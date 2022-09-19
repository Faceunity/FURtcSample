//
//  NSString+SHA256.m
//  RtcSample
//
//  Created by support on 2020/10/23.
//  Copyright © 2020 tiantian. All rights reserved.
//

#import "NSString+SHA256.h"

#import <CommonCrypto/CommonDigest.h>


@implementation NSString (SHA256)

//SHA256加密
+ (NSString*)sha256HashFor:(NSString*)input{
    const char* str = [input cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned char result[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(str, (CC_LONG)strlen(str), result);
    
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH*2];
    for(int i = 0; i<CC_SHA256_DIGEST_LENGTH; i++)
    {
        [ret appendFormat:@"%02x",result[i]];
    }
    ret = (NSMutableString *)[ret lowercaseString];
    return ret;
}


@end


