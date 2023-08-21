//
//  RTCSampleChatViewController.m
//  RtcSample
//
//  Created by daijian on 2019/2/27.
//  Copyright © 2019年 tiantian. All rights reserved.
//

#import "RTCSampleChatViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "RTCSampleUserAuthrization.h"
#import "UIViewController+RTCSampleAlert.h"
#import "RTCSampleRemoteUserManager.h"
#import "RTCSampleRemoteUserModel.h"
#import "NSString+SHA256.h"


/**faceU */
#import "FUDemoManager.h"
#import <FURenderKit/FUCaptureCamera.h>
#import <FURenderKit/FUGLDisplayView.h>

/**faceU */



@interface RTCSampleChatViewController ()<AliRtcEngineDelegate,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,FUCaptureCameraDelegate>


/**
 @brief 开始推流界面
 */
@property(nonatomic, strong) UIButton      *startButton;

/** 切换摄像头 */
@property(nonatomic, strong) UIButton *cameraBtn;

/** 静音 🔇 */
@property(nonatomic, strong) UIButton *muteBtn;


/**
 @brief SDK实例
 */
@property (nonatomic, strong) AliRtcEngine *engine;

/**
 @brief 本地用户视图
 */
@property(nonatomic, strong) FUGLDisplayView *localView;


/**
 @brief 远端用户管理
 */
@property(nonatomic, strong) RTCSampleRemoteUserManager *remoteUserManager;

/**
 @brief 远端用户视图
 */
@property(nonatomic, strong) UICollectionView *remoteUserView;


/**
 @brief 是否入会
 */
@property(nonatomic, assign) BOOL isJoinChannel;


@property(nonatomic, strong) FUCaptureCamera *mCamera;


@end

@implementation RTCSampleChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //导航栏名称等基本设置
    [self baseSetting];
    
    //初始化SDK内容
    [self initializeSDK];
    
    //开启本地预览
    [self startPreview];
    
    // 外部采集摄像头
    [self setupmCamera];
    
    //添加页面控件
    [self addSubviews];
    
    if (self.isuseFU) {
        
        // FaceUnity UI
        [FUDemoManager setupFUSDK];
        [[FUDemoManager shared] addDemoViewToView:self.view originY:CGRectGetHeight(self.view.frame) - FUBottomBarHeight - FUSafaAreaBottomInsets() - 160];
    }
    
}


#pragma mark ----------FUCameraDelegate-----

/// 开始采集
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [_mCamera startCapture];
    
}

/// 外部摄像头采集
- (void)setupmCamera{

    _mCamera = [[FUCaptureCamera alloc] initWithCameraPosition:(AVCaptureDevicePositionFront) captureFormat:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange];
    _mCamera.sessionPreset = AVCaptureSessionPreset1280x720;
    _mCamera.delegate = self;

}

/// 采集数据回调
/// @param sampleBuffer sampleBuffer
- (void)didOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer captureDevicePosition:(AVCaptureDevicePosition)position{

    if (_engine) {
        
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        if (self.isuseFU) {
        
            [[FUDemoManager shared] checkAITrackedResult];
            if ([FUDemoManager shared].shouldRender) {
                [[FUTestRecorder shareRecorder] processFrameWithLog];
                [FUDemoManager updateBeautyBlurEffect];
                FURenderInput *input = [[FURenderInput alloc] init];
                input.renderConfig.imageOrientation = FUImageOrientationUP;
                input.pixelBuffer = pixelBuffer;
                //开启重力感应，内部会自动计算正确方向，设置fuSetDefaultRotationMode，无须外面设置
                input.renderConfig.gravityEnable = YES;
                input.renderConfig.readBackToPixelBuffer = YES;
                FURenderOutput *outPut = [[FURenderKit shareRenderKit] renderWithInput:input];
            }
        }
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        AliRtcVideoDataSample *dataSample = [[AliRtcVideoDataSample alloc] init];
        dataSample.format = AliRtcVideoFormat_NV21;
        dataSample.type = AliRtcBufferType_CVPixelBuffer;
        dataSample.pixelBuffer = pixelBuffer;
        dataSample.timeStamp = 0;
        [self.engine pushExternalVideoFrame:dataSample sourceType:(AliRtcVideosourceCameraType)];
        [self.localView displayPixelBuffer:pixelBuffer];
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        
    }
    
}


#pragma mark - baseSetting
/**
 @brief 基础设置
 */
- (void)baseSetting{
    self.title = @"视频通话";
    self.view.backgroundColor = [UIColor whiteColor];
}

#pragma mark - initializeSDK
/**
 @brief 初始化SDK
 */
- (void)initializeSDK{
    
    // 创建SDK实例，注册delegate，extras可以为空
    NSDictionary *extrasDic = @{@"user_specified_video_preprocess":@"TRUE"};
    NSData *data = [NSJSONSerialization dataWithJSONObject:extrasDic options:0 error:NULL];
    NSString *extrasStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    _engine = [AliRtcEngine sharedInstance:self extras:extrasStr];
    
    AliRtcVideoEncoderConfiguration *config = [[AliRtcVideoEncoderConfiguration alloc] init];
    config.dimensions = CGSizeMake(720, 1280);
    config.frameRate = 30;
    config.bitrate = 0;
    config.mirrorMode = 0;
    config.orientationMode = 0;
    config.rotationMode = 0;
    [_engine setVideoEncoderConfiguration:config];
    [_engine setChannelProfile:(AliRtcCommunication)];
    
    // 设置外部采集
    [_engine setExternalVideoSource:YES sourceType:(AliRtcVideosourceCameraType) renderMode:(AliRtcRenderModeCrop)];
}

- (void)startPreview{

    // 设置本地预览视频
    FUGLDisplayView *localView = [[FUGLDisplayView alloc] initWithFrame:self.view.bounds];
    localView.contentMode = FUGLDisplayViewContentModeScaleAspectFill;
    [self.view addSubview:localView];
    self.localView = localView;
    // 开启本地预览
    [self.engine startPreview];
    
}

#pragma mark - action

/**
 @brief 登陆服务器，并开始推流
 */
- (void)startPreview:(UIButton *)sender {

    //随机生成用户名，仅是demo展示使用
    NSString *userId = [NSString stringWithFormat:@"iOSUser%u",arc4random()%1234];
    
    NSString * uuidStr =[[[UIDevice currentDevice] identifierForVendor] UUIDString];;
    NSString *nonce = [NSString stringWithFormat:@"AK-%@",[uuidStr lowercaseString]];
    
    NSString *timestamp = [NSString stringWithFormat:@"%.0f",[[NSDate date] timeIntervalSince1970] + 24 * 7 * 3600];
    
    //sha256(appId + appKey + channelId + userId + nonce + timestamp)
    NSString *token = @"sv8hdwp7";
    
    token = [token stringByAppendingString:@"57e964d805be8b173f1de8abaa4f5dca"];
    token = [token stringByAppendingString:self.channelName];
    token = [token stringByAppendingString:userId];
    token = [token stringByAppendingString:nonce];
    token = [token stringByAppendingString:timestamp];
    token = [NSString sha256HashFor:token];
    
    //AliRtcAuthInfo 配置项, token 相关数据的获取请在服务端配置, 示例代码仅供演示使用
    AliRtcAuthInfo *authinfo = [[AliRtcAuthInfo alloc]init];
    authinfo.channelId   = self.channelName;
    authinfo.appId     = @"sv8hdwp7";
    authinfo.nonce     = nonce;
    authinfo.userId   = userId;
    authinfo.token     = token;
    authinfo.timestamp = [timestamp integerValue];
    authinfo.gslb      = @[@"https://rgslb.rtc.aliyuncs.com"];

    
    //加入频道
    [self.engine joinChannel:authinfo name:userId onResult:^(NSInteger errCode, NSString * _Nonnull channel, NSInteger elapsed) {
            
        //加入频道回调处理
        NSLog(@"joinChannel result: %d", (int)errCode);
        dispatch_async(dispatch_get_main_queue(), ^{
        
            // 加入频道UI处理
            if (errCode == 0) { // 加入频道成功
                
                _isJoinChannel = YES;
                sender.hidden = YES;
            }
            
        });
        
    }];
    
    //防止屏幕锁定
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
}

- (void)onJoinChannelResult:(int)result channel:(NSString *)channel elapsed:(int)elapsed{

    if (result != 0) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
           
            [self showAlertWithMessage:[NSString stringWithFormat:@"加入房间失败,请重试,codeError = %d",result] handler:^(UIAlertAction * _Nonnull action) {
                        
            }];
            
        });
        
    }
}


/// 切换摄像头
/// @param caremaBtn caremaBtn
- (void)caremaBtnClick:(UIButton *)caremaBtn{
    
    caremaBtn.selected = !caremaBtn.selected;
    [self.mCamera changeCameraInputDeviceisFront:!caremaBtn.selected];
    if (self.isuseFU) {
        
        [FUDemoManager resetTrackedResult];
    }
    
}

/// 静音
/// @param muteBtn muteBtn
- (void)muteBtnClick:(UIButton *)muteBtn{
    
    muteBtn.selected = !muteBtn.selected;
    
    if (muteBtn.selected) {

        [self.engine muteLocalMic:YES mode:(AliRtcMuteAudioModeDefault)]; // 静音
        
    }else{
    
        [self.engine muteLocalMic:NO mode:(AliRtcMuteAudioModeDefault)]; // 恢复静音
    }
    
}

/**
 @brief 离开频道
 */
- (void)leaveChannel:(UIButton *)sender {
    
    [self leaveChannel];
    _engine = nil;
    if (self.isuseFU) {
        [FUDemoManager destory];
    }
    [self.mCamera stopCapture];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - private

/**
 @brief 离开频需要取消本地预览、离开频道、销毁SDK
 */
- (void)leaveChannel {
    
    [self.remoteUserManager removeAllUser];
    
    //停止本地预览
    [self.engine stopPreview];
    
    if (_isJoinChannel) {
        //离开频道
        [self.engine leaveChannel];
    }

    [self.remoteUserView removeFromSuperview];
    
    //销毁SDK实例
    [AliRtcEngine destroy];
}

#pragma mark - uicollectionview delegate & datasource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.remoteUserManager allOnlineUsers].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    RTCRemoterUserView *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    RTCSampleRemoteUserModel *model =  [self.remoteUserManager allOnlineUsers][indexPath.row];
    AliRenderView *view = model.view;
    [cell updateUserRenderview:view];
    return cell;
}

#pragma mark - alirtcengine delegate
- (void)onRemoteTrackAvailableNotify:(NSString *_Nonnull)uid audioTrack:(AliRtcAudioTrack)audioTrack videoTrack:(AliRtcVideoTrack)videoTrack{
    
    //收到远端订阅回调
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.remoteUserManager updateRemoteUser:uid forTrack:videoTrack];
        if (videoTrack == AliRtcVideoTrackCamera) {
            AliVideoCanvas *canvas = [[AliVideoCanvas alloc] init];
            canvas.renderMode = AliRtcRenderModeAuto;
//            canvas.mirrorMode = AliRtcRenderMirrorModeAllEnabled;
            canvas.view = [self.remoteUserManager cameraView:uid];
            [self.engine setRemoteViewConfig:canvas uid:uid forTrack:AliRtcVideoTrackCamera];
        }else if (videoTrack == AliRtcVideoTrackScreen) {
            AliVideoCanvas *canvas2 = [[AliVideoCanvas alloc] init];
            canvas2.renderMode = AliRtcRenderModeAuto;
            canvas2.view = [self.remoteUserManager screenView:uid];
            [self.engine setRemoteViewConfig:canvas2 uid:uid forTrack:AliRtcVideoTrackScreen];
        }else if (videoTrack == AliRtcVideoTrackBoth) {
            
            AliVideoCanvas *canvas = [[AliVideoCanvas alloc] init];
            canvas.renderMode = AliRtcRenderModeAuto;
            canvas.view = [self.remoteUserManager cameraView:uid];
            [self.engine setRemoteViewConfig:canvas uid:uid forTrack:AliRtcVideoTrackCamera];
            
            AliVideoCanvas *canvas2 = [[AliVideoCanvas alloc] init];
            canvas2.renderMode = AliRtcRenderModeAuto;
            canvas2.view = [self.remoteUserManager screenView:uid];
            [self.engine setRemoteViewConfig:canvas2 uid:uid forTrack:AliRtcVideoTrackScreen];
        }
        [self.remoteUserView reloadData];
    });
}

- (void)onRemoteUserOnLineNotify:(NSString *)uid {
    
}



- (void)onRemoteUserOffLineNotify:(NSString *)uid offlineReason:(AliRtcUserOfflineReason)reason {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.remoteUserManager remoteUserOffLine:uid];
        [self.remoteUserView reloadData];
    });
}

- (void)onOccurError:(int)error message:(NSString *)message{
    
    dispatch_async(dispatch_get_main_queue(), ^{
    
        [self showAlertWithMessage:message handler:^(UIAlertAction * _Nonnull action) {
            
            [self leaveChannel:nil];
        }];
        
    });
}


#pragma  mark -  订阅回调接口

//- (BOOL)onCaptureVideoSample:(AliRtcVideoSource)videoSource videoSample:(AliRtcVideoDataSample *)videoSample{
//
//    if (videoSource == AliRtcVideosourceCameraType) { //
//
//        // 测试性能
//        [[FUTestRecorder shareRecorder] processFrameWithLog];
//
//        [[FUManager shareManager] processFrameWithY:videoSample.dataYPtr U:videoSample.dataUPtr V:videoSample.dataVPtr yStride:videoSample.strideY uStride:videoSample.strideU vStride:videoSample.strideV FrameWidth:videoSample.width FrameHeight:videoSample.height];
//
//        [self checkAI];
//    }
//
//
//
//    return YES;
//}


#pragma mark - add subviews

- (void)addSubviews {
    
    UIButton *exitButton = [UIButton buttonWithType:UIButtonTypeCustom];
    exitButton.frame = CGRectMake(0, 0, 60, 40);
    [exitButton setTitle:@"退出" forState:UIControlStateNormal];
    [exitButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [exitButton addTarget:self action:@selector(leaveChannel:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:exitButton];
    
    CGRect rcScreen = [UIScreen mainScreen].bounds;
    CGRect rc = rcScreen;
    rc.size   = CGSizeMake(60, 60);
    rc.origin.y  = rcScreen.size.height - 100;
    rc.origin.x  = self.view.center.x - rc.size.width/2;
    _startButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _startButton.frame = rc;
    [_startButton setTitle:@"开始" forState:UIControlStateNormal];
    [_startButton setBackgroundColor:[UIColor orangeColor]];
    _startButton.layer.cornerRadius  = rc.size.width/2;
    _startButton.layer.masksToBounds = YES;
    [_startButton addTarget:self action:@selector(startPreview:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_startButton];
    // 切换摄像头
    _cameraBtn = [[UIButton alloc] init];
    [_cameraBtn setTitle:@"相机" forState:(UIControlStateNormal)];
    _cameraBtn.backgroundColor = [UIColor orangeColor];
    _cameraBtn.layer.cornerRadius  = rc.size.width/2;
    _cameraBtn.layer.masksToBounds = YES;
    rc.origin.x = CGRectGetMinX(_startButton.frame) - 80;
    _cameraBtn.frame = rc;
    [_cameraBtn addTarget:self action:@selector(caremaBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_cameraBtn];
    
    // 静音
    _muteBtn = [[UIButton alloc] init];
    [_muteBtn setTitle:@"静音" forState:(UIControlStateNormal)];
    [_muteBtn setTitle:@"X" forState:(UIControlStateSelected)];
    _muteBtn.backgroundColor = [UIColor orangeColor];
    _muteBtn.layer.cornerRadius  = rc.size.width/2;
    _muteBtn.layer.masksToBounds = YES;
    rc.origin.x = CGRectGetMaxX(_startButton.frame) + 20;
    _muteBtn.frame = rc;
    [_muteBtn addTarget:self action:@selector(muteBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_muteBtn];
    
    rc.origin.x = 10;
    rc.origin.y = [UIApplication sharedApplication].statusBarFrame.size.height+20+44;
    rc.size = CGSizeMake(self.view.frame.size.width-20, 200);
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = CGSizeMake(140, 200);
    flowLayout.minimumLineSpacing = 10;
    flowLayout.minimumInteritemSpacing = 10;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.remoteUserView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    self.remoteUserView.frame = rc;
    self.remoteUserView.backgroundColor = [UIColor clearColor];
    self.remoteUserView.delegate   = self;
    self.remoteUserView.dataSource = self;
    self.remoteUserView.showsHorizontalScrollIndicator = NO;
    [self.remoteUserView registerClass:[RTCRemoterUserView class] forCellWithReuseIdentifier:@"cell"];
    [self.view addSubview:self.remoteUserView];
    
    _remoteUserManager = [RTCSampleRemoteUserManager shareManager];
    
}

@end

@implementation RTCRemoterUserView
{
    AliRenderView *viewRemote;
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        //设置远端流界面
        CGRect rc  = CGRectMake(0, 0, 140, 200);
        viewRemote = [[AliRenderView alloc] initWithFrame:rc];
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)updateUserRenderview:(AliRenderView *)view {
    view.backgroundColor = [UIColor clearColor];
    view.frame = viewRemote.frame;
    viewRemote = view;
    [self addSubview:viewRemote];
}

@end
