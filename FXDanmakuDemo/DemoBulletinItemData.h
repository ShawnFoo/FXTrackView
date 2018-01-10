//
//  DemoBulletinItemData.h
//  FXDanmakuDemo
//
//  Created by ShawnFoo on 2017/2/18.
//  Copyright © 2017年 ShawnFoo. All rights reserved.
//

#import "FXDanmakuItemData.h"

@interface DemoBulletinItemData : FXDanmakuItemData

@property (nonatomic, copy) NSString *avatarName;
@property (nonatomic, copy) NSString *desc;

+ (instancetype)dataWithDesc:(NSString *)desc avatarName:(NSString *)avatarName;

@end
