//
//  SettingViewController.h
//  ChildYoutube
//
//  Created by Sandro Albert on 16/07/16.
//  Copyright (c) 2016. Sandro Albert All rights reserved.
//

#import <UIKit/UIKit.h>

@class SettingViewController;

@protocol SettingViewControllerDelegate
- (void)settingViewControllerDidFinish:(SettingViewController *)controller;
- (void)settingViewControllerPasscodeEnabled:(SettingViewController *)controller;
- (void)settingViewControllerPasscodeDisabled:(SettingViewController *)controller;
@end

@interface SettingViewController : UITableViewController

@property (weak, nonatomic) id <SettingViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UISwitch *seekSwtch;
@property (weak, nonatomic) IBOutlet UISwitch *volumeSwtch;
@property (weak, nonatomic) IBOutlet UISwitch *passcodeSwtch;
@property (weak, nonatomic) IBOutlet UILabel *timerLbl;
@property (weak, nonatomic) IBOutlet UILabel *countLbl;
@property (weak, nonatomic) IBOutlet UITableViewCell *changeCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *timerCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *countCell;

- (IBAction)onDone:(id)sender;
- (IBAction)onEnablePasscode:(UISwitch *)sender;

@end
