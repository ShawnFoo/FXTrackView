//
//  NSTimer+FXWeakTimer.h
//  FXKit
//
//  Created by ShawnFoo on 16/6/14.
//  Copyright © 2016年 ShawnFoo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^fx_timer_fire_block_t)(NSTimer *timer);

/**
 不会强引用Target的NSTimer. 当Target释放时, 若关联NSTimer依旧有效, 则会对其调用invalidate, 外部可不管.
 
 正常方式创建的NSTimer存在这种情况, NSRunLoop -> NSTimer(CFRunLooperTimerRef) -> Target -> NSTimer, 有效期间存在循环引用. 必须主动去打破这个环,
 然而Target已经循环引用, 不会执行dealloc方法, 即无法在其dealloc方法中invalidate timer.
 
 使用该类别创建的NSTimer会通过一个Target代理对象来被NSTimer持有, 该代理再弱引用指向原Target, 从而打破循环.
 */
@interface NSTimer (FXWeakTarget)

/**
 *  返回一个已激活的NSTimer对象. 该对象会以NSRunLoopDefaultMode模式加入到当前的RunLoop中.
 *
 *  @param interval 定时器两次触发的间隔
 *  @param target 关联目标对象. 当该对象被释放时, 若对应NSTimer依旧有效, 则会调用invlidate使其失效
 *  @param block 定时器触发时执行的Block, 还可以通过Block中的timer调用失效方法
 */
+ (NSTimer *)fx_scheduledTimerWithInterval:(NSTimeInterval)interval
									target:(id)target
									 block:(fx_timer_fire_block_t)block;

/**
 *  返回一个已激活且会重复触发的NSTimer对象. 该对象会以NSRunLoopDefaultMode模式加入到当前的RunLoop中.
 *
 *  @param interval 定时器两次触发的间隔
 *  @param target 关联目标对象. 当该对象被释放时, 若对应NSTimer依旧有效, 则会调用invlidate使其失效
 *  @param block 定时器触发时执行的Block, 还可以通过Block中的timer调用失效方法
 */
+ (NSTimer *)fx_scheduledRepeatedTimerWithInterval:(NSTimeInterval)interval
											target:(id)target
											 block:(fx_timer_fire_block_t)block;

/**
 *  创建一个未激活的NSTimer对象
 *
 *  @param interval 定时器两次触发的间隔
 *  @param target 关联目标对象. 当该对象被释放时, 若对应NSTimer依旧有效, 则会调用invlidate使其失效
 *  @param block 定时器触发时执行的Block, 还可以通过Block中的timer调用失效方法
 */
+ (NSTimer *)fx_timerWithInterval:(NSTimeInterval)interval
						   target:(id)target
							block:(fx_timer_fire_block_t)block;

/**
 *  创建一个未激活会重复触发的NSTimer对象
 *
 *  @param interval 定时器两次触发的间隔
 *  @param target 关联目标对象. 当该对象被释放时, 若对应NSTimer依旧有效, 则会调用invlidate使其失效
 *  @param block 定时器触发时执行的Block, 还可以通过Block中的timer调用失效方法
 */
+ (NSTimer *)fx_repeatedTimerWithInterval:(NSTimeInterval)interval
								   target:(id)target
									block:(fx_timer_fire_block_t)block;

@end

NS_ASSUME_NONNULL_END
