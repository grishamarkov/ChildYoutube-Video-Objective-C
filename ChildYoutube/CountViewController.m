//
//  CountViewController.m
//  ChildYoutube
//
//  Created by Sandro Albert on 16/07/16.
//  Copyright (c) 2016. Sandro Albert All rights reserved.
//

#import "CountViewController.h"
#import "Utils.h"

@interface CountViewController ()

@end

@implementation CountViewController

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
    
    NSUserDefaults *userStore = [NSUserDefaults standardUserDefaults];
    self.countFld.text = [NSString stringWithFormat:@"%ld", (long)[userStore integerForKey:kMaximumCount]];
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

- (IBAction)onDone:(id)sender {
    NSUserDefaults *userStore = [NSUserDefaults standardUserDefaults];
    NSInteger countNum = [self.countFld.text integerValue];
    [userStore setInteger:countNum forKey:kMaximumCount];
    [userStore synchronize];
    
    if ([self.delegate respondsToSelector:@selector(countViewControllerDidSelect:)]) {
        [self.delegate countViewControllerDidSelect:self];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onResetHistory:(id)sender {
    [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"Are you sure to reset all history?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes", nil] show];
}

#pragma mark - UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        NSUserDefaults *userStore = [NSUserDefaults standardUserDefaults];
        [userStore removeObjectForKey:kVideoHistory];
        [userStore synchronize];
    }
}

#pragma mark - UITextField delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSCharacterSet *numbersOnly = [NSCharacterSet decimalDigitCharacterSet];
    
    NSString *replacedStr = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSCharacterSet *charsetFromText = [NSCharacterSet characterSetWithCharactersInString:replacedStr];
    
    return [numbersOnly isSupersetOfSet:charsetFromText];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}

@end
