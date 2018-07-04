//
//  MainViewController.h
//  ChildYoutube
//
//  Created by Sandro Albert on 16/07/16.
//  Copyright (c) 2016. Sandro Albert All rights reserved.
//

#import "SettingViewController.h"
#import <MBProgressHUD.h>

@interface MainViewController : UIViewController <SettingViewControllerDelegate, UIPopoverControllerDelegate, MBProgressHUDDelegate>

@property (strong, nonatomic) UIPopoverController *settingPopoverController;
@property (weak, nonatomic) IBOutlet UICollectionView *videoCollect;

- (IBAction)onInfo:(id)sender;

@end
