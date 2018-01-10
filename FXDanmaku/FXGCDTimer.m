//
//  FXGCDTimer.m
//  FXDanmakuDemo
//
//  Created by ShawnFoo on 2017/1/9.
//  Copyright © 2017年 ShawnFoo. All rights reserved.
//

#import "FXGCDTimer.h"

@interface FXGCDTimer ()

@property (nonatomic, copy) dispatch_block_t block;
@property (nonatomic, strong) dispatch_queue_t blockQueue;
@property (nonatomic, weak) dispatch_source_t sourceTimer;
@property (nonatomic, strong) dispatch_semaphore_t syncSemophore;

@end

@implementation FXGCDTimer

#pragma mark - Accessor
- (BOOL)isValid {
    return self.block != nil;
}

#pragma mark - LifeCycle
- (instancetype)init {
    if (self = [super init]) {
        _syncSemophore = dispatch_semaphore_create(1);
    }
    return self;
}

+ (instancetype)scheduledTimerWithInterval:(NSTimeInterval)interval
                                     queue:(dispatch_queue_t)queue
                                     block:(dispatch_block_t)block
{
    return [self scheduledTimerWithInterval:interval
                                     repeat:NO
                                      queue:queue
                                      block:block];
}

+ (instancetype)scheduledRepeatTimerWithInterval:(NSTimeInterval)interval
                                           queue:(dispatch_queue_t)queue
                                           block:(dispatch_block_t)block
{
    return [self scheduledTimerWithInterval:interval
                                     repeat:YES
                                      queue:queue
                                      block:block];
}

+ (instancetype)scheduledTimerWithInterval:(NSTimeInterval)interval
                                    repeat:(BOOL)repeat
                                     queue:(dispatch_queue_t)queue
                                     block:(dispatch_block_t)block
{
    FXGCDTimer *timer = nil;
    if (block) {
        timer = [[FXGCDTimer alloc] init];
        timer.block = block;
        timer.blockQueue = queue ?: dispatch_get_main_queue();
        dispatch_source_t sourceTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,
                                                               0,
                                                               0,
                                                               timer.blockQueue);
        
        uint64_t repeatInterval = interval * NSEC_PER_SEC;
        dispatch_source_set_timer(sourceTimer,
                                  dispatch_walltime(DISPATCH_TIME_NOW, repeatInterval),
                                  repeat ? repeatInterval : DISPATCH_TIME_FOREVER,
                                  0);
        dispatch_source_set_event_handler(sourceTimer, ^{
            dispatch_semaphore_wait(timer.syncSemophore, DISPATCH_TIME_FOREVER);
            {
                if (repeat || !dispatch_source_testcancel(sourceTimer)) {
                    timer.block();
                    if (!repeat) {
                        timer.block = nil;
                        dispatch_source_cancel(sourceTimer);
                    }
                }
            }
            dispatch_semaphore_signal(timer.syncSemophore);
        });
        timer.sourceTimer = sourceTimer;
        dispatch_resume(sourceTimer);
    }
    return timer;
}

#pragma mark - Action
- (void)invalidate {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.blockQueue, ^{
        typeof(self) self = weakSelf;
        if (self) {
            dispatch_semaphore_wait(self.syncSemophore, DISPATCH_TIME_FOREVER);
            {
                if (self.sourceTimer && !dispatch_source_testcancel(self.sourceTimer)) {
                    self.block = nil;
                    dispatch_source_cancel(self.sourceTimer);
                }
            }
            dispatch_semaphore_signal(self.syncSemophore);
        }
    });
}

@end
