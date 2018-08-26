//
//  ViewController.m
//  FXDanmakuDemo
//
//  Created by ShawnFoo on 16/3/14.
//  Copyright © 2016年 ShawnFoo. All rights reserved.
//

#import "MultiRowsVC.h"
#import "FXDanmaku.h"
#import "NSObject+FXAlertView.h"
#import "DemoDanmakuItemData.h"
#import "DemoDanmakuItem.h"

#define CurrentDevice [UIDevice currentDevice]
#define CurrentOrientation [[UIDevice currentDevice] orientation]
#define ScreenScale [UIScreen mainScreen].scale
#define NotificationCetner [NSNotificationCenter defaultCenter]

@interface MultiRowsVC () <FXDanmakuDelegate>

@property (weak, nonatomic) IBOutlet FXDanmaku *danmaku;

@end

@implementation MultiRowsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self setupDanmaku];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Device Orientation
- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Views
- (void)setupDanmaku {
    FXDanmakuConfiguration *config = [FXDanmakuConfiguration defaultConfiguration];
    config.rowHeight = [DemoDanmakuItem itemHeight];
    self.danmaku.configuration = config;
    self.danmaku.backgroundColor = [UIColor whiteColor];
    self.danmaku.delegate = self;
    [self.danmaku registerNib:[UINib nibWithNibName:NSStringFromClass([DemoDanmakuItem class]) bundle:nil]
       forItemReuseIdentifier:[DemoDanmakuItem reuseIdentifier]];
}

#pragma mark - Observer
- (void)setupObserver {
    [NotificationCetner addObserver:self
                           selector:@selector(applicationWillResignActive:)
                               name:UIApplicationWillResignActiveNotification
                             object:nil];
    [NotificationCetner addObserver:self
                           selector:@selector(applicationDidBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [self.danmaku start];
}

- (void)applicationWillResignActive:(NSNotification*)notification {
    [self.danmaku pause];
}

#pragma mark - Actions
- (IBAction)segmentValueChanged:(UISegmentedControl *)sender {
    // this is a copy FXDanmakuConfiguration object below!
    FXDanmakuConfiguration *config = self.danmaku.configuration;
    // update/change config's property
    config.itemInsertOrder = sender.selectedSegmentIndex;
    // set it back to let danmku refresh
    self.danmaku.configuration = config;
}

- (IBAction)addOneData:(id)sender {
    [self addDatasWithCount:1];
}

- (IBAction)addFiveData:(UIButton *)sender {
    [self addDatasWithCount:5];
}

- (IBAction)addTwentyFiveData:(id)sender {
    [self addDatasWithCount:25];
}

- (IBAction)start:(id)sender {
    [self.danmaku start];
}

- (IBAction)pause:(id)sender {
    [self.danmaku pause];
}

- (IBAction)stop:(id)sender {
    [self.danmaku stop];
}

#pragma mark - FXDanmakuDelegate
- (void)danmaku:(FXDanmaku *)danmaku didClickItem:(FXDanmakuItem *)item withData:(DemoDanmakuItemData *)data {
    [self fx_presentConfirmViewWithTitle:nil
                                 message:[NSString stringWithFormat:@"You clicked item %@", data.desc]
                      confirmButtonTitle:nil
                       cancelButtonTitle:@"Ok"
                          confirmHandler:nil
                           cancelHandler:nil];
}

- (BOOL)shouldAddDanmakuItemDataWhenQueueIsFull:(FXDanmakuItemData *)data {
    // only discard normal priority data when data queue is beyond limit.
    return FXDataPriorityHigh == data.priority;
}

#pragma mark - DataSource
- (void)addDatasWithCount:(NSUInteger)count {
    static NSUInteger index = 0;
    __weak typeof(self) wSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        for (NSUInteger i = 0; i < count; i++) {
            DemoDanmakuItemData *data = [DemoDanmakuItemData data];
            NSInteger num = arc4random() % 6;
            data.avatarName = [NSString stringWithFormat:@"avatar%d", (int)num];
            if (num % 2 == 0) {
                data.desc = [NSString stringWithFormat:@"DanmakuItem-%@", @(index++)];
            } else {
                data.desc = [NSString stringWithFormat:@"Item-%@", @(index++)];
            }
            [wSelf.danmaku addData:data];
        }
        
        if (!wSelf.danmaku.isRunning) {
            [wSelf.danmaku start];
        }
    });
}

#pragma mark - Orientation
#pragma mark For iOS8 And Later
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    // if danmaku view's height will change in different device orientation, you'd better pause danmaku and clean screen before orientation will change.
    [self.danmaku pause];
    // if you could set danmaku.cleanScreenWhenPaused = false, then you need to call 'cleanScreen' method after pause.
    //    [self.danmaku cleanScreen];
    
    [coordinator animateAlongsideTransition:nil
                                 completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
                                     // resume danmaku after orientation did change
                                     [self.danmaku start];
                                 }];
}

#pragma mark For Version below iOS8

#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_9_0
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self.danmaku pause];
    // if you could set danmaku.cleanScreenWhenPaused = false, then you need to call 'cleanScreen' method after pause.
    //    [self.danmaku cleanScreen];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.danmaku start];
}
#endif

@end
