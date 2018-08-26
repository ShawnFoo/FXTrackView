//
//  FXDanmakuPriorityQueue.h
//  FXDanmaku
//
//  Created by ShawnFoo on 2018/8/26.
//

#import <Foundation/Foundation.h>
@class FXDanmakuItemData;

NS_ASSUME_NONNULL_BEGIN

@protocol FXDamakuQueue <NSObject>

@property (nonatomic, readonly) BOOL isEmpty;
@property (nonatomic, nullable, readonly) id peek;
@property (nonatomic, readonly) NSInteger count;

- (void)enqueue:(id)object;
- (nullable id)dequeue;
- (void)emptyQueue;

@end

@interface FXDanmakuPriorityQueue : NSObject <FXDamakuQueue>

@property (nonatomic, nullable, readonly) FXDanmakuItemData *peek;

- (void)enqueue:(FXDanmakuItemData *)data;
- (nullable FXDanmakuItemData *)dequeue;

@end

NS_ASSUME_NONNULL_END
