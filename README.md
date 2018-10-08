# FXDanmaku

[![中文](https://img.shields.io/badge/%E4%B8%AD%E6%96%87-Readme-lightgrey.svg)](https://shawnfoo.github.io/2017/02/26/FXDanmaku%E5%BC%B9%E5%B9%95%E5%BA%93%E4%BB%8B%E7%BB%8D/)
![iOS 7.0+](https://img.shields.io/badge/iOS-7.0%2B-orange.svg)
![pod](https://img.shields.io/badge/Cocoapods-v1.0.7-blue.svg)
![compatible](https://img.shields.io/badge/Compatible-Objective--C%2FSwift-yellow.svg)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](https://github.com/ShawnFoo/FXDanmaku/blob/master/LICENSE)

High-performance danmaku with click event, reusable items and customize configurations.

## Features

1. Except UI operations in main-thread, other operations are in different dispatch queues.
2. Followed producer-cosumer pattern with pthread lib.
3. Defined delegate protocol to handle click response or other events.
4. Methods to register resuable item. Defined **FXDanmakuItem** class to custom your own item by inheriting it.
5. Many configurations to meet your product's requirements. Such as, the velocity of item, the order to insert item, the direction of item movement and so on.
6. Easy to use. Just three control: start(resume), pause, stop. Except that, most methods are thread-safe.
7. Adaptation to the change of device orientaion.

## Preview

![](https://github.com/ShawnFoo/FXDanmaku/blob/master/Images/preview1.gif?raw=true)
![](https://github.com/ShawnFoo/FXDanmaku/blob/master/Images/preview2.gif?raw=true)

## Example

Setup danmaku view:

```
// Configuration
FXDanmakuConfiguration *config = [FXDanmakuConfiguration defaultConfiguration];
config.rowHeight = [DemoDanmakuItem itemHeight];
config.dataQueueCapacity = 500;
config.itemMinVelocity = 80;  // set random velocity between 80 and 120 pt/s
config.itemMaxVelocity = 120;
self.danmaku.configuration = config;

// Delegate
self.danmaku.delegate = self;

// Reuse
[self.danmaku registerNib:[UINib nibWithNibName:NSStringFromClass([DemoDanmakuItem class]) bundle:nil]
   forItemReuseIdentifier:[DemoDanmakuItem reuseIdentifier]];
[self.danmaku registerClass:[DemoBulletinItem class]
     forItemReuseIdentifier:[DemoBulletinItem reuseIdentifier]];
```
Add data:

```
// add data for danmaku view to present
DemoDanmakuItemData *data = [DemoDanmakuItemData data];
[self.danmaku addData:data];

// start running
if (!self.danmaku.isRunning) {
    [self.danmaku start];
}
```
Handle click in delegate method:

```
- (void)danmaku:(FXDanmaku *)danmaku didClickItem:(FXDanmakuItem *)item withData:(DemoDanmakuItemData *)data {
    // handle click event here
}
```

More examples in `FXDanmakuDemo.xcworkspace`.

Demo build succeed in Xcode8.

## Q&A
#### 1. Relationships among rowHeight、estimatedRowSpace and rowSpace.
![](http://wx3.sinaimg.cn/large/9161297cgy1fcyktlu5gnj20k80b475g.jpg)

#### 2. How to create your danmakuItem by nib.
![](http://wx1.sinaimg.cn/large/9161297cgy1fd35qtq40mj20d104zmxq.jpg)

![](http://wx3.sinaimg.cn/large/9161297cgy1fd35qu2f5hj20bl08lt9l.jpg)

Last thing, drag IBOutlet property to setup your custom danmakuItem.

#### 3. Adaptation to the change of device orientaion.

Only when your danmaku view's height will change in different device orientaion, should you do a little work to adapt. Otherwise, you won't need to add any codes.
Let's say, your danmaku view's height is 100pt in portrait, but is 200pt in lanscape. Then add codes below in your controller.

*For iOS8 And Later*

```
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [self.danmaku pause];
    [self.danmaku cleanScreen];

    [coordinator animateAlongsideTransition:nil
								 completion:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
                                 	// resume danmaku after orientation did change
                                 	[self.danmaku start];
                             	 }];
}
```

*For version lower than iOS8*

```
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self.danmaku pause];
    [self.danmaku cleanScreen];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.danmaku start];
}
```

#### 4. How to limit the capacity of the data queue to the FXDanmaku view?

```
// By setting the FXDanmakuConfiguration
FXDanmakuConfiguration *config = [FXDanmakuConfiguration defaultConfiguration];
// The number of FXDanmakuItemData that FXDanmaku view can hold at maximum count.
config.dataQueueCapacity = 500;
// Beyond this value, the data will be discarded.
```

In addition, you still have chance to decide which data can be added into the queue when data quque is full through delegate method.

```
- (BOOL)shouldAddDanmakuItemDataWhenQueueIsFull:(FXDanmakuItemData *)data {
    // Keep adding data with high priority, even the number of the data in queue reaches maximum count
    return FXDataPriorityHigh == data.priority;
}
```

## Requirements
FXDanmaku requires `iOS 7.0+`.

## Installation
#### Cocoapods(iOS7+)

1. Add these lines below to your Podfile

	```
	platform :ios, 'xxx'
	target 'xxx' do
	  pod 'FXDanmaku', '~> 1.0.0'
	end
	```
2. Install the pod by running `pod install`

#### Manually(iOS7+)
Drag `FXDanmaku` document to your project

## License
FXDanmaku is provided under the MIT license. See LICENSE file for details.
