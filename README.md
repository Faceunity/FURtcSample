# FURtcSample 快速接入文档

`FURtcSample` 是集成了 [Faceunity](https://github.com/Faceunity/FULiveDemo/tree/dev) 面部跟踪和虚拟道具功能 和 阿里音视频通信 功能的 Demo。

**本文是 FaceUnity SDK  快速对接 阿里音视频通信 的导读说明**

**关于  FaceUnity SDK 的更多详细说明，请参看 [FULiveDemo](https://github.com/Faceunity/FULiveDemo/tree/dev)**



## 快速集成方法

### 一、导入 SDK

将  FaceUnity  文件夹全部拖入工程中，并且添加依赖库 `OpenGLES.framework`、`Accelerate.framework`、`CoreMedia.framework`、`AVFoundation.framework`、`libc++.tbd`、`CoreML.framework`

备注: Cocoapods 管理无需添加依赖库

### FaceUnity 模块简介
```C
-FUManager              //nama 业务类
-FUCamera               //视频采集类(示例程序未用到)    
-authpack.h             //权限文件
+FUAPIDemoBar     //美颜工具条,可自定义
+items       //贴纸和美妆资源 xx.bundel文件
      
```


### 二、加入展示 FaceUnity SDK 美颜贴纸效果的  UI

1、在 RTCSampleChatViewController.m  中添加头文件，并创建页面属性

```C
/**faceU */
#import "FUManager.h"
#import "FUAPIDemoBar.h"

@property (nonatomic, strong) FUAPIDemoBar *demoBar;

```

2、初始化 UI，并遵循代理  FUAPIDemoBarDelegate ，实现代理方法 `bottomDidChange:` 切换贴纸 和 `filterValueChange:` 更新美颜参数。

```C
-(FUAPIDemoBar *)demoBar {
    if (!_demoBar) {
        
        _demoBar = [[FUAPIDemoBar alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 164 - 231, self.view.frame.size.width, 231)];
        
        _demoBar.mDelegate = self;
    }
    return _demoBar ;
}

```

#### 切换贴纸

```C
// 切换贴纸
-(void)bottomDidChange:(int)index{
    if (index < 3) {
        [[FUManager shareManager] setRenderType:FUDataTypeBeautify];
    }
    if (index == 3) {
        [[FUManager shareManager] setRenderType:FUDataTypeStrick];
    }
    
    if (index == 4) {
        [[FUManager shareManager] setRenderType:FUDataTypeMakeup];
    }
    if (index == 5) {
        [[FUManager shareManager] setRenderType:FUDataTypebody];
    }
}

```

#### 更新美颜参数

```C
// 更新美颜参数    
- (void)filterValueChange:(FUBeautyParam *)param{
    [[FUManager shareManager] filterValueChange:param];
}
```

### 三、在 `viewDidLoad:` 调用 `setupDemoBar` 方法 初始化SDK,并将`demoBar`添加到页面上

```C
#pragma  mark -  setupDemoBar
-(void)setupDemoBar{
    
    [[FUManager shareManager] loadFilter];
    [FUManager shareManager].isRender = YES;
    [FUManager shareManager].flipx = NO;
    [FUManager shareManager].trackFlipx = NO;
    [self.view addSubview:self.demoBar];

}

```

### 四、在视频数据回调中 加入 FaceUnity  的数据处理

订阅回调开始，在 RTCSampleChatViewController.m  的  ` onVideoTexture:(NSString *)uid videoTextureType:(AliRtcVideoTextureType)videoTextureType textureId:(int)textureId width:(int)width height:(int)height rotate:(int)rotate extraData:(long)extraData `  方法中会有视频数据的回调，修改其为以下内容：

```C
#pragma  mark -  订阅回调接口
- (int)onVideoTexture:(NSString *)uid videoTextureType:(AliRtcVideoTextureType)videoTextureType textureId:(int)textureId width:(int)width height:(int)height rotate:(int)rotate extraData:(long)extraData{
    
    textureId = [[FUManager shareManager] renderItemWithTexture:textureId Width:width Height:height];
    
    return textureId;
}

```



### 五、销毁道具

1 视图控制器生命周期结束时,销毁道具
```C
[[FUManager shareManager] destoryItems];
```

2 切换摄像头需要调用,切换摄像头
```C
[[FUManager shareManager] onCameraChange];
```

### 关于 FaceUnity SDK 的更多详细说明，请参看 [FULiveDemo](https://github.com/Faceunity/FULiveDemo/tree/dev)