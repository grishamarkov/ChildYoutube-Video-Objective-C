//
//  MainViewController.m
//  ChildYoutube
//
//  Created by Sandro Albert on 16/07/16.
//  Copyright (c) 2016. Sandro Albert All rights reserved.
//

#import "MainViewController.h"
#import "VideoCell.h"
#import <AFNetworking.h>
#import <UIImageView+AFNetworking.h>
#import <XCDYouTubeKit.h>
#import "Utils.h"
#import "PasscodeCoordinator.h"

static const NSUInteger MAX_CANDIDATE = 6;

@interface MainViewController ()

@property (weak, nonatomic) IBOutlet UIToolbar *searchToolbar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *titleItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *searchbarItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *searchItem;

@property (strong, nonatomic) NSMutableArray *videoAry;
@property (strong, nonatomic) MBProgressHUD *HUD;
@property (nonatomic) NSUInteger currIdx;
@property (strong, nonatomic) NSString *currKeyword;
@property (nonatomic) BOOL isLoading;
@property (strong, nonatomic) UIToolbar *exitToolbar;
@property (strong, nonatomic) XCDYouTubeVideoPlayerViewController *currPlayer;
@property (nonatomic) BOOL isToolbarShowed;
@property (nonatomic) CFAbsoluteTime lastControlTime;
@property (strong, nonatomic) NSTimer *autohideTimer;
@property (strong, nonatomic) NSTimer *lockTimer;
@property (strong, nonatomic) UIButton *fullCoverBtn;
@property (strong, nonatomic) NSMutableArray *candidateAry;

@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.candidateAry = [NSMutableArray array];
    
    // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoPlayerViewControllerDidReceiveVideo:) name:XCDYouTubeVideoPlayerViewControllerDidReceiveVideoNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(passcodeLocked:) name:PasscodeLockedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(passcodeDismissed:) name:PasscodeDismissedNotification object:nil];
    
    CGRect rctFrame = [[UIScreen mainScreen] bounds];
    self.fullCoverBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    // [self.fullCoverBtn setBackgroundImage:image forState:UIControlStateNormal];
    self.fullCoverBtn.backgroundColor = [UIColor whiteColor];
    [self.fullCoverBtn addTarget:self action:@selector(onTouchFull:) forControlEvents:UIControlEventTouchUpInside];
    self.fullCoverBtn.transform = CGAffineTransformRotate(CGAffineTransformIdentity, -M_PI_2);
    self.fullCoverBtn.frame = rctFrame;

    if ([[PasscodeCoordinator sharedCoordinator] isPasscodeProtectionOn]) {
        self.lockTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(checkLockStatus) userInfo:nil repeats:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:TrackingInactivityStartedNotification object:nil];
    }
    
    [self onTitleItem:nil];
    
    self.HUD = [[MBProgressHUD alloc] initWithView:self.view];
    self.HUD.delegate = self;
    
    self.currKeyword = @"Cartoon";
    self.titleItem.title = self.currKeyword;
    [self searchByKeyword];
    
    self.searchDisplayController.searchResultsTableView.scrollEnabled = NO;
    self.searchDisplayController.searchBar.showsSearchResultsButton = NO;
}

- (void)configureTableView:(UITableView *)tableView {
    
    tableView.separatorInset = UIEdgeInsetsZero;
    
    UIView *tableFooterViewToGetRidOfBlankRows = [[UIView alloc] initWithFrame:CGRectZero];
    tableFooterViewToGetRidOfBlankRows.backgroundColor = [UIColor clearColor];
    tableView.tableFooterView = tableFooterViewToGetRidOfBlankRows;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self configForOrientation:[UIApplication sharedApplication].statusBarOrientation];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [UIView animateWithDuration:duration animations:^{
        [self configForOrientation:toInterfaceOrientation];
    }];
}

- (void)passcodeLocked:(NSNotification *)notification
{
    if (self.currPlayer) {
        [self.currPlayer.moviePlayer pause];
    }
    
    if ([self.lockTimer isValid]) {
        [self.lockTimer invalidate];
        self.lockTimer = nil;
    }
    
    [self presentImage:[UIImage imageNamed:@"alarm_clock_char"] overWindow:notification.object animation:YES dismissAfter:10.0];
}

- (void)passcodeDismissed:(NSNotification *)notification
{
    if (!self.lockTimer) {
        self.lockTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(checkLockStatus) userInfo:nil repeats:YES];
    }
}

/*
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // viewWillAppear/viewDidAppear is called when exiting fullscreen on iOS 6+.
    if (self.currPlayer && !self.currPlayer.moviePlayer.fullscreen) {
        [self installMovieNotificationObserversForPlayer:self.currPlayer.moviePlayer];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // viewWillDisappear/viewDidDisappear is called when entering fullscreen on iOS 6+.
    if (self.currPlayer && !self.currPlayer.moviePlayer.fullscreen) {
        [self removeMovieNotificationHandlers];
    }
}
*/
#define FLEX_SPACE ([[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil])

- (IBAction)onTitleItem:(id)sender {
    [self.searchToolbar setItems:@[FLEX_SPACE, self.titleItem, FLEX_SPACE, self.searchItem] animated:YES];
}

- (IBAction)onSearchItem:(id)sender {
    [self.searchToolbar setItems:@[FLEX_SPACE, self.titleItem, FLEX_SPACE, self.searchbarItem] animated:YES];
    self.searchDisplayController.searchBar.text = self.currKeyword;
    [self.searchDisplayController.searchBar becomeFirstResponder];
    self.searchDisplayController.searchResultsTableView.contentOffset = CGPointZero;
}

#pragma mark - Exit Toobar

- (void)addToolbarForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Get the screen dimensions based on the orientation
    /*CGRect screenRect = [UIScreen mainScreen].bounds;
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        CGRect temp = CGRectZero;
        temp.size.width = screenRect.size.height;
        temp.size.height = screenRect.size.width;
        screenRect = temp;
    }
    
    CGFloat screenWidth = CGRectGetWidth(screenRect);
    CGFloat screenHeight = CGRectGetHeight(screenRect);*/
    
	// Create a sample overlay view centered the fullscreen view
    if (!self.exitToolbar) {
        self.exitToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 1024, 44)];
        self.exitToolbar.barStyle = UIBarStyleBlackTranslucent;
        self.exitToolbar.items = @[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onDoneVideo:)]];
    }
	
	// Rotation and position the view based on the orientation
    // If your overlay isn't centered you'll need to adjust the CGAffineTransformTranslate
    // transform for PortraitUpsideDown, LandscapeLeft and LandscapeRight orientations.
	CGAffineTransform transform = CGAffineTransformIdentity;
    
	switch (interfaceOrientation) {
		case UIInterfaceOrientationPortrait:
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			transform = CGAffineTransformRotate(transform, M_PI);
			break;
		case UIInterfaceOrientationLandscapeLeft:
			transform = CGAffineTransformRotate(transform, -M_PI_2);
			transform = CGAffineTransformTranslate(transform, -490, -490);
			break;
		case UIInterfaceOrientationLandscapeRight:
			transform = CGAffineTransformRotate(transform, M_PI_2);
			transform = CGAffineTransformTranslate(transform, 490, -234);
			break;
		default:
			break;
	}
	
    self.exitToolbar.transform = transform;
    
	[self.appWindow addSubview:self.exitToolbar];
    NSLog(@"%@", NSStringFromCGRect(self.exitToolbar.frame));
}

- (void)configForOrientation:(UIInterfaceOrientation)orientation
{
    switch (orientation) {
        case UIInterfaceOrientationLandscapeLeft:
            self.fullCoverBtn.transform = CGAffineTransformRotate(CGAffineTransformIdentity, -M_PI_2);
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            self.fullCoverBtn.transform = CGAffineTransformRotate(CGAffineTransformIdentity, M_PI_2);
            break;
            
        default:
            break;
    }
}

- (void)searchByKeyword
{
    [self.view addSubview:self.HUD];
    self.HUD.labelText = @"Loading...";
    [self.HUD show:YES];
    
    self.currIdx = 0;
    self.videoAry = [NSMutableArray array];
    [self.videoCollect reloadData];
    
    [self loadCurrBlock];
}

- (void)loadCurrBlock
{
    self.isLoading = YES;
    
    NSString *searchCall = @"http://gdata.youtube.com/feeds/api/videos";
    NSDictionary *params = @{@"q": self.currKeyword, @"start-index": [NSString stringWithFormat:@"%lu", (unsigned long)self.currIdx+1], @"max-results": @"30", @"alt": @"json", @"v": @"2"};
    
    AFHTTPRequestOperationManager *opManager = [AFHTTPRequestOperationManager manager];
    [opManager GET:searchCall parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // NSLog(@"JSON: %@", responseObject);
        NSArray *entries = [responseObject valueForKeyPath:@"feed.entry"];
        NSUInteger startIdx = self.currIdx;
        for (int i = 0; i < [entries count]; i++) {
            NSDictionary *videoItem = entries[i];
            NSString *videoId = [videoItem valueForKeyPath:@"media$group.yt$videoid.$t"];
            [self.videoAry addObject:videoId];
            
            // [[XCDYouTubeVideoPlayerViewController alloc] initWithVideoIdentifier:videoId];
            [[XCDYouTubeClient defaultClient] getVideoWithIdentifier:videoId completionHandler:^(XCDYouTubeVideo *video, NSError *error) {
                if (video) {
                    [self.videoAry replaceObjectAtIndex:startIdx+i withObject:video];
                    [self.videoCollect reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:startIdx+i inSection:0]]];
                } else {
                    NSLog(@"video load fail: %@", error);
                }
            }];
        }
        self.currIdx += [entries count];
        [self.videoCollect reloadData];
        [self.HUD hide:YES];
        
        self.isLoading = NO;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        [self.HUD hide:YES];
        
        self.isLoading = NO;
    }];
}

/*
#pragma mark - Notifications

- (void)videoPlayerViewControllerDidReceiveVideo:(NSNotification *)notification
{
	XCDYouTubeVideo *video = notification.userInfo[XCDYouTubeVideoUserInfoKey];
    NSUInteger videoIndex = [self.videoAry indexOfObject:video.identifier];
    if (videoIndex != NSNotFound) {
        [self.videoAry replaceObjectAtIndex:videoIndex withObject:video];
        [self.videoCollect reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:videoIndex inSection:0]]];
    }
}
*/
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setting View Controller

- (void)settingViewControllerDidFinish:(SettingViewController *)controller
{
    [self.settingPopoverController dismissPopoverAnimated:YES];
    self.settingPopoverController = nil;
}

- (void)settingViewControllerPasscodeEnabled:(SettingViewController *)controller
{
    [[NSNotificationCenter defaultCenter] postNotificationName:TrackingInactivityStartedNotification object:nil];
    [self.lockTimer invalidate];
    self.lockTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(checkLockStatus) userInfo:nil repeats:YES];
}

- (void)checkLockStatus
{
    [[NSNotificationCenter defaultCenter] postNotificationName:TrackingInactivityEndedNotification object:nil];
}

- (void)settingViewControllerPasscodeDisabled:(SettingViewController *)controller
{
    [self.lockTimer invalidate];
    self.lockTimer = nil;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.settingPopoverController = nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showAlternate"]) {
        id destCtlr = [[segue destinationViewController] viewControllers][0];
        [destCtlr setDelegate:self];
        UIPopoverController *popoverController = [(UIStoryboardPopoverSegue *)segue popoverController];
        self.settingPopoverController = popoverController;
        popoverController.delegate = self;
    }
}

- (IBAction)togglePopover:(id)sender
{
    if (self.settingPopoverController) {
        [self.settingPopoverController dismissPopoverAnimated:YES];
        self.settingPopoverController = nil;
    } else {
        [self performSegueWithIdentifier:@"showAlternate" sender:sender];
    }
}

#pragma mark - MBProgressHUD Delegate

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    [self.HUD removeFromSuperview];
}

#pragma mark - UICollectionView datasource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.videoAry count] + 1;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    VideoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"VideoCell" forIndexPath:indexPath];
    cell.titleLbl.text = @"";
    cell.thumbImg.image = nil;
    
    if (indexPath.item < [self.videoAry count]) {
        XCDYouTubeVideo *videoItem = self.videoAry[indexPath.item];
        if ([videoItem isKindOfClass:[XCDYouTubeVideo class]]) {
            cell.titleLbl.text = videoItem.title;
            NSURL *thumbnailURL = videoItem.mediumThumbnailURL ?: videoItem.smallThumbnailURL;
            [cell.thumbImg setImageWithURL:thumbnailURL];
        }
    } else {
        [self fetchMoreItems];
    }
    
    return cell;
}

- (void)fetchMoreItems
{
    if (self.isLoading) {
        return;
    }
    
    [self.view addSubview:self.HUD];
    self.HUD.labelText = @"Loading more...";
    [self.HUD show:YES];
    
    [self loadCurrBlock];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *videoId = @"";
    id videoItem = self.videoAry[indexPath.item];
    if ([videoItem isKindOfClass:[XCDYouTubeVideo class]]) {
        videoId = ((XCDYouTubeVideo *)videoItem).identifier;
    } else if ([videoItem isKindOfClass:[NSString class]]) {
        videoId = videoItem;
    }
    
    if ([videoId length] > 0) {
        NSUserDefaults *userStore = [NSUserDefaults standardUserDefaults];
        NSInteger maximumCount = [userStore integerForKey:kMaximumCount];
        NSMutableDictionary *videoHistory = [[userStore dictionaryForKey:kVideoHistory] mutableCopy];
        if (!videoHistory) {
            videoHistory = [NSMutableDictionary dictionary];
        }
        NSInteger countForVideo = [videoHistory[videoId] integerValue];
        if (maximumCount > 0 && countForVideo >= maximumCount) {
            [self presentImage:[UIImage imageNamed:@"Stop_sign"] overWindow:nil animation:NO dismissAfter:0.0];
            return;
        }
        
        [videoHistory setObject:@(++countForVideo) forKey:videoId];
        [userStore setObject:videoHistory forKey:kVideoHistory];
        [userStore synchronize];
        
        self.currPlayer = [[XCDYouTubeVideoPlayerViewController alloc] initWithVideoIdentifier:videoId];
        // videoPlayer.preferredVideoQualities = @[@(XCDYouTubeVideoQualityMedium360), @(XCDYouTubeVideoQualitySmall240)];
        [self presentMoviePlayerViewControllerAnimated:self.currPlayer];
        
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:kEnableSeekControl] boolValue]) {
            self.currPlayer.moviePlayer.controlStyle = MPMovieControlStyleFullscreen;
        } else {
            self.currPlayer.moviePlayer.controlStyle = MPMovieControlStyleNone;
            [self startCustomToolbar];
            [self installMovieNotificationObserversForPlayer:self.currPlayer.moviePlayer];
            self.exitToolbar.alpha = 1.f;
            [[self appWindow] addSubview:self.exitToolbar];
            
            self.lastControlTime = CFAbsoluteTimeGetCurrent();
            self.isToolbarShowed = YES;
            self.autohideTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(autoHidePlayerControl) userInfo:nil repeats:YES];
        }
    }
}

#pragma - full cover

- (UIWindow *)appWindow
{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (!window) {
        window = [[UIApplication sharedApplication] windows][0];
    }
    
    return window;
}

- (void)startCustomToolbar
{
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutToolbarForOrientation:) name:UIDeviceOrientationDidChangeNotification object:nil];
	
    // This needs to be called in the next run loop for it to work properly in iOS 6+
    [self performSelector:@selector(addToolbarForCurrentInterfaceOrientation) withObject:nil afterDelay:0];
}

- (void)hidePlayerControl
{
    if (self.isToolbarShowed) {
        self.exitToolbar.alpha = 0.f;
        
        self.isToolbarShowed = NO;
    }
}

- (void)autoHidePlayerControl
{
    CFTimeInterval duration = CFAbsoluteTimeGetCurrent() - self.lastControlTime;
    if (self.isToolbarShowed && duration > 5) {
        [UIView animateWithDuration:0.5 animations:^{
            [self hidePlayerControl];
            self.isToolbarShowed = NO;
        }];
    }
}

-(void)showPlayerControl
{
    self.exitToolbar.alpha = 1.f;
    
    self.isToolbarShowed = YES;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.exitToolbar.superview) {
        NSLog(@"touch on player");
        if(self.isToolbarShowed){
            [UIView animateWithDuration:0.5 animations:^{
                [self hidePlayerControl];
            }];
        }
        else{
            self.lastControlTime = CFAbsoluteTimeGetCurrent();
            [UIView animateWithDuration:0.5 animations:^{
                [self showPlayerControl];
            }];
        }
    }
}

- (void)addToolbarForCurrentInterfaceOrientation
{
    [self addToolbarForInterfaceOrientation:self.interfaceOrientation];
}

#pragma mark - UIDeviceOrientationDidChangeNotification Handler

- (void)layoutToolbarForOrientation:(UIDeviceOrientation)orientation
{
    // This needs to be called in the next run loop for it to work properly in iOS 6+
    [self performSelector:@selector(layoutToolbar) withObject:nil afterDelay:0];
}

- (void)layoutToolbar
{
    UIInterfaceOrientation statusBarOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    [self addToolbarForInterfaceOrientation:statusBarOrientation];
}

- (void)onDoneVideo:(id)sender
{
    [self dismissMoviePlayerViewControllerAnimated];
}

- (void)installMovieNotificationObserversForPlayer:(MPMoviePlayerController *)player
{
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:player];
}

#pragma mark - Movie Notification Handlers

- (void)moviePlayBackDidFinish:(NSNotification *)notification
{
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    
    [self.autohideTimer invalidate];
    
	// Remove the fullscreen overlay view
	if (self.exitToolbar) {
		[self.exitToolbar removeFromSuperview];
	}
}

#pragma mark - Remove Movie Player

- (void)removeMovieNotificationHandlers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PasscodeLockedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PasscodeDismissedNotification object:nil];
}

- (IBAction)onInfo:(id)sender {
    [self presentImage:[UIImage imageNamed:@"help_page"] overWindow:nil animation:NO dismissAfter:0.0];
}

- (void)presentImage:(UIImage *)image overWindow:(UIWindow *)overWindow animation:(BOOL)animation dismissAfter:(NSTimeInterval)after
{
    [self.fullCoverBtn setBackgroundImage:image forState:UIControlStateNormal];
    
    if (!overWindow) {
        overWindow = [UIApplication sharedApplication].keyWindow;
    }
    [overWindow addSubview:self.fullCoverBtn];
    
    if (animation) {
        [self earthquake:self.fullCoverBtn];
    }
    
    if (after > 0.0) {
        self.fullCoverBtn.userInteractionEnabled = NO;
        [self performSelector:@selector(onTouchFull:) withObject:self.fullCoverBtn afterDelay:after];
    } else {
        self.fullCoverBtn.userInteractionEnabled = YES;
    }
}

- (void)onTouchFull:(id)sender
{
    [sender removeFromSuperview];
}

- (void)earthquake:(UIView*)lockView
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    [animation setDuration:0.03];
    [animation setRepeatCount:12];
    [animation setAutoreverses:YES];
    [animation setFromValue:[NSValue valueWithCGPoint:CGPointMake([lockView center].x, [lockView center].y - 20.f)]];
    [animation setToValue:[NSValue valueWithCGPoint:CGPointMake([lockView center].x, [lockView center].y + 20.f)]];
    [[lockView layer] addAnimation:animation forKey:@"position"];
}

#pragma mark - UISearchBar delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    self.currKeyword = searchBar.text;
    self.titleItem.title = self.currKeyword;
    NSLog(@"search: %@", self.currKeyword);
    if ([self.currKeyword length] > 0) {
        [self searchByKeyword];
        [self.searchDisplayController setActive:NO animated:YES];
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [self onTitleItem:nil];
}

#pragma mark - UISearchDisplayDelegate

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    NSLog(@"🔦 | will begin search");
    // [controller setActive:YES animated:YES];
}
- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller {
    NSLog(@"🔦 | did begin search");
}
- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
    NSLog(@"🔦 | will end search");
}
- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
    NSLog(@"🔦 | did end search");
    // controller.searchBar.text = self.currKeyword;
}
- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView {
    NSLog(@"🔦 | did load table");
    [self configureTableView:tableView];
}
- (void)searchDisplayController:(UISearchDisplayController *)controller willUnloadSearchResultsTableView:(UITableView *)tableView {
    NSLog(@"🔦 | will unload table");
}
- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView {
    NSLog(@"🔦 | will show table");
    // controller.searchBar.text = self.suggestionKeyword;
}
- (void)searchDisplayController:(UISearchDisplayController *)controller didShowSearchResultsTableView:(UITableView *)tableView {
    NSLog(@"🔦 | did show table");
    
    // tableView.contentOffset = CGPointZero;
}
- (void)searchDisplayController:(UISearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView {
    NSLog(@"🔦 | will hide table");
}
- (void)searchDisplayController:(UISearchDisplayController *)controller didHideSearchResultsTableView:(UITableView *)tableView {
    NSLog(@"🔦 | did hide table");
}
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    NSLog(@"🔦 | should reload table for search string: %@", searchString);
    
    // self.candidateAry = [NSMutableArray array];
    controller.searchResultsTableView.contentOffset = CGPointZero;
    [self getCandidate:searchString];
    
    return YES;
}

- (void)getCandidate:(NSString *)query
{
    @autoreleasepool {
        NSString *urlStr = [NSString stringWithFormat:@"http://suggestqueries.google.com/complete/search?client=youtube&ds=yt&q=%@", query];
        NSString *candidates = [NSString stringWithContentsOfURL:[NSURL URLWithString:urlStr] encoding:NSUTF8StringEncoding error:nil];
        if ([candidates hasPrefix:@"window.google.ac.h"] && [candidates hasSuffix:@")"]) {
            candidates = [candidates substringFromIndex:[@"window.google.ac.h" length]];
            candidates = [candidates stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"()"]];
            
            NSError *error = nil;
            NSArray *result = [NSJSONSerialization JSONObjectWithData:[candidates dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
            if (error) {
                NSLog(@"Error: %@", error);
            } else {
                NSArray *candidateList = result[1];
                self.candidateAry = [NSMutableArray array];
                for (int i = 0; i < [candidateList count]; i++) {
                    NSArray *candidateItem = candidateList[i];
                    [self.candidateAry addObject:candidateItem[0]];
                    if ([self.candidateAry count] >= MAX_CANDIDATE) {
                        break;
                    }
                }
            }
            [self.searchDisplayController.searchResultsTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
        }
    }
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    NSLog(@"🔦 | should reload table for search scope?");
    return YES;
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.candidateAry count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"searchCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    if ([self.candidateAry count] > indexPath.row) {
        cell.textLabel.text = self.candidateAry[indexPath.row];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ([self.candidateAry count] > indexPath.row) {
        self.currKeyword = self.candidateAry[indexPath.row];
        self.titleItem.title = self.currKeyword;
        [self searchByKeyword];
    }
    [self.searchDisplayController setActive:NO animated:YES];
}

@end
