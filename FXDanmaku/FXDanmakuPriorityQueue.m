//
//  FXDanmakuPriorityQueue.m
//  FXDanmaku
//
//  Created by ShawnFoo on 2018/8/26.
//

#import "FXDanmakuPriorityQueue.h"
#import "FXDanmakuItemData.h"

#pragma mark - FXInnerStackQueue
@interface FXInnerStackQueue<__covariant ObjectType>: NSObject <FXDamakuQueue>

@property (nonatomic, strong) NSMutableArray<ObjectType> *dequeueStack;
@property (nonatomic, strong) NSMutableArray<ObjectType> *enququeStack;

@end

@implementation FXInnerStackQueue

- (void)enqueue:(id)object {
    if (object) {
        [self.enququeStack addObject:object];
    }
}

- (id)dequeue {
    if (!_dequeueStack.count && _enququeStack.count) {
        [self.dequeueStack addObjectsFromArray:[self.enququeStack reverseObjectEnumerator].allObjects];
        [self.enququeStack removeAllObjects];
    }
    id lastObject = [_dequeueStack lastObject];
    if (lastObject) {
        [_dequeueStack removeLastObject];
    }
    return lastObject;
}

- (void)emptyQueue {
    [_dequeueStack removeAllObjects];
    [_enququeStack removeAllObjects];
}

#pragma mark Computed Properties
- (BOOL)isEmpty {
    return !_dequeueStack.count && !_enququeStack.count;
}

- (id)peek {
    return _dequeueStack.count ? _dequeueStack.lastObject : _enququeStack.firstObject;
}

- (NSInteger)count {
    return _dequeueStack.count + _enququeStack.count;
}

#pragma mark Lazy Getter
- (NSMutableArray *)dequeueStack {
    if (!_dequeueStack) {
        _dequeueStack = [[NSMutableArray alloc] init];
    }
    return _dequeueStack;
}

- (NSMutableArray *)enququeStack {
    if (!_enququeStack) {
        _enququeStack = [[NSMutableArray alloc] init];
    }
    return _enququeStack;
}

@end

#pragma mark - FXDanmakuPriorityQueue
@interface FXDanmakuPriorityQueue()

@property (nonatomic, strong) FXInnerStackQueue<FXDanmakuItemData *> *highPriorityQueue;
@property (nonatomic, strong) FXInnerStackQueue<FXDanmakuItemData *> *normalPriorityQueue;

@end

@implementation FXDanmakuPriorityQueue

- (void)enqueue:(FXDanmakuItemData *)data {
    if (data.priority == FXDataPriorityHigh) {
        [self.highPriorityQueue enqueue:data];
    } else {
        [self.normalPriorityQueue enqueue:data];
    }
}

- (FXDanmakuItemData *)dequeue {
    return !_highPriorityQueue || _highPriorityQueue.isEmpty ? [_normalPriorityQueue dequeue] : [_highPriorityQueue dequeue];
}

- (void)emptyQueue {
    [_highPriorityQueue emptyQueue];
    [_normalPriorityQueue emptyQueue];
}

#pragma mark Computed Properties
- (BOOL)isEmpty {
    return (!_highPriorityQueue || _highPriorityQueue.isEmpty)
    && (!_normalPriorityQueue || _normalPriorityQueue.isEmpty);
}

- (FXDanmakuItemData *)peek {
    return !_highPriorityQueue || _highPriorityQueue.isEmpty ? _normalPriorityQueue.peek : _highPriorityQueue.peek;
}

- (NSInteger)count {
    return _highPriorityQueue.count + _normalPriorityQueue.count;
}

#pragma mark Lazy Getter
- (FXInnerStackQueue<FXDanmakuItemData *> *)normalPriorityQueue {
    if (!_normalPriorityQueue) {
        _normalPriorityQueue = [[FXInnerStackQueue alloc] init];
    }
    return _normalPriorityQueue;
}

- (FXInnerStackQueue<FXDanmakuItemData *> *)highPriorityQueue {
    if (!_highPriorityQueue) {
        _highPriorityQueue = [[FXInnerStackQueue alloc] init];
    }
    return _highPriorityQueue;
}

@end
