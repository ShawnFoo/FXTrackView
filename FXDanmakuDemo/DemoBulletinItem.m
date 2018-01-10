
//
//  DemoBulletinItem.m
//  FXDanmakuDemo
//
//  Created by ShawnFoo on 2017/2/18.
//  Copyright © 2017年 ShawnFoo. All rights reserved.
//

#import "DemoBulletinItem.h"
#import "DemoBulletinItemData.h"
#import "Masonry.h"
#import "UIImageView+CornerRadius.h"

#define UIColorFromHexRGB(rgbValue) \
([UIColor colorWithRed:((float)((rgbValue&0xFF0000)>>16))/255.0 \
green:((float)((rgbValue&0xFF00)>>8))/255.0 \
blue:((float)(rgbValue&0xFF))/255.0 \
alpha:1])

@interface DemoBulletinItem ()

@property (nonatomic, readonly) NSDictionary *descAttrs;
@property (nonatomic, readonly) NSString *prefix;
@property (nonatomic, readonly) NSDictionary *prefixAttrs;
@property (nonatomic, readonly) CGFloat avatarLength;

@property (nonatomic, weak) UIImageView *avatarImageView;
@property (nonatomic, weak) UILabel *descLabel;
@property (nonatomic, weak) UIImageView *backgroundImageView;

@end

@implementation DemoBulletinItem

#pragma mark - Constants
+ (CGFloat)itemHeight {
    return 32;
}

+ (NSString *)reuseIdentifier {
    // any unique identifiers, recommend to use class'name, but, of cource, you can name it on your own
    return @"BulletinItemIdentifier";
}

#pragma mark - Accssor
- (NSDictionary *)descAttrs {
    static NSDictionary *sDescAttrs = nil;
    if (!sDescAttrs) {
        sDescAttrs = @{
                       NSFontAttributeName: [UIFont systemFontOfSize:24],
                       NSForegroundColorAttributeName: UIColorFromHexRGB(0xAC7A7A)
                       };
    }
    return sDescAttrs;
}

- (NSString *)prefix {
    return @"Bulletin: ";
}

- (NSDictionary *)prefixAttrs {
    static NSDictionary *sPrefixAttrs = nil;
    if (!sPrefixAttrs) {
        sPrefixAttrs = @{
                         NSFontAttributeName: [UIFont systemFontOfSize:20],
                         NSForegroundColorAttributeName: UIColorFromHexRGB(0xAD2727)
                         };
    }
    return sPrefixAttrs;
}

- (NSAttributedString *)attrStringWithDesc:(NSString *)desc {
    NSMutableAttributedString *mAttrStr =
    [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%@", self.prefix, desc]
                                           attributes:self.descAttrs];
    NSRange prefixRange = NSMakeRange(0, self.prefix.length);
    [mAttrStr setAttributes:self.prefixAttrs range:prefixRange];
    return [mAttrStr copy];
}

- (CGFloat)avatarLength {
    return 28;
}

#pragma mark - Factory
+ (instancetype)item {
    return [[self alloc] initWithReuseIdentifier:[self reuseIdentifier]];
}

#pragma mark - LifeCycle
- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (newSuperview && !self.avatarImageView) {
        [self setupSubviews];
    }
}

#pragma mark - Overrides
#pragma mark Reuse
- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.avatarImageView.image = nil;
    self.descLabel.attributedText = nil;
}

- (void)itemWillBeDisplayedWithData:(DemoBulletinItemData *)data {
    
    self.descLabel.attributedText = [self attrStringWithDesc:data.desc];
    UIImage *avatarImg = nil;
    if (data.avatarName && (avatarImg = [UIImage imageNamed:data.avatarName])) {
        self.avatarImageView.image = avatarImg;
    }
}

#pragma mark - Setup
- (void)setupSubviews {
    
    /*
     Set constraints for subviews to extend superview's, the item's, width!
     Or you can also set item's bounds manually in itemWillBeDisplayedWithData: method!
     */
    
    const CGFloat cAvatarMargin = 2;
    const CGFloat cItemHeight = [[self class] itemHeight];
    const CGFloat cLabelRightMargin = 4;
    
    UIImageView *avatarIV = [[UIImageView alloc] init];
    [avatarIV zy_cornerRadiusAdvance:cItemHeight/2.0 rectCornerType:UIRectCornerAllCorners];
    [self addSubview:avatarIV];
    [avatarIV mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.equalTo(cAvatarMargin);
        make.bottom.equalTo(-cAvatarMargin);
        make.width.equalTo(self.avatarLength);
    }];
    self.avatarImageView = avatarIV;
    
    UILabel *descLabel = [UILabel new];
    [self addSubview:descLabel];
    [descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(avatarIV.mas_right).offset(cAvatarMargin);
        make.right.equalTo(-cLabelRightMargin);
        make.top.bottom.equalTo(self);
    }];
    self.descLabel = descLabel;
    
    UIImageView *backgroundIV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bulletin_bg"]];
    [self insertSubview:backgroundIV atIndex:0];
    [backgroundIV mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    self.backgroundImageView = backgroundIV;
}

@end
