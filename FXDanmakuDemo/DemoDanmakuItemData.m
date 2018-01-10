//
//  DemoDanmakuItemData.m
//  FXDanmakuDemo
//
//  Created by ShawnFoo on 2017/2/13.
//  Copyright © 2017年 ShawnFoo. All rights reserved.
//

#import "DemoDanmakuItemData.h"
#import "DemoDanmakuItem.h"

@implementation DemoDanmakuItemData

+ (instancetype)data {
    // Data is kind of viewModel for DanmakuItem, danmaku will create item for data by it's itemReuseIdentifier property
    return [super dataWithItemReuseIdentifier:[DemoDanmakuItem reuseIdentifier]];
}

+ (instancetype)highPriorityData {
    // High Priority data will be displayed first since it will be inserted to queue before normal priority data;
    return [super highPriorityDataWithItemReuseIdentifier:[DemoDanmakuItem reuseIdentifier]];
}

@end
