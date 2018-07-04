//
//  SettingViewController.m
//  ChildYoutube
//
//  Created by Sandro Albert on 16/07/16.
//  Copyright (c) 2016. Sandro Albert All rights reserved.
//

#import "SettingViewController.h"
#import "Utils.h"
#import "PasscodeCoordinator.h"
#import "TimerViewController.h"
#import "CountViewController.h"

@interface SettingViewController ()

@end

@implementation SettingViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    NSUserDefaults *userStore = [NSUserDefaults standardUserDefaults];
    self.seekSwtch.on = [[userStore objectForKey:kEnableSeekControl] boolValue];
    self.volumeSwtch.on = [[userStore objectForKey:kEnableVolumeControl] boolValue];
    self.passcodeSwtch.on = [[PasscodeCoordinator sharedCoordinator] isPasscodeProtectionOn];
    
    if (self.passcodeSwtch.on) {
        [self enabledPasscode];
    } else {
        [self disabledPasscode];
    }
}

- (void)enabledPasscode
{
    self.changeCell.alpha = 1.f;
    self.timerCell.alpha = 1.f;
    self.countCell.alpha = 1.f;
    
    [self refreshTimerLabel];
    [self refreshCountLabel];
    
    [self.delegate settingViewControllerPasscodeEnabled:self];
}

- (void)refreshTimerLabel
{
    NSNumber *inactivityDuration = [[PasscodeCoordinator sharedCoordinator] getPasscodeInactivityDurationInMinutes];
    NSInteger timerVal = [inactivityDuration integerValue];
    if (timerVal < 1) {
        timerVal = 1;
    }
    NSString *timerStr = [Utils timerStringForMin:timerVal];
    self.timerLbl.text = [@"Timer: " stringByAppendingString:timerStr];
}

- (void)refreshCountLabel
{
    NSUserDefaults *userStore = [NSUserDefaults standardUserDefaults];
    self.countLbl.text = [@"Maximum Count: " stringByAppendingFormat:@"%ld", (long)[userStore integerForKey:kMaximumCount]];
}

- (void)disabledPasscode
{
    self.changeCell.alpha = 0.f;
    self.timerCell.alpha = 0.f;
    self.countCell.alpha = 0.f;
    
    [self.delegate settingViewControllerPasscodeDisabled:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
/*
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return 0;
}
*/
/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

// Called after the user changes the selection.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 3) {
        [[PasscodeCoordinator sharedCoordinator] changePasscodeWithCompletion:^(BOOL success) {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"showTimer"] || [[segue identifier] isEqualToString:@"showCount"]) {
        id destinationCtlr = [segue destinationViewController];
        [destinationCtlr setDelegate:self];
        [[destinationCtlr view] setBackgroundColor:self.view.backgroundColor];
    }
}

- (IBAction)onDone:(id)sender {
    NSUserDefaults *userStore = [NSUserDefaults standardUserDefaults];
	[userStore setObject:@(self.seekSwtch.on) forKey:kEnableSeekControl];
	[userStore setObject:@(self.volumeSwtch.on) forKey:kEnableVolumeControl];
    [userStore synchronize];
    
    [self.delegate settingViewControllerDidFinish:self];
}

- (IBAction)onEnablePasscode:(UISwitch *)sender {
    if (sender.on) {
        [[PasscodeCoordinator sharedCoordinator] setupNewPasscodeWithCompletion:^(BOOL success) {
            if (success) {
                [self enabledPasscode];
            } else {
                sender.on = NO;
            }
        }];
    } else {
        [[PasscodeCoordinator sharedCoordinator] disablePasscodeProtectionWithCompletion:^(BOOL success) {
            if (success) {
                [self disabledPasscode];
            } else {
                sender.on = YES;
            }
        }];
    }
}

#pragma mark - TimerViewControllerDelegate

- (void)timerViewControllerDidSelect:(TimerViewController *)controller
{
    [self refreshTimerLabel];
}

#pragma mark - CountViewControllerDelegate

- (void)countViewControllerDidSelect:(CountViewController *)controller
{
    [self refreshCountLabel];
}

@end
