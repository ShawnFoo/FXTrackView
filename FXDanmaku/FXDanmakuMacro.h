//
//  FXDanmakuMacro.h
//  FXDanmakuDemo
//
//  Created by ShawnFoo on 16/3/14.
//  Copyright © 2016年 ShawnFoo. All rights reserved.
//

#ifndef FXDanmakuMacro_h
#define FXDanmakuMacro_h

#ifdef __OBJC__

#if DEBUG
#define fx_ext_keywordify autoreleasepool {}
#else
#define fx_ext_keywordify try {} @catch (...) {}
#endif

#define FXWeakify(o) fx_ext_keywordify __weak typeof(o) o##Weak = o
#define FXStrongify(o) fx_ext_keywordify __strong typeof(o) o = o##Weak
#define FXReturnIfSelfNil {\
if (!self) return;\
}

#define FXNSStringFromSelectorName(name) NSStringFromSelector(@selector(name))

#ifdef DEBUG
#define FXLogD(format, ...) NSLog((@"\n"format@"\n\t %s [Line %d]\n"), ##__VA_ARGS__, __PRETTY_FUNCTION__, __LINE__)
#else
#define FXLogD(...) do {} while(0)
#endif

#ifdef DEBUG
#define FXDanmakuExceptionName @"FXDanmakuException"
#define FXException(format, ...) @throw [NSException \
exceptionWithName:FXDanmakuExceptionName \
reason:[NSString stringWithFormat:format, ##__VA_ARGS__]  \
userInfo:nil];
#else
#define FXException(...) do {} while(0)
#endif

#define FXRunBlockSafe(block, ...) {\
if (block) {\
block(__VA_ARGS__);\
}\
}

#define FXRunBlockSafe_MainThread(block) {\
if ([NSThread isMainThread]) {\
FXRunBlockSafe(block)\
}\
else {\
if (block) {\
dispatch_async(dispatch_get_main_queue(), block);\
}\
}\
}

#define FXRunBlockSyncSafe_MainThread(block) {\
if ([NSThread isMainThread]) {\
FXRunBlockSafe(block)\
}\
else {\
if (block) {\
dispatch_sync(dispatch_get_main_queue(), block);\
}\
}\
}

#endif /* __OBJC__ */

#endif /* FXBarrageViewHeader_h */
