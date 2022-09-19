//
//  RTCSampleChatViewController.h
//  RtcSample
//
//  Created by daijian on 2019/2/27.
//  Copyright © 2019年 tiantian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AliRTCSdk/AliRTCSdk.h>
#import <AliRTCSdk/AliRenderView.h>

NS_ASSUME_NONNULL_BEGIN

@interface RTCSampleChatViewController : UIViewController

/**
 @brief 频道号
 */
@property(nonatomic, copy) NSString *channelName;

@property(nonatomic, assign) BOOL isuseFU;

@end

NS_ASSUME_NONNULL_END

@interface RTCRemoterUserView : UICollectionViewCell


/**
 @brief 用户流视图
 
 @param view renderview
 */
- (void)updateUserRenderview:(AliRenderView *)view;

@end
