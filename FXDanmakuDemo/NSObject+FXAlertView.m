//
//  NSObject+FXAlertView.m
//
//
//  Created by ShawnFoo on 10/9/15.
//  Copyright © 2015 shawnfoo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "NSObject+FXAlertView.h"

#define KeyWindow [UIApplication sharedApplication].keyWindow
#define SysVersionBiggerThaniOS7 [[UIDevice currentDevice].systemVersion floatValue] >= 8.0

#define RunBlockSafe(block, ...) {\
if (block) {\
block(__VA_ARGS__);\
}\
}

@implementation NSObject (FXAlertView)

#pragma mark - Private
/**
 *  返回一个view存在于视图阶层上的controller(如无特殊情况, 一般返回最顶层root Controller), 用于呈现AlertViewController, 兼容iOS7以上版本
 (主要是为了兼容iOS9..)
 */
- (UIViewController *)fx_controllerInViewHierarchy {
    
    UIViewController *mostTopController = KeyWindow.rootViewController;
    // presentedViewController: The view controller that is presented by this view controller, one of its ancestors in the view controller hierarchy
    while (mostTopController.presentedViewController) {
        mostTopController = mostTopController.presentedViewController;
    }
    
    return mostTopController;
}

#pragma mark - Public
#pragma mark ConfirmView
- (void)fx_presentConfirmViewWithTitle:(NSString *)title
                               message:( NSString *)message
                    confirmButtonTitle:(NSString *)confirmTitle
                     cancelButtonTitle:(NSString *)cancelTitle
                        confirmHandler:(void (^)(void))confirmHandler
                         cancelHandler:(void (^)(void))cancelHandler {
    
    [self fx_presentConfirmViewInController:nil
                               confirmTitle:title
                                    message:message
                         confirmButtonTitle:confirmTitle
                          cancelButtonTitle:cancelTitle
                             confirmHandler:confirmHandler
                              cancelHandler:cancelHandler];
}

- (void)fx_presentConfirmViewInController:(id)controller
                             confirmTitle:(NSString *)title
                                  message:( NSString *)message
                       confirmButtonTitle:(NSString *)confirmTitle
                        cancelButtonTitle:(NSString *)cancelTitle
                           confirmHandler:(void (^)(void))confirmHandler
                            cancelHandler:(void (^)(void))cancelHandler {
    
    NSString *cancelTitleStr = cancelTitle?:@"取消";
    UIViewController *viewController = controller?:[self fx_controllerInViewHierarchy];
    if (SysVersionBiggerThaniOS7) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        // Create the action.
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelTitleStr style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            RunBlockSafe(cancelHandler);
        }];
        // Add the action.
        [alertController addAction:cancelAction];
        if (confirmTitle) {
            UIAlertAction *otherAction = [UIAlertAction actionWithTitle:confirmTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                RunBlockSafe(confirmHandler)
            }];
            [alertController addAction:otherAction];
        }
        
        [viewController presentViewController:alertController animated:YES completion:nil];
    }
    else { // iOS7
        UIAlertView *alertView;
        if (confirmTitle) {
            alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:viewController cancelButtonTitle:cancelTitleStr otherButtonTitles:confirmTitle, nil];
        }
        else {
            alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:viewController cancelButtonTitle:cancelTitleStr otherButtonTitles:nil];
        }
        alertView.alertViewStyle = UIAlertViewStyleDefault;
        void (^alertViewClickAction)(NSUInteger) =  ^(NSUInteger buttonIndex) {
            if (!buttonIndex) {
                RunBlockSafe(cancelHandler)
            }
            else {
                RunBlockSafe(confirmHandler)
            }
        };
        objc_setAssociatedObject(alertView,
                                 @selector(fx_presentConfirmViewWithTitle:message:confirmButtonTitle:cancelButtonTitle:confirmHandler:cancelHandler:),
                                 alertViewClickAction,
                                 OBJC_ASSOCIATION_COPY_NONATOMIC);
        [alertView show];
    }
}

#pragma mark iOS7 UIAlertView Delegate method

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    void (^alertViewClickAction)(NSUInteger) = objc_getAssociatedObject(alertView,
                                                                        @selector(fx_presentConfirmViewWithTitle:message:confirmButtonTitle:cancelButtonTitle:confirmHandler:cancelHandler:));
    RunBlockSafe(alertViewClickAction, buttonIndex);
}

#pragma mark SelectActionSheet

- (void)fx_presentSelectSheetWithTitle:(NSString *)title
                     cancelButtonTitle:(NSString *)cancelTitle
             twoOtherButtonTitlesArray:(NSArray *)twoOtherTitleArray
                        firstBTHandler:(void (^)(void))firstBTHandler
                       secondBTHandler:(void (^)(void))secondBTHandler {
    
    [self fx_presentSelectSheetByController:nil
                                 sheetTitle:title
                          cancelButtonTitle:cancelTitle
                  twoOtherButtonTitlesArray:twoOtherTitleArray
                             firstBTHandler:firstBTHandler
                            secondBTHandler:secondBTHandler];
}

- (void)fx_presentSelectSheetByController:(id)controller
                               sheetTitle:(NSString *)title
                        cancelButtonTitle:(NSString *)cancelTitle
                twoOtherButtonTitlesArray:(NSArray *)twoOtherTitleArray
                           firstBTHandler:(void (^)(void))firstBTHandler
                          secondBTHandler:(void (^)(void))secondBTHandler {
    
    NSString *cancelTitleStr = cancelTitle?:@"取消";
    UIViewController *viewController = controller?:[self fx_controllerInViewHierarchy];
    if (SysVersionBiggerThaniOS7) {// iOS8
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        // Create the action.
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelTitleStr style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *firstOtherAction = [UIAlertAction actionWithTitle:twoOtherTitleArray[0] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            RunBlockSafe(firstBTHandler);
        }];
        UIAlertAction *secondOtherAction = [UIAlertAction actionWithTitle:twoOtherTitleArray[1] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            RunBlockSafe(secondBTHandler);
        }];
        
        // Add the action.
        [alertController addAction:cancelAction];
        [alertController addAction:firstOtherAction];
        [alertController addAction:secondOtherAction];
        
        [viewController presentViewController:alertController animated:YES completion:nil];
    }
    else { // iOS7
        
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                                 delegate:viewController
                                                        cancelButtonTitle:cancelTitleStr
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:twoOtherTitleArray[0], twoOtherTitleArray[1], nil];
        
        void (^sheetClickAction)(NSUInteger) =  ^(NSUInteger buttonIndex) {
            switch (buttonIndex) {
                case 0:
                    RunBlockSafe(firstBTHandler);
                    break;
                case 1:
                    RunBlockSafe(secondBTHandler);
                    break;
                default:
                    break;
            }
        };
        objc_setAssociatedObject(actionSheet,
                                 @selector(fx_presentSelectSheetWithTitle:cancelButtonTitle:twoOtherButtonTitlesArray:firstBTHandler:secondBTHandler:),
                                 sheetClickAction,
                                 OBJC_ASSOCIATION_COPY_NONATOMIC);
        [actionSheet showInView:viewController.view];
    }
}

#pragma mark iOS7 UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    void (^sheetClickAction)(NSUInteger) = objc_getAssociatedObject(actionSheet, @selector(fx_presentSelectSheetWithTitle:cancelButtonTitle:twoOtherButtonTitlesArray:firstBTHandler:secondBTHandler:));
    RunBlockSafe(sheetClickAction, buttonIndex);
}

@end
