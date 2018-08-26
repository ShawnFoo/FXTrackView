//
//  NSTimer+FXWeakTimer.m
//  FXKit
//
//  Created by ShawnFoo on 16/6/14.
//  Copyright © 2016年 ShawnFoo. All rights reserved.
//

#import "NSTimer+FXWeakTarget.h"
#import <objc/runtime.h>

#pragma mark - FXTimerTargetDeallocMonitor Interface
@interface FXTimerTargetMonitor : NSObject

@property (nonatomic, copy) void (^deallocBlock)(void);

+ (void)addMonitorToTarget:(id)target forKey:(id)key withDeallocBlock:(void (^)(void))deallocBlock;

@end


#pragma mark - FXTimerTargetProxy Interface
@interface FXTimerTargetProxy : NSObject

@property (nonatomic, weak) id target;
@property (nonatomic, copy) fx_timer_fire_block_t fireBlock;
@property (nonatomic, weak) NSTimer *timer;

+ (instancetype)proxyWithTarget:(id)target fireBlock:(fx_timer_fire_block_t)block;
- (void)fireBlockInvoker:(NSTimer *)timer;
- (void)invalidateTimer;

@end


#pragma mark - NSTimer + FXWeakTarget
@implementation NSTimer (FXWeakTarget)

+ (NSTimer *)fx_scheduledTimerWithInterval:(NSTimeInterval)interval
									target:(id)target
									 block:(fx_timer_fire_block_t)block {
	return [self fx_timerWithInterval:interval
							   target:target
							  repeats:NO
							scheduled:YES
								block:block];
}

+ (NSTimer *)fx_scheduledRepeatedTimerWithInterval:(NSTimeInterval)interval
											target:(id)target
											 block:(fx_timer_fire_block_t)block {
	return [self fx_timerWithInterval:interval
							   target:target
							  repeats:YES
							scheduled:YES
								block:block];
}

+ (NSTimer *)fx_timerWithInterval:(NSTimeInterval)interval
						   target:(id)target
							block:(fx_timer_fire_block_t)block {
	return [self fx_timerWithInterval:interval
							   target:target
							  repeats:NO
							scheduled:NO
								block:block];
}

+ (NSTimer *)fx_repeatedTimerWithInterval:(NSTimeInterval)interval
								   target:(id)target
									block:(fx_timer_fire_block_t)block {
	return [self fx_timerWithInterval:interval
							   target:target
							  repeats:YES
							scheduled:NO
								block:block];
}

+ (NSTimer *)fx_timerWithInterval:(NSTimeInterval)interval
						   target:(id)target
						  repeats:(BOOL)repeats
						scheduled:(BOOL)scheduled
							block:(fx_timer_fire_block_t)block {
	FXTimerTargetProxy *targetProxy = [[FXTimerTargetProxy alloc] init];
	targetProxy.target = target;
	targetProxy.fireBlock = block;
	
	[FXTimerTargetMonitor addMonitorToTarget:target forKey:targetProxy withDeallocBlock:^{
		[targetProxy invalidateTimer];
	}];
	
	if (scheduled) {
		targetProxy.timer = [NSTimer scheduledTimerWithTimeInterval:interval
															 target:targetProxy
														   selector:@selector(fireBlockInvoker:)
														   userInfo:nil
															repeats:repeats];
		return targetProxy.timer;
	}
	else {
		NSTimer *timer = [NSTimer timerWithTimeInterval:interval
												 target:targetProxy
											   selector:@selector(fireBlockInvoker:)
											   userInfo:nil
												repeats:repeats];
		targetProxy.timer = timer;
		return timer;
	}
}

@end


#pragma mark - FXTimerTargetDeallocMonitor IMP
@implementation FXTimerTargetMonitor

+ (void)addMonitorToTarget:(id)target forKey:(id)key withDeallocBlock:(void (^)(void))deallocBlock {
	FXTimerTargetMonitor *monitor = [[FXTimerTargetMonitor alloc] init];
	monitor.deallocBlock = deallocBlock;
	objc_setAssociatedObject(target,
							 (__bridge const void *)(key),
							 monitor,
							 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)dealloc {
	dispatch_async(dispatch_get_main_queue(), _deallocBlock);
	_deallocBlock = nil;
}

@end


#pragma mark - FXTimerTargetProxy IMP
@implementation FXTimerTargetProxy

+ (instancetype)proxyWithTarget:(id)target fireBlock:(fx_timer_fire_block_t)block {
	FXTimerTargetProxy *proxy = [[FXTimerTargetProxy alloc] init];
	proxy.target = target;
	proxy.fireBlock = block;
	return proxy;
}

- (void)fireBlockInvoker:(NSTimer *)timer {
	if (timer.valid) {
		id strongTarget = self.target;
		if (strongTarget) {
			[self invokeFireBlock];
		}
		else {
			[self invalidateTimer];
		}
	}
}

- (void)invokeFireBlock {
	if (self.fireBlock) {
		self.fireBlock(self.timer);
	}
}

- (void)invalidateTimer {
	self.fireBlock = nil;
	[self.timer invalidate];
}

@end

