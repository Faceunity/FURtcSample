//
//  NSString+SHA256.h
//  RtcSample
//
//  Created by support on 2020/10/23.
//  Copyright © 2020 tiantian. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (SHA256)

//SHA256加密
+ (NSString*)sha256HashFor:(NSString *)input;


@end

NS_ASSUME_NONNULL_END
