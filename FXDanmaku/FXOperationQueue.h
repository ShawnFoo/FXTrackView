//
//  FXOperationQueue.h
//  FXDanmakuDemo
//
//  Created by ShawnFoo on 2017/1/15.
//  Copyright © 2017年 ShawnFoo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FXOperationQueue : NSObject

@property (nonatomic, readonly) dispatch_queue_t queue;

+ (instancetype)queueWithDispatchQueue:(dispatch_queue_t)queue;

- (void)addSyncOperationBlock:(dispatch_block_t)block;
- (void)addAsyncOperationBlock:(dispatch_block_t)block;

- (void)cancelAllOperation;

@end
