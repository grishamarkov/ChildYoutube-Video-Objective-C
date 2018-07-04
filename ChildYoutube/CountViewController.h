//
//  CountViewController.h
//  ChildYoutube
//
//  Created by Sandro Albert on 16/07/16.
//  Copyright (c) 2016. Sandro Albert All rights reserved.

#import <UIKit/UIKit.h>

@class CountViewController;

@protocol CountViewControllerDelegate <NSObject>
- (void)countViewControllerDidSelect:(CountViewController *)controller;
@end

@interface CountViewController : UIViewController

@property (weak, nonatomic) id <CountViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UITextField *countFld;

- (IBAction)onDone:(id)sender;
- (IBAction)onResetHistory:(id)sender;

@end
