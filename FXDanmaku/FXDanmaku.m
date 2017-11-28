//
//  FXDanmaku.m
//  FXDanmakuDemo
//
//  Github: https://github.com/ShawnFoo/FXDanmaku.git
//  Version: 1.0.4
//  Last Modified: 7/16/2017
//  Created by ShawnFoo on 12/4/2015.
//  Copyright © 2015 ShawnFoo. All rights reserved.
//

#import "FXDanmaku.h"
#import <pthread.h>
#import "FXDanmakuMacro.h"
#import "FXReuseObjectQueue.h"
#import "FXDanmakuItem.h"
#import "FXSingleRowItemsManager.h"
#import "FXDanmakuItem_Private.h"
#import "FXGCDTimer.h"
#import "FXGCDOperationQueue.h"
#import <JHChainableAnimations/JHChainableAnimations.h>

typedef NS_ENUM(NSUInteger, DanmakuStatus) {
    StatusNotStarted,
    StatusRunning,
    StatusPaused,
    StatusStoped,
    StatusBreaked
};

@interface FXDanmaku ()

@property (nonatomic, assign) DanmakuStatus status;
@property (nonatomic, assign) DanmakuStatus breakedStatus;
@property (nonatomic, strong) dispatch_semaphore_t statusSemophore;

@property (nonatomic, strong) dispatch_queue_t consumerQueue;
@property (nonatomic, strong) FXGCDOperationQueue *dataProducerQueue;
@property (nonatomic, strong) FXGCDOperationQueue *rowProducerQueue;

@property (nonatomic, strong) NSMutableArray<FXDanmakuItemData *> *dataQueue;
@property (nonatomic, strong) FXReuseObjectQueue *reuseItemQueue;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, FXSingleRowItemsManager *> *rowItemsManager;
@property (nonatomic, strong) NSHashTable<FXGCDTimer *> *resetOccupiedRowTimers;

@property (nonatomic, assign) BOOL hasData;
@property (nonatomic, assign) BOOL hasUnoccupiedRows;

@property (nonatomic, assign) BOOL hasCalculatedRows;
@property (nonatomic, assign) CGSize oldSize;
@property (nonatomic, assign) NSInteger numOfRows;
@property (nonatomic, assign) CGFloat rowSpace;
@property (nonatomic, assign) NSUInteger occupiedRowMaskBit;

@property (nonatomic, weak) FXGCDTimer *innerResumeTimer;

@property (nonatomic, readonly) BOOL shouldAcceptData;

@end

@implementation FXDanmaku {
    pthread_mutex_t _row_mutex;
    pthread_cond_t _row_prod, _row_cons;
    pthread_mutex_t _data_mutex;
    pthread_cond_t _data_prod, _data_cons;
}

@synthesize status = _status;
@synthesize breakedStatus = _breakedStatus;
@synthesize configuration = _configuration;

#pragma mark - Accessor
#pragma mark Lazy Loading
- (dispatch_queue_t)consumerQueue {
    if (!_consumerQueue) {
        _consumerQueue = dispatch_queue_create("shawnfoo.danmaku.consumerQueue", NULL);
    }
    return _consumerQueue;
}

- (FXGCDOperationQueue *)dataProducerQueue {
    if (!_dataProducerQueue) {
        _dataProducerQueue =
        [FXGCDOperationQueue queueWithDispatchQueue:dispatch_queue_create("shawnfoo.danmaku.dataProducerQueue", NULL)];
    }
    return _dataProducerQueue;
}

- (FXGCDOperationQueue *)rowProducerQueue {
    if (!_rowProducerQueue) {
        _rowProducerQueue =
        [FXGCDOperationQueue queueWithDispatchQueue:dispatch_queue_create("shawnfoo.danmaku.rowProducerQueue", NULL)];
    }
    return _rowProducerQueue;
}

- (NSMutableArray<FXDanmakuItemData *> *)dataQueue {
    if (!_dataQueue) {
        _dataQueue = [NSMutableArray array];
    }
    return _dataQueue;
}

- (FXReuseObjectQueue *)reuseItemQueue {
    if (!_reuseItemQueue) {
        _reuseItemQueue = [FXReuseObjectQueue queue];
    }
    return _reuseItemQueue;
}

- (NSMutableDictionary<NSNumber *, FXSingleRowItemsManager *> *)rowItemsManager {
    if (!_rowItemsManager) {
        _rowItemsManager = [NSMutableDictionary dictionaryWithCapacity:_numOfRows];
    }
    return _rowItemsManager;
}

- (NSHashTable<FXGCDTimer *> *)resetOccupiedRowTimers {
    if (!_resetOccupiedRowTimers) {
        _resetOccupiedRowTimers = [NSHashTable weakObjectsHashTable];
    }
    return _resetOccupiedRowTimers;
}

- (FXSingleRowItemsManager *)itemsManagerAtRow:(NSUInteger)row {
    FXSingleRowItemsManager *manager = self.rowItemsManager[@(row)];
    if (!manager) {
        manager = [[FXSingleRowItemsManager alloc] init];
        self.rowItemsManager[@(row)] = manager;
    }
    return manager;
}

- (DanmakuStatus)status {
    DanmakuStatus status;
    dispatch_semaphore_wait(_statusSemophore, DISPATCH_TIME_FOREVER);
    status = _status;
    dispatch_semaphore_signal(_statusSemophore);
    return status;
}

- (DanmakuStatus)breakedStatus {
    DanmakuStatus status;
    dispatch_semaphore_wait(_statusSemophore, DISPATCH_TIME_FOREVER);
    status = _breakedStatus;
    dispatch_semaphore_signal(_statusSemophore);
    return status;
}

- (FXDanmakuConfiguration *)configuration {
    return [_configuration copy];
}

#pragma mark Shortcut Accessory
- (FXSingleRowItemsManager *)rowItemsManagerAtRow:(NSUInteger)row {
    FXSingleRowItemsManager *manager = self.rowItemsManager[@(row)];
    if (!manager) {
        manager = [[FXSingleRowItemsManager alloc] init];
        self.rowItemsManager[@(row)] = manager;
    }
    return manager;
}

#pragma mark Computed Property
- (BOOL)isRunning {
    return StatusRunning == self.status;
}

- (BOOL)shouldAcceptData {
    DanmakuStatus status = self.status;
    BOOL stoped = StatusStoped == status;
    if (stoped || (StatusPaused == status && !_acceptDataWhenPaused)) {
        return false;
    }
    return true;
}

#pragma mark Setter
- (void)setConfiguration:(FXDanmakuConfiguration *)configuration {
    _configuration = [configuration copy];
    if (!_configuration) {
        [self innerBreak];
        return;
    }
    
    _hasCalculatedRows = false;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setStatus:(DanmakuStatus)status {
    dispatch_semaphore_wait(_statusSemophore, DISPATCH_TIME_FOREVER);
    if (StatusBreaked == status && StatusBreaked != _status) {
        _breakedStatus = _status;
    }
    else if (StatusBreaked != status) {
        _breakedStatus = 0;
    }
    _status = status;
    dispatch_semaphore_signal(_statusSemophore);
}

- (void)setBreakedStatus:(DanmakuStatus)breakedStatus {
    dispatch_semaphore_wait(_statusSemophore, DISPATCH_TIME_FOREVER);
    _breakedStatus = breakedStatus;
    dispatch_semaphore_signal(_statusSemophore);
}

#pragma mark - LifeCycle
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonSetup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self commonSetup];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self calcRowsIfNeeded];
}

- (void)removeFromSuperview {
    if (StatusStoped != self.status) {
        [self stop];
    }
    [super removeFromSuperview];
}

- (void)dealloc {
    [_innerResumeTimer invalidate];
    
    pthread_mutex_destroy(&_row_mutex);
    pthread_mutex_destroy(&_data_mutex);
    pthread_cond_destroy(&_row_prod);
    pthread_cond_destroy(&_row_cons);
    pthread_cond_destroy(&_data_prod);
    pthread_cond_destroy(&_data_cons);
    FXLogD(@"FXDanmaku View has been deallocated.");
}

#pragma mark - Setup
- (void)commonSetup {
    _status = StatusNotStarted;
    _cleanScreenWhenPaused = true;
    _emptyDataWhenPaused = false;
    _acceptDataWhenPaused = true;
    _hasCalculatedRows = false;
    
    self.backgroundColor = [UIColor clearColor];
    self.layer.masksToBounds = true;
    
    pthread_mutex_init(&_row_mutex, NULL);
    pthread_cond_init(&_row_prod, NULL);
    pthread_cond_init(&_row_cons, NULL);
    
    pthread_mutex_init(&_data_mutex, NULL);
    pthread_cond_init(&_data_prod, NULL);
    pthread_cond_init(&_data_cons, NULL);
    
    _statusSemophore = dispatch_semaphore_create(1);
    _oldSize = self.frame.size;
}

- (void)calcRowsIfNeeded {
    if (!self->_configuration) {
        return;
    }
    
    if (!self.hasCalculatedRows || !CGSizeEqualToSize(self.oldSize, self.frame.size)) {
        self.hasCalculatedRows = true;
        self.oldSize = self.frame.size;
        
        [self cancelResumeSchedule];
        [self innerBreak];
        [self cleanScreenUnsafe];
        [self calcRowsAndRowHeight];
        [self scheduleToResume];
    }
}

- (void)calcRowsAndRowHeight {
    pthread_mutex_lock(&self->_row_mutex);
    {
        CGFloat viewHeight = self.frame.size.height;
        CGFloat rowHeight = self->_configuration.rowHeight;
        
        CGFloat estimatedRowSpace = self->_configuration.estimatedRowSpace;
        self.numOfRows = floor((viewHeight + estimatedRowSpace) / (rowHeight + estimatedRowSpace));
        self.rowSpace = (viewHeight - self.numOfRows*rowHeight) / (self.numOfRows - 1);
        if (isnan(self.rowSpace)) {
            self.rowSpace = 0;
        }
        self.hasUnoccupiedRows = self.numOfRows > 0;
    }
    pthread_mutex_unlock(&self->_row_mutex);
}

#pragma mark - Register
- (void)registerNib:(nullable UINib *)nib forItemReuseIdentifier:(NSString *)identifier {
    if (identifier.length) {
        [self.reuseItemQueue registerNib:nib forObjectReuseIdentifier:identifier];
    }
}

- (void)registerClass:(nullable Class)itemClass forItemReuseIdentifier:(NSString *)identifier {
    if (identifier.length && ([itemClass isSubclassOfClass:[FXDanmakuItem class]])) {
        [self.reuseItemQueue registerClass:itemClass forObjectReuseIdentifier:identifier];
    }
}

#pragma mark - Data Input
- (void)addData:(FXDanmakuItemData *)data {
    if (!self.shouldAcceptData) return;
    @FXWeakify(self);
    [self.dataProducerQueue addAsyncOperationBlock:^{
        @FXStrongify(self);
        FXReturnIfSelfNil
        pthread_mutex_lock(&self->_data_mutex);
        {
            if ([self insertData:data]) {
                if (!self.hasData) {
                    self.hasData = true;
                    if (StatusRunning == self.status) {
                        pthread_cond_signal(&self->_data_cons);
                    }
                }
            }
        }
        pthread_mutex_unlock(&self->_data_mutex);
    }];
}

- (void)addDatas:(NSArray<FXDanmakuItemData *> *)datas {
    if (!self.shouldAcceptData) return;
    if (!datas.count) return;
    @FXWeakify(self);
    [self.dataProducerQueue addAsyncOperationBlock:^{
        @FXStrongify(self);
        FXReturnIfSelfNil
        pthread_mutex_lock(&self->_data_mutex);
        {
            BOOL addedData = false;
            for (FXDanmakuItemData *data in datas) {
                if ([self insertData:data]) {
                    addedData = true;
                }
            }
            if (!self.hasData && addedData) {
                self.hasData = true;
                if (StatusRunning == self.status) {
                    pthread_cond_signal(&self->_data_cons);
                }
            }
        }
        pthread_mutex_unlock(&self->_data_mutex);
    }];
}

- (void)emptyData {
    [self.dataProducerQueue cancelAllOperation];
    @FXWeakify(self);
    [self.dataProducerQueue addAsyncOperationBlock:^{
        @FXStrongify(self);
        FXReturnIfSelfNil
        pthread_mutex_lock(&self->_data_mutex);
        {
            [self->_dataQueue removeAllObjects];
            self.hasData = false;
        }
        pthread_mutex_unlock(&self->_data_mutex);
    }];
}

#pragma mark - Actions
- (void)start {
    @FXWeakify(self);
    FXRunBlockSafe_MainThread(^{
        @FXStrongify(self);
        FXReturnIfSelfNil
        if (!self->_configuration) {
            FXException(@"Please set danmaku's confiuration, it can't be nil!");
            return;
        }
        
        if (StatusRunning != self.status) {
            self.status = StatusRunning;
            if (!self.hasCalculatedRows) {
                FXLogD(@"Since danmaku hasn't be layout yet, it will start later.");
                [self innerBreak];
                return;
            }
            [self startConsuming];
        }
    });
}

- (void)pause {
    if (StatusRunning == self.status) {
        self.status = StatusPaused;
        [self breakConsumerSuspensionIfNeeded];
    }
}

- (void)stop {
    if (StatusStoped != self.status) {
        self.status = StatusStoped;
        [self breakConsumerSuspensionIfNeeded];
    }
}

- (void)innerBreak {
    self.status = StatusBreaked;
    [self breakConsumerSuspensionIfNeeded];
}

- (void)innerResume {
    DanmakuStatus resumeStatus = self.breakedStatus;
    self.status = resumeStatus;
    if (resumeStatus == StatusRunning) {
        [self startConsuming];
    }
}

- (void)scheduleToResume {
    const NSTimeInterval cInterval = 0.01;
    
    [self cancelResumeSchedule];
    @FXWeakify(self);
    self.innerResumeTimer = [FXGCDTimer scheduledTimerWithInterval:cInterval
                                                             queue:nil
                                                             block:^
                             {
                                 @FXStrongify(self);
                                 FXReturnIfSelfNil
                                 [self innerResume];
                             }];
    
}

- (void)cancelResumeSchedule {
    if (self.innerResumeTimer) {
        [self.innerResumeTimer invalidate];
    }
}

#pragma mark - Consumer
- (void)startConsuming {
    @FXWeakify(self);
    dispatch_async(self.consumerQueue, ^{
        @FXStrongify(self);
        [self consumeData];
    });
}

- (void)breakConsumerSuspensionIfNeeded {
    @FXWeakify(self);
    [self.rowProducerQueue addAsyncOperationBlock:^{
        @FXStrongify(self);
        FXReturnIfSelfNil
        pthread_mutex_lock(&self->_row_mutex);
        {
            if (!self.hasUnoccupiedRows) {
                self.hasUnoccupiedRows = true;
                pthread_cond_signal(&self->_row_cons);
            }
        }
        pthread_mutex_unlock(&self->_row_mutex);
    }];
    
    [self.dataProducerQueue addAsyncOperationBlock:^{
        @FXStrongify(self);
        FXReturnIfSelfNil
        pthread_mutex_lock(&self->_data_mutex);
        {
            if (!self.hasData) {
                self.hasData = true;
                pthread_cond_signal(&self->_data_cons);
            }
        }
        pthread_mutex_unlock(&self->_data_mutex);
    }];
}

#pragma mark - Clean Screen
- (void)cleanScreen {
    @FXWeakify(self);
    FXRunBlockSafe_MainThread(^{
        @FXStrongify(self);
        FXReturnIfSelfNil
        [self innerBreak];
        [self cleanScreenUnsafe];
        [self innerResume];
    });
}

- (void)cleanScreenUnsafe {
    BOOL hasItems = false;
    for (UIView *subView in self.subviews) {
        if ([subView isKindOfClass:[FXDanmakuItem class]]) {
            hasItems = true;
            [subView removeFromSuperview];
            [self.reuseItemQueue enqueueReuseObject:(FXReuseObject)subView];
        }
    }
    if (hasItems) {
        [self resetOccupiedRows];
    }
    self.rowItemsManager = nil;
}

#pragma mark - Data Producer & Consumer
- (FXDanmakuItemData *)fetchData {
    FXDanmakuItemData *data = nil;
    pthread_mutex_lock(&self->_data_mutex);
    {
        while (!self.hasData) {
            pthread_cond_wait(&self->_data_cons, &self->_data_mutex);
        }
        if (StatusRunning == self.status) {
            data = self->_dataQueue.firstObject;
            if (data) {
                [self->_dataQueue removeObjectAtIndex:0];
            }
            self.hasData = self->_dataQueue.count > 0;
        }
    }
    
    pthread_mutex_unlock(&self->_data_mutex);
    return data;
}

- (BOOL)insertData:(FXDanmakuItemData *)data {
    if (![self shouldInsertData:data]) {
        return false;
    }
    if (FXDataPriorityHigh == data.priority) {
        NSUInteger insertIndex = 0;
        for (NSUInteger i = 0; i < self.dataQueue.count; i++) {
            FXDanmakuItemData *data = self.dataQueue[i];
            if (FXDataPriorityNormal == data.priority) {
                insertIndex = i;
                break;
            }
        }
        [self.dataQueue insertObject:data atIndex:insertIndex];
    }
    else {
        [self.dataQueue addObject:data];
    }
    return true;
}

- (BOOL)shouldInsertData:(FXDanmakuItemData *)data {
    BOOL shouldInsert = self.dataQueue.count < self->_configuration.dataQueueCapacity;
    
    id<FXDanmakuDelegate> strongDelegate = self.delegate;
    if (!shouldInsert
        && [strongDelegate respondsToSelector:@selector(shouldAddDanmakuItemDataWhenQueueIsFull:)]) {
        shouldInsert = [strongDelegate shouldAddDanmakuItemDataWhenQueueIsFull:data];
    }
    return shouldInsert;
}

#pragma mark - Row Producer & Consumer
- (NSInteger)fetchUnoccupiedRow {
    NSInteger row;
    switch (self->_configuration.itemInsertOrder) {
        case FXDanmakuItemInsertOrderRandom:
            row = [self fetchRandomUnoccupiedRow];
            break;
        case FXDanmakuItemInsertOrderFromBottom:
            row = [self fetchOrderedUnoccupiedRowFromBottom];
            break;
        default:
            row = [self fetchOrderedUnoccupiedRowFromTop];
            break;
    }
    return row;
}

- (NSInteger)fetchRandomUnoccupiedRow {
    NSInteger row = -1;
    pthread_mutex_lock(&self->_row_mutex);
    {
        while (!self.hasUnoccupiedRows) {
            pthread_cond_wait(&self->_row_cons, &self->_row_mutex);
        }
        if (StatusRunning == self.status) {
            UInt8 *array = NULL;
            int n = 0;
            for (int i = 0; i < self.numOfRows; i++) {
                if (1<<i & self.occupiedRowMaskBit) {
                    continue;
                }
                if (!array) {
                    array = malloc(sizeof(UInt8)*(self.numOfRows-i));
                }
                array[n++] = i;
            }
            if (array) {
                row = array[arc4random()%n];
                [self addOccupiedRow:row];
                self.hasUnoccupiedRows = n > 1 ? true : false;
                free(array);
            }
            else {
                self.hasUnoccupiedRows = false;
            }
        }
    }
    pthread_mutex_unlock(&self->_row_mutex);
    return row;
}

- (NSInteger)fetchOrderedUnoccupiedRowFromBottom {
    NSInteger row = -1;
    pthread_mutex_lock(&self->_row_mutex);
    {
        while (!self.hasUnoccupiedRows) {
            pthread_cond_wait(&self->_row_cons, &self->_row_mutex);
        }
        if (StatusRunning == self.status) {
            BOOL hasRows = false;
            for (NSInteger i = self.numOfRows-1; i > -1; i--) {
                if (1<<i & self.occupiedRowMaskBit) {
                    continue;
                }
                else if (-1 == row) {
                    row = i;
                }
                else {
                    hasRows = true;
                    break;
                }
            }
            if (row > -1) {
                [self addOccupiedRow:row];
            }
            self.hasUnoccupiedRows = hasRows;
        }
    }
    pthread_mutex_unlock(&self->_row_mutex);
    return row;
}

- (NSInteger)fetchOrderedUnoccupiedRowFromTop {
    NSInteger row = -1;
    pthread_mutex_lock(&self->_row_mutex);
    {
        while (!self.hasUnoccupiedRows) {
            pthread_cond_wait(&self->_row_cons, &self->_row_mutex);
        }
        if (StatusRunning == self.status) {
            BOOL hasRows = false;
            for (int i = 0; i < self.numOfRows; i++) {
                if (1<<i & self.occupiedRowMaskBit) {
                    continue;
                }
                else if (-1 == row) {
                    row = i;
                }
                else {
                    hasRows = true;
                    break;
                }
            }
            if (row > -1) {
                [self addOccupiedRow:row];
            }
            self.hasUnoccupiedRows = hasRows;
        }
    }
    pthread_mutex_unlock(&self->_row_mutex);
    return row;
}

- (void)addOccupiedRow:(NSInteger)row {
    if (row < self.numOfRows) {
        self.occupiedRowMaskBit |= 1<<row;
    }
}

- (void)removeOccupiedRow:(NSInteger)row {
    pthread_mutex_lock(&self->_row_mutex);
    {
        if ((row < self.numOfRows)
            && (1<<row & self.occupiedRowMaskBit))
        {
            self.occupiedRowMaskBit -= 1<<row;
            if (!self.hasUnoccupiedRows) {
                self.hasUnoccupiedRows = true;
                pthread_cond_signal(&self->_row_cons);
            }
        }
    }
    pthread_mutex_unlock(&self->_row_mutex);
}

- (void)resetOccupiedRows {
    for (FXGCDTimer *timer in self.resetOccupiedRowTimers) {
        [timer invalidate];
    }
    
    @FXWeakify(self);
    [self.rowProducerQueue addAsyncOperationBlock:^{
        @FXStrongify(self);
        FXReturnIfSelfNil
        pthread_mutex_lock(&self->_row_mutex);
        {
            self.occupiedRowMaskBit = 0;
            self.hasUnoccupiedRows = self.numOfRows > 0;
        }
        pthread_mutex_unlock(&self->_row_mutex);
    }];
}

#pragma mark - Animation Computation
- (NSUInteger)randomVelocity {
    NSUInteger minVel = self->_configuration.itemMinVelocity;
    NSUInteger maxVel = self->_configuration.itemMaxVelocity;
    if (minVel == maxVel) {
        return minVel;
    }
    return arc4random()%(maxVel-minVel) + minVel;
}

- (CGPoint)startPointWithRow:(NSUInteger)row {
    CGFloat yAxis = row * (self->_configuration.rowHeight+self.rowSpace);
    return CGPointMake(self.frame.size.width, yAxis);
}

- (NSTimeInterval)animationDurationOfVelocity:(NSUInteger)velocity itemWidth:(CGFloat)width {
    return (self.frame.size.width + width) / velocity;
}

- (NSTimeInterval)resetOccupiedRowTimeOfVelocity:(NSUInteger)velocity itemWidth:(CGFloat)width {
    float ratio = self->_configuration.moveRatioToResetOccupiedRow;
    return (self.bounds.size.width*ratio + width) / velocity;
}

#pragma mark - Item Presentation
- (void)consumeData {
    while (StatusRunning == self.status) {
        FXDanmakuItemData *data = [self fetchData];
        if (data) {
            NSInteger unoccupiedRow = [self fetchUnoccupiedRow];
            if (unoccupiedRow > -1) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self presentData:data atRow:unoccupiedRow];
                });
            }
            else if (StatusPaused == self.status && !self.emptyDataWhenPaused) {
                data.priority = FXDataPriorityHigh;
                [self addData:data];
            }
        }
    }
    [self stopConsumingData];
}

- (void)stopConsumingData {
    BOOL emptyData = false;
    BOOL cleanScreen = false;
    
    DanmakuStatus status = self.status;
    if (StatusStoped == status) {
        emptyData = true;
        cleanScreen = true;
    }
    else if (StatusPaused == status) {
        emptyData = self.emptyDataWhenPaused;
        cleanScreen = self.cleanScreenWhenPaused;
    }
    
    if (emptyData) {
        [self emptyData];
    }
    if (cleanScreen) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self cleanScreenUnsafe];
        });
    }
}

- (void)presentData:(FXDanmakuItemData *)data atRow:(NSUInteger)row {
    FXDanmakuItem *item = (FXDanmakuItem *)[self.reuseItemQueue dequeueReuseObjectWithIdentifier:data.itemReuseIdentifier];
    if (!item) {
        FXException(@"Didn't register resue class or nib for %@(itemReuseIdentifier)", data.itemReuseIdentifier);
    }
    item.p_data = data;
    
    [self addSubview:item];
    [[self itemsManagerAtRow:row] addDanmakuItem:item];
    [self notifyDelegateWillDisplayItem:item];
    [item itemWillBeDisplayedWithData:data];
    
    BOOL moveFromLeftToRight = FXDanmakuItemMoveDirectionLeftToRight == self->_configuration.itemMoveDirection;
    CGFloat itemWidth = [item itemWidthWithData:data];
    if (itemWidth < 0) {
        itemWidth = [item systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].width;
    }
    CGPoint point = [self startPointWithRow:row];
    if (moveFromLeftToRight) {
        point.x = -itemWidth;
    }
    NSUInteger velocity = [self randomVelocity];
    NSTimeInterval animDuration = [self animationDurationOfVelocity:velocity itemWidth:itemWidth];
    NSTimeInterval resetTime = [self resetOccupiedRowTimeOfVelocity:velocity itemWidth:itemWidth];
    
    item.frame = CGRectMake(point.x, point.y , itemWidth, self->_configuration.rowHeight);
    CGRect toFrame = item.frame;
    toFrame.origin.x = moveFromLeftToRight ? self.frame.size.width : -itemWidth;
    
    CGFloat centerX = (self.frame.size.width - toFrame.size.width) * 0.5f;
    __weak __typeof(&*self)weakSelf = self;
    __weak FXDanmakuItem *weakItem = item;
    JHChainableAnimator *animator = [[JHChainableAnimator alloc] initWithView:item];
    animator.completionBlock = ^{
        [weakItem removeFromSuperview];
        [weakSelf.rowItemsManager[@(row)] removeDanmakuItem:weakItem];
        [weakSelf notifyDelegateDidEndDisplayingItem:weakItem];
        [weakSelf.reuseItemQueue enqueueReusableObject:(FXReuseObject)weakItem];
    };
    if (data.animate == FXDataAnimateDefault) {
        animator.makeX(toFrame.origin.x).animate(animDuration);
    } else {
        CGFloat itemInDuration = 0.5f;
        CGFloat waitDuration = animDuration - itemInDuration * 2;
        resetTime = animDuration - itemInDuration;
        if (waitDuration < 0) {
            waitDuration = 0.1f;
        }
        animator.makeX(centerX).thenAfter(itemInDuration).wait(waitDuration).makeX(toFrame.origin.x).animate(itemInDuration);
    }
    
    @FXWeakify(self);
    FXGCDTimer *resetTimer = [FXGCDTimer scheduledTimerWithInterval:resetTime
                                                              queue:self.rowProducerQueue.queue
                                                              block:^
                              {
                                  @FXStrongify(self);
                                  FXReturnIfSelfNil
                                  [self removeOccupiedRow:row];
                              }];
    [self.resetOccupiedRowTimers addObject:resetTimer];
}

#pragma mark - Responder Chain
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (!self.isUserInteractionEnabled || self.isHidden || self.alpha <= 0.0) {
        return nil;
    }
    UIView *hitView = nil;
    if ([self pointInside:point withEvent:event]) {
        for (UIView *subView in [self.subviews reverseObjectEnumerator]) {
            if (![subView isKindOfClass:[FXDanmakuItem class]]) {
                CGPoint convertedPoint = [self convertPoint:point toView:subView];
                if ((hitView = [subView hitTest:convertedPoint withEvent:event])) {
                    return hitView;
                }
            }
        }
        if (self.delegate && [self itemAtTouchPoint:point] != nil) {
            hitView = self;
        }
    }
    return hitView;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = touches.anyObject;
    if (touch.tapCount == 1) {
        [self handleTouchAtPoint:[touch locationInView:self]];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {}

#pragma mark Touch Handler
- (FXDanmakuItem *)itemAtTouchPoint:(CGPoint)point {
    NSUInteger row = point.y / (self->_configuration.rowHeight + self.rowSpace);
    FXSingleRowItemsManager *manager = self->_rowItemsManager[@(row)];
    return [manager itemAtPoint:point];
}

- (void)handleTouchAtPoint:(CGPoint)point {
    FXDanmakuItem *item = [self itemAtTouchPoint:point];
    if (item) {
        [self notifyDelegateClickedItem:item];
    }
}

#pragma mark - Invoke Delegate
- (void)notifyDelegateWillDisplayItem:(FXDanmakuItem *)item {
    id<FXDanmakuDelegate> strongDelegate = self.delegate;
    if ([strongDelegate respondsToSelector:@selector(danmaku:willDisplayItem:withData:)]) {
        [strongDelegate danmaku:self willDisplayItem:item withData:item.p_data];
    }
}

- (void)notifyDelegateDidEndDisplayingItem:(FXDanmakuItem *)item {
    id<FXDanmakuDelegate> strongDelegate = self.delegate;
    if ([strongDelegate respondsToSelector:@selector(danmaku:didEndDisplayingItem:withData:)]) {
        [strongDelegate danmaku:self didEndDisplayingItem:item withData:item.p_data];
    }
}

- (void)notifyDelegateClickedItem:(FXDanmakuItem *)item {
    id<FXDanmakuDelegate> strongDelegate = self.delegate;
    if ([strongDelegate respondsToSelector:@selector(danmaku:didClickItem:withData:)]) {
        [strongDelegate danmaku:self didClickItem:item withData:item.p_data];
    }
}

@end
