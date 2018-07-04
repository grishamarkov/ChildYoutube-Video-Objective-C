//
//  AppDelegate.m
//  ChildYoutube
//
//  Created by Sandro Albert on 16/07/16.
//  Copyright (c) 2016. Sandro Albert All rights reserved.
//

#import "AppDelegate.h"
#import <Crashlytics/Crashlytics.h>
#import "Utils.h"
#import "PasscodeCoordinator.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [Crashlytics startWithAPIKey:@"bcb52a590fe6deee5acd039af2fb270e61fa663f"];
    
    NSUserDefaults *userStore = [NSUserDefaults standardUserDefaults];
    if ([userStore objectForKey:kEnableSeekControl] == nil) {
        [userStore setObject:@(YES) forKey:kEnableSeekControl];
        [userStore synchronize];
    }
    if ([userStore objectForKey:kEnableVolumeControl] == nil) {
        [userStore setObject:@(YES) forKey:kEnableVolumeControl];
        [userStore synchronize];
    }
    
    //Activate protection
    [[PasscodeCoordinator sharedCoordinator] activatePasscodeProtection];
    
    //Set style
    [self setPasscodeStyle];
    
    return YES;
}

- (void)setPasscodeStyle
{
    UIColor *iPhone5CWhite = [UIColor colorWithRed:0.961 green:0.957 blue:0.969 alpha:1.0];
    UIColor *wpBlue = [UIColor colorWithRed:0.129 green:0.459 blue:0.608 alpha:1.0];
    UIColor *wpOrange = [UIColor colorWithRed:0.835 green:0.306 blue:0.129 alpha:1.0];
    
    PasscodeButtonStyleProvider *buttonStyleProvider = [[PasscodeButtonStyleProvider alloc] init];
    PasscodeButtonStyle *style = [[PasscodeButtonStyle alloc] init];
    style.lineColor = iPhone5CWhite;
    style.titleColor = iPhone5CWhite;
    style.fillColor = [UIColor clearColor];
    style.selectedFillColor = wpOrange;
    style.selectedLineColor = iPhone5CWhite;
    style.selectedTitleColor = iPhone5CWhite;
    style.titleFont = [UIFont fontWithName:@"Avenir-Book" size:35];
    
    [buttonStyleProvider addStyle:style forButton:PasscodeButtonTypeAll];
    
    [PasscodeCoordinator sharedCoordinator].buttonStyleProvider = buttonStyleProvider;
    [PasscodeCoordinator sharedCoordinator].instructionsLabelFont = [UIFont fontWithName:@"Avenir-Book" size:20];
    [PasscodeCoordinator sharedCoordinator].cancelOrDeleteButtonFont = [UIFont fontWithName:@"Avenir-Book" size:15];
    [PasscodeCoordinator sharedCoordinator].backgroundColor = wpBlue;
    // [PasscodeCoordinator sharedCoordinator].backgroundImage = [UIImage imageNamed:@"background.jpeg"];
    // [PasscodeCoordinator sharedCoordinator].logo = [UIImage imageNamed:@"wp_white.png"];
    [PasscodeCoordinator sharedCoordinator].instructionsLabelColor = iPhone5CWhite;
    [PasscodeCoordinator sharedCoordinator].cancelOrDeleteButtonColor = iPhone5CWhite;
    [PasscodeCoordinator sharedCoordinator].passcodeViewFillColor = wpOrange;
    [PasscodeCoordinator sharedCoordinator].passcodeViewLineColor = iPhone5CWhite;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
