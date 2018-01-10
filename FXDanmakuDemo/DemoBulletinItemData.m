//
//  DemoBulletinItemData.m
//  FXDanmakuDemo
//
//  Created by ShawnFoo on 2017/2/18.
//  Copyright © 2017年 ShawnFoo. All rights reserved.
//

#import "DemoBulletinItemData.h"
#import "DemoBulletinItem.h"

@implementation DemoBulletinItemData

+ (instancetype)dataWithDesc:(NSString *)desc avatarName:(NSString *)avatarName {
    // Data is kind of viewModel for DanmakuItem, danmaku will create item for data by it's itemReuseIdentifier property
    DemoBulletinItemData *data = [DemoBulletinItemData dataWithItemReuseIdentifier:[DemoBulletinItem reuseIdentifier]];
    data.desc = desc;
    data.avatarName = avatarName;
    return data;
}

@end
