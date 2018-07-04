//
//  TimerViewController.m
//  ChildYoutube
//
//  Created by Sandro Albert on 16/07/16.
//  Copyright (c) 2016. Sandro Albert All rights reserved.
//

#import "TimerViewController.h"
#import "PasscodeCoordinator.h"
#import "Utils.h"

@interface TimerViewController ()

@end

@implementation TimerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSNumber *inactivityDuration = [[PasscodeCoordinator sharedCoordinator] getPasscodeInactivityDurationInMinutes];
    NSInteger timerVal = [inactivityDuration integerValue];
    if (timerVal < 1) {
        timerVal = 1;
    }
    [self.timerPicker selectRow:timerVal-1 inComponent:0 animated:YES];
    NSString *timerStr = [Utils timerStringForMin:timerVal];
    self.timerLbl.text = [@"Timer: " stringByAppendingString:timerStr];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UIPickerView datasource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 60;
}

#pragma maek - UIPickerView delegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [Utils timerStringForMin:row+1];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSString *timerStr = [Utils timerStringForMin:row+1];
    self.timerLbl.text = [@"Timer: " stringByAppendingString:timerStr];
}

- (IBAction)onDone:(id)sender {
    NSInteger row = [self.timerPicker selectedRowInComponent:0];
    [[PasscodeCoordinator sharedCoordinator] setPasscodeInactivityDurationInMinutes:@(row+1)];
    
    if ([self.delegate respondsToSelector:@selector(timerViewControllerDidSelect:)]) {
        [self.delegate timerViewControllerDidSelect:self];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

@end
