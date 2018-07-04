//
//  TimerViewController.h
//  ChildYoutube
//
//  Created by Sandro Albert on 16/07/16.
//  Copyright (c) 2016. Sandro Albert All rights reserved.
//

#import <UIKit/UIKit.h>

@class TimerViewController;

@protocol TimerViewControllerDelegate <NSObject>
- (void)timerViewControllerDidSelect:(TimerViewController *)controller;
@end

@interface TimerViewController : UIViewController

@property (weak, nonatomic) id <TimerViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *timerLbl;
@property (weak, nonatomic) IBOutlet UIPickerView *timerPicker;

- (IBAction)onDone:(id)sender;

@end
