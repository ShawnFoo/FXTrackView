//
//  DemoBulletinItem.h
//  FXDanmakuDemo
//
//  Created by ShawnFoo on 2017/2/18.
//  Copyright © 2017年 ShawnFoo. All rights reserved.
//

#import "FXDanmakuItem.h"

@interface DemoBulletinItem : FXDanmakuItem

@property (class, nonatomic, readonly) CGFloat itemHeight;

+ (NSString *)reuseIdentifier;

@end
