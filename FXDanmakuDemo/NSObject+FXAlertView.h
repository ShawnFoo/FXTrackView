//
//  NSObject+FXAlertView.h
//
//
//  Created by ShawnFoo on 10/9/15.
//  Copyright © 2015 shawnfoo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIAlertView.h>

@interface NSObject (FXAlertView) <UIAlertViewDelegate, UIActionSheetDelegate>

/**
 *  `简单`弹出系统自带 确认窗口(两个按钮:确定和取消)或消息通知窗口(一个按钮:取消功能); 兼容iOS7及以上版本,
        iOS7无需另外实现UIAlertViewDelegate的代理方法, 该Catogory会处理..
 *
 *  @param title            提示窗口标题
 *  @param message          提示消息
 *  @param confirmTitle     确定按钮标题 (设置为nil, 即为仅包含1个取消按钮的消息通知窗口)
 *  @param cancelTitle      取消按钮标题 (nil 则为`取消`)
 *  @param confirmHandler   点击确定按钮执行的block, 不需要则设置nil
 *  @param cancelHandler    点击取消按钮执行的block, 不需要则设置nil
 */
- (void)fx_presentConfirmViewWithTitle:(NSString *)title
                            message:(NSString *)message
                 confirmButtonTitle:(NSString *)confirmTitle
                  cancelButtonTitle:(NSString *)cancelTitle
                     confirmHandler:(void (^)(void))confirmHandler
                      cancelHandler:(void (^)(void))cancelHandler;

/**
 *  弹出系统自带 确认窗口(两个按钮:确定和取消)或消息通知窗口(一个按钮:取消功能); 兼容iOS7及以上版本,
 iOS7无需另外实现UIAlertViewDelegate的代理方法, 该Catogory会处理..
 *
 *  @param controller     呈现AlertView的Controller(nil则为:KeyWindow的rootController)
 *  @param title          提示窗口标题
 *  @param message        提示消息
 *  @param confirmTitle   确定按钮标题 (设置为nil, 即为仅包含1个取消按钮的消息通知窗口)
 *  @param cancelTitle    取消按钮标题 (nil 则为`取消`)
 *  @param confirmHandler 点击确定按钮执行的block, 不需要则设置nil
 *  @param cancelHandler  点击取消按钮执行的block, 不需要则设置nil
 */
- (void)fx_presentConfirmViewInController:(id)controller
                          confirmTitle:(NSString *)title
                               message:( NSString *)message
                    confirmButtonTitle:(NSString *)confirmTitle
                     cancelButtonTitle:(NSString *)cancelTitle
                        confirmHandler:(void (^)(void))confirmHandler
                         cancelHandler:(void (^)(void))cancelHandler;

/**
 *  `简单`弹出系统自带 选择表单; 兼容iOS7及以上版本; iOS7无需另外实现UIActionSheetDelegate的代理方法, 该Catogory会处理..
 *
 *  @param title              标题(nil则无标题)
 *  @param cancelTitle        取消按钮标题(nil则为:取消)
 *  @param twoOtherTitleArray 另外两个选择按钮的标题, NSString数组(按先后顺序展示)
 *  @param firstSelBTHandler  第一个选择按钮触发的Handler Block
 *  @param secondSelBTHandler 第二个选择按钮触发的Handler Block
 */
- (void)fx_presentSelectSheetWithTitle:(NSString *)title
                  cancelButtonTitle:(NSString *)cancelTitle
          twoOtherButtonTitlesArray:(NSArray *)twoOtherTitleArray
                     firstBTHandler:(void (^)(void))firstBTHandler
                    secondBTHandler:(void (^)(void))firstBTHandler;

/**
 *  弹出系统自带 选择表单, 需指定presentingController; 兼容iOS7及以上版本; iOS7无需另外实现UIActionSheetDelegate的代理方法, 该Catogory会处理..
 *
 *  @param controller         呈现ActionSheet的Controller(nil则为:KeyWindow的rootController)
 *  @param title              标题(nil则无标题)
 *  @param cancelTitle        取消按钮标题(nil则为:取消)
 *  @param twoOtherTitleArray 另外两个选择按钮的标题, NSString数组(按先后顺序展示)
 *  @param firstSelBTHandler  第一个选择按钮触发的Handler Block
 *  @param secondSelBTHandler 第二个选择按钮触发的Handler Block
 */
- (void)fx_presentSelectSheetByController:(id)controller
                            sheetTitle:(NSString *)title
                     cancelButtonTitle:(NSString *)cancelTitle
             twoOtherButtonTitlesArray:(NSArray *)twoOtherTitleArray
                        firstBTHandler:(void (^)(void))firstBTHandler
                       secondBTHandler:(void (^)(void))secondBTHandler;

@end


