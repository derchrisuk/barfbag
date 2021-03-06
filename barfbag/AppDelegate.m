//
//  AppDelegate.m
//  barfbag
//
//  Created by Lincoln Six Echo on 02.12.12.
//  Copyright (c) 2012 appdoctors. All rights reserved.
//

#import "AppDelegate.h"

#import "MasterConfig.h"
#import "FavouriteManager.h"

#import "ATMHud.h"
#import "ATMHudQueueItem.h"
#import "SinaURLConnection.h"

#import "GenericTabBarController.h"

#import "ScheduleNavigationController.h"
#import "ScheduleSemanticNavigationController.h"
#import "FavouritesNavigationController.h"
#import "VideoStreamNavigationController.h"
#import "ConfigurationNavigationController.h"

#import "WelcomeViewController.h"

// PENTABARF SCHEDULE OBJECTS
#import "Conference.h"
#import "Day.h"
#import "Event.h"
#import "Link.h"
#import "Person.h"

// SEMANTIC WIKI OBJECTS & CONNECTION HANDLING
#import "NSObject+SBJson.h"
#import "Workshops.h"
#import "Assemblies.h"

// ICLOUD SUPPORT
#import "MKiCloudSync.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize tabBarController  = _tabBarController;
@synthesize themeColor = _themeColor;
@synthesize scheduledConferences;
@synthesize semanticWikiAssemblies;
@synthesize semanticWikiWorkshops;
@synthesize videoStreamsHtml;
@synthesize masterConfiguration;
@synthesize hud;
@synthesize flashyView;

- (void)dealloc {
    [_window release];
    [_tabBarController release];
    [_themeColor release];
    self.scheduledConferences = nil;
    self.semanticWikiAssemblies = nil;
    self.semanticWikiWorkshops = nil;
    self.videoStreamsHtml = nil;
    self.masterConfiguration = nil;
    self.hud = nil;
    self.flashyView = nil;
    [super dealloc];
}

#pragma mark - Convenience & Helper Methods

- (UIFont*) fontWithType:(CustomFontType)fontType andPointSize:(CGFloat)pointSize {
    switch( fontType ) {
        case CustomFontTypeExtralight:
            return [UIFont fontWithName:@"SourceCodePro-ExtraLight" size:pointSize];
            break;

        case CustomFontTypeLight:
            return [UIFont fontWithName:@"SourceCodePro-Light" size:pointSize];
            break;

        case CustomFontTypeRegular:
            return [UIFont fontWithName:@"Source Code Pro" size:pointSize];
            break;

        case CustomFontTypeSemibold:
            return [UIFont fontWithName:@"SourceCodePro-Semibold" size:pointSize];
            break;

        case CustomFontTypeBold:
            return [UIFont fontWithName:@"SourceCodePro-Bold" size:pointSize];
            break;

        case CustomFontTypeBlack:
            return [UIFont fontWithName:@"SourceCodePro-Black" size:pointSize];
            break;

        default:
            break;
    }
    return nil;
}

- (CGFloat) randomFloatBetweenLow:(CGFloat)lowValue andHigh:(CGFloat)highValue {
    return (((CGFloat)arc4random()/0x100000000)*(highValue-lowValue)+lowValue);
}

- (UIColor*) randomColor {
#if SCREENSHOTMODE
    return kCOLOR_ORANGE;
#endif
    NSInteger indexLastDisplayed = 10;
    if( [[NSUserDefaults standardUserDefaults] objectForKey:kUSERDEFAULT_KEY_INTEGER_COLOR_INDEX] ) {
        indexLastDisplayed = [[NSUserDefaults standardUserDefaults] integerForKey:kUSERDEFAULT_KEY_INTEGER_COLOR_INDEX];
    }
    NSInteger colorIndex = 0;
    NSArray *colors = [NSArray arrayWithObjects:kCOLOR_VIOLET,kCOLOR_GREEN,kCOLOR_RED,kCOLOR_CYAN,kCOLOR_ORANGE,nil];
    while( colorIndex == indexLastDisplayed ) {
        colorIndex = [[NSNumber numberWithFloat:(0.4+[self randomFloatBetweenLow:0.0 andHigh:4.0])] integerValue];
    }
    [[NSUserDefaults standardUserDefaults] setInteger:colorIndex forKey:kUSERDEFAULT_KEY_INTEGER_COLOR_INDEX];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return [colors objectAtIndex:colorIndex];
}

- (void) addUserAgentInfoToRequest:(NSMutableURLRequest*)request {
	NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
	NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
	NSString *appPlatform = [[UIDevice currentDevice] platformString];
	NSString *appSystemVersion = [[UIDevice currentDevice] systemVersion];
	NSString *appLanguageContext = [[NSLocale currentLocale] localeIdentifier];
	
	NSString *uaString = [NSString stringWithFormat:@"%@/%@ (%@; iOS %@; %@)", appName, appVersion, appPlatform, appSystemVersion, appLanguageContext];
	if( DEBUG ) NSLog( @"CONNECTION: USER AGENT = %@", uaString );
	[request setValue:uaString forHTTPHeaderField:@"User-Agent"];
	
}

- (void) emptyAllFilesFromFolder:(NSString*)folderPath {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *listOfFiles = nil;
    @try {
        listOfFiles = [fm contentsOfDirectoryAtPath:folderPath error:&error];
        if( listOfFiles && [listOfFiles count] > 0 ) {
            if( DEBUG ) NSLog( @"CLEANUP: CLEANING DIRECTORY... %@ (%i ITEMS)", folderPath, [listOfFiles count] );
            for( NSString* currentFilePath in listOfFiles ) {
                if( [fm fileExistsAtPath:currentFilePath] ) {
                    error = nil;
                    if( DEBUG ) NSLog( @"CLEANUP: DELETING... %@", currentFilePath );
                    BOOL successDelete = [fm removeItemAtPath:currentFilePath error:&error];
                    if( !successDelete || error ) {
                        if( DEBUG ) NSLog( @"CLEANUP: ERROR DELETING... %@", currentFilePath );
                    }
                }
            }
        }
    }
    @catch (NSException *exception) {
        if( DEBUG ) NSLog( @"CLEANUP: ERROR CLEANING DIRECTORY... %@", folderPath );
    }
    
}

- (Conference*) conference {
    return (Conference*)[scheduledConferences lastObject];
}

- (void) alertWithTag:(NSInteger)tag title:(NSString*)title andMessage:(NSString*)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:LOC( @"OK" ), nil];
    alert.tag = tag;
    [alert show];
    [alert release];
}

- (UIColor*) backgroundColor {
    return kCOLOR_BACK;
}

- (UIColor*) brightColor {
    CGFloat hue = [[self themeColor] hue];
    return [UIColor colorWithHue:hue saturation:0.025f brightness:1.0 alpha:1.0];
}

- (UIColor*) brighterColor {
    CGFloat hue = [[self themeColor] hue];
    CGFloat brightness = [[self themeColor] brightness];
    return [UIColor colorWithHue:hue saturation:hue*0.3f brightness:brightness*1.15 alpha:1.0];
}

- (UIColor*) darkerColor {
    CGFloat hue = [[self themeColor] hue];
    CGFloat brightness = [[self themeColor] brightness];
    CGFloat saturation = [[self themeColor] saturation];
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness*0.8 alpha:1.0];
}

- (UIColor*) darkColor {
    CGFloat hue = [[self themeColor] hue];
    CGFloat brightness = [[self themeColor] brightness];
    CGFloat saturation = [[self themeColor] saturation];
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness*0.4f alpha:1.0];
}

- (UIColor*) backBrightColor {
    CGFloat hue = [kCOLOR_BACK hue];
    CGFloat brightness = [kCOLOR_BACK brightness];
    CGFloat saturation = [kCOLOR_BACK saturation];
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness*1.55 alpha:1.0];
}

- (BOOL) isConfigOnForKey:(NSString*)key defaultValue:(BOOL)isOn {
    if( ![[NSUserDefaults standardUserDefaults] objectForKey:key] ) {
        return isOn;
    }
    return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}

- (void) signalCloudSyncToUser {
    [self showHudWithCaption:@"Syncing iCloud" hasActivity:YES];
    [[FavouriteManager sharedManager] rebuildFavouriteCache];
    [self showHudWithCaption:@"iCloud was synced." hasActivity:NO];
    
    BOOL shouldUseErrorProneAnimation = NO;
        if( shouldUseErrorProneAnimation ) {
        CGFloat sizeValue = MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        if( flashyView ) {
            return;
        }
        self.flashyView = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, sizeValue, sizeValue )] autorelease];
        flashyView.backgroundColor = kCOLOR_WHITE;
        flashyView.alpha = 0.0f;
        [_window.rootViewController.view addSubview:flashyView];
        [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            flashyView.alpha = 1.0;
        } completion:^(BOOL finished) {
            if( finished ) {
                [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    flashyView.backgroundColor = [self themeColor];
                } completion:^(BOOL finished) {
                    if( finished ) {
                        
                        [UIView animateWithDuration:0.8 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                            flashyView.alpha = 0.0;
                        } completion:^(BOOL finished) {
                            if( finished ) {
                                [flashyView removeFromSuperview];
                                self.flashyView = nil;
                                [self showHudWithCaption:@"iCloud was synced." hasActivity:NO];
                            }
                        }];
                        
                    }
                }];
            
            }
        }];
    }
}

- (void) configureAppearance {
    if( ![[UINavigationBar class] respondsToSelector:@selector(appearance)] ) return;

    // TOOLBARS I.E. MAIL TOOLBAR
    UINavigationBar *proxyNavigationBar = [UINavigationBar appearance];
    [proxyNavigationBar setTintColor:kCOLOR_BACK];

    /*
     // REVEALS FUCKED UP RESULTS OF TITLE TEXT
    NSMutableDictionary *attribs = [NSMutableDictionary dictionary];
    [attribs setObject:[self fontWithType:CustomFontTypeBold andPointSize:0.0] forKey:UITextAttributeFont];
    proxyNavigationBar.titleTextAttributes = attribs;
     */
    // MPAVController
    // MPAVController *proxyMpavController = [MPAVController appearance];

    // SLIDER
    BOOL useCustomSlider = YES;
    if( useCustomSlider ) {
        UISlider *proxySlider = [UISlider appearance];
        [proxySlider setMinimumTrackTintColor:[self darkColor]];
        [proxySlider setMaximumTrackTintColor:[self themeColor]];
    }
    
    // SWITCH
    UISwitch *proxySwitch = [UISwitch appearance];
    proxySwitch.onTintColor = [self darkerColor];
    
    // TABBAR
    UITabBar *proxyTabBar = [UITabBar appearance];
    proxyTabBar.tintColor = kCOLOR_BACK;
    proxyTabBar.selectedImageTintColor = [self themeColor];
    
    // SEARCHBAR
    UISearchBar *proxySearchBar = [UISearchBar appearance];
    proxySearchBar.tintColor = kCOLOR_BACK;

    // TOOLBARS I.E. MAIL TOOLBAR
    UINavigationBar *proxyNavigationBarMail = [UINavigationBar appearanceWhenContainedIn:[MFMailComposeViewController class], nil];
    [proxyNavigationBarMail setTintColor:kCOLOR_BACK];
    
    UIToolbar *proxyToolbarBarMail = [UIToolbar appearanceWhenContainedIn:[MFMailComposeViewController class], nil];
    [proxyToolbarBarMail setTintColor:kCOLOR_BACK];
}

#pragma mark - Fetch Master Configuration

- (void) configFetchContentWithUrlString:(NSString*)urlString {
    if( DEBUG ) NSLog( @"MASTERCONFIG: PLIST FETCHING FROM %@", urlString );
    [[NSNotificationCenter defaultCenter] postNotificationName:kNOTIFICATION_MASTER_CONFIG_STARTED object:self];
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                                              cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                          timeoutInterval:kCONNECTION_TIMEOUT];
    
    [self addUserAgentInfoToRequest:theRequest];
    
    BOOL shouldCheckModifiedDate = NO;
    if( shouldCheckModifiedDate ) {
        NSString *modifiedDateString = nil;
        CGFloat secondsForTwoMonths = 60*24*60*60;
        NSDate *lastModifiedDate = [NSDate dateWithTimeIntervalSinceNow:-secondsForTwoMonths];
        @try {
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            df.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'";
            df.locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
            df.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
            modifiedDateString = [df stringFromDate:lastModifiedDate];
            [df release];
        }
        @catch (NSException * e) {
            // do nothing
        }
        NSLog( @"FETCHING STUFF SINCE DATE: %@", lastModifiedDate );
        [theRequest addValue:modifiedDateString forHTTPHeaderField:@"If-Modified-Since"];
    }
    
    // KICK OFF CONNECTION AS BLOCK
    [SinaURLConnection asyncConnectionWithRequest:theRequest completionBlock:^(NSData *data, NSURLResponse *response) {
        NSInteger statusCode = ((NSHTTPURLResponse*)response).statusCode;
        if( DEBUG ) NSLog( @"MASTERCONFIG: PLIST CONNECTION RESPONSECODE: %i", statusCode );
        // REPLACE STORED OFFLINE DATA
        if( statusCode != 200 ) {
            [self alertWithTag:0 title:LOC( @"Master Configuration" ) andMessage:LOC( @"Derzeit liegen keine\nKonfigurationsdaten vor\num zu Aktualisieren.\n\nProbieren sie es später\nnoch einmal bitte!" )];
        }
        else {
            BOOL isCached = NO;
            if( data && [data length] > 500 ) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kNOTIFICATION_MASTER_CONFIG_SUCCEEDED object:self];
                isCached = NO;
                // SAVE INFOS
                NSString *pathToStoreFile = [kFOLDER_DOCUMENTS stringByAppendingPathComponent:kFILE_CACHED_MASTER_CONFIG];
                BOOL hasStoredFile = [data writeToFile:pathToStoreFile atomically:YES];
                if( !hasStoredFile ) {
                    if( DEBUG ) NSLog( @"MASTERCONFIG: PLIST SAVING FAILED!!!" );
                }
                else {
                    if( DEBUG ) NSLog( @"MASTERCONFIG: PLIST SAVING SUCCEEDED." );
                }
                [self configFillCached:isCached];
            }
            else {
                isCached = YES;
                [self configFillCached:isCached];
            }
        }
        [self hideHud];
    } errorBlock:^(NSError *error) {
        if( DEBUG ) NSLog( @"MASTERCONFIG: NO INTERNET CONNECTION." );
        [[NSNotificationCenter defaultCenter] postNotificationName:kNOTIFICATION_MASTER_CONFIG_FAILED object:self];
        [self alertWithTag:0 title:LOC( @"Verbindungsproblem" ) andMessage:LOC( @"Derzeit besteht scheinbar\nkeine Internetverbindung zum\nAktualisieren der Daten." )];
        // TODO: DISPLAY SOME ERROR...
        BOOL isCached = YES;
        [self configFillCached:isCached];
        [self hideHud];
    } uploadProgressBlock:^(float progress) {
        // do nothing
    } downloadProgressBlock:^(float progress) {
        // TODO: UPDATE PROGRESS DISPLAY ...
    } cancelBlock:^(float progress) {
        // do nothing
        [self hideHud];
    }];
}

-(void) configFillCached:(BOOL)isCachedContent {
    NSString *pathToStoredFile = [kFOLDER_DOCUMENTS stringByAppendingPathComponent:kFILE_CACHED_MASTER_CONFIG];
    @try {
        self.masterConfiguration = [NSDictionary dictionaryWithContentsOfFile:pathToStoredFile];
        if( !isCachedContent ) {
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kUSERDEFAULT_KEY_DATE_LAST_UPDATED];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    @catch (NSException *exception) {
        // Not interested, sorry!
    }
    [[MasterConfig sharedConfiguration] initialize];
    if( !isCachedContent ) {
        [self masterConfigFetchCompleted];
    }
}

- (void) configLoadCached {
    NSString *pathToCachedFile = [kFOLDER_DOCUMENTS stringByAppendingPathComponent:kFILE_CACHED_MASTER_CONFIG];
    NSFileManager *fm = [NSFileManager defaultManager];
    if( [fm fileExistsAtPath:pathToCachedFile] ) {
        if( DEBUG ) NSLog( @"MASTERCONFIG: PLIST LOADING CACHED..." );
        [self configFillCached:YES];
    }
    else {
        // TRY TO UPDATE DATA IMMEDIATELY
        [[MasterConfig sharedConfiguration] refreshFromMothership];
    }
}

#pragma mark - Master Config Delegate

- (void) masterConfigFetchRemoteConfig:(MasterConfig*)config fromUrl:(NSString*)urlString {
    [self showHudWithCaption:LOC( @"Aktualisiere Master Configuration" ) hasActivity:YES];
    [self configFetchContentWithUrlString:urlString];    
}

- (void) masterConfigFetchCompleted {
    // WILL REFRESH ALL DATA AFTER MASTER CONFIG IS RELOADED ANY TIME
    [[NSNotificationCenter defaultCenter] postNotificationName:kNOTIFICATION_MASTER_CONFIG_COMPLETED object:self];
}

#pragma mark - Fetching, Caching & Parsing of JSON (semantic wiki)

-(void) semanticWikiFillCached:(BOOL)isCachedContent {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *pathToCachedAssemblyFile = [kFOLDER_DOCUMENTS stringByAppendingPathComponent:kFILE_CACHED_ASSEMBLIES];
    NSString *pathToCachedWorkshopFile = [kFOLDER_DOCUMENTS stringByAppendingPathComponent:kFILE_CACHED_WORKSHOPS];
    // FETCH FROM CACHE
    if( [fm fileExistsAtPath:pathToCachedAssemblyFile] ) {
        NSString *jsonString = [NSString stringWithContentsOfFile:pathToCachedAssemblyFile encoding:NSUTF8StringEncoding error:nil];
        id result = nil;
        @try {
            result = [[Assemblies class] objectFromJSONObject:[jsonString JSONValue] mapping:[Assemblies objectMapping]];
            if( DEBUG ) NSLog( @"WIKI: ASSEMBLIESCLASS = %@, OBJECT: %@", NSStringFromClass( [result class] ), result );
            Assemblies *assemblies = (Assemblies*)result;
            if( DEBUG ) NSLog( @"WIKI: ASSEMBLIES FOUND %i items", [[assemblies assemblyItems] count] );
            self.semanticWikiAssemblies = [assemblies assemblyItemsSorted];
        }
        @catch (NSException *exception) {
            self.semanticWikiAssemblies = [NSArray array];
            if( DEBUG ) NSLog( @"WIKI: NO ASSEMBLIES FOUND/PARSED" );
        }
    }
    if( [fm fileExistsAtPath:pathToCachedWorkshopFile] ) {
        NSString *jsonString = [NSString stringWithContentsOfFile:pathToCachedWorkshopFile encoding:NSUTF8StringEncoding error:nil];
        id result = nil;
        @try {
            result = [[Workshops class] objectFromJSONObject:[jsonString JSONValue] mapping:[Workshops objectMapping]];
            if( DEBUG ) NSLog( @"WIKI: WORKSHOPSCLASS = %@, OBJECT: %@", NSStringFromClass( [result class] ), result );
            Workshops *workshops = (Workshops*)result;
            if( DEBUG ) NSLog( @"WIKI: WORKSHOPS FOUND %i items", [[workshops workshopItems] count] );
            self.semanticWikiWorkshops = [workshops workshopItemsSorted];
        }
        @catch (NSException *exception) {
            self.semanticWikiWorkshops = [NSArray array];
            if( DEBUG ) NSLog( @"WIKI: NO WORKSHOPS FOUND/PARSED" );
        }
    }
}

- (BOOL) semanticWikiFetchAssemblies {
    [self showHudWithCaption:LOC( @"Aktualisiere Assemblies" ) hasActivity:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNOTIFICATION_JSON_STARTED object:self];
    NSURL *connectionUrl = [NSURL URLWithString:[[MasterConfig sharedConfiguration] urlStringForKey:kURL_KEY_29C3_ASSEMBLIES]];
    BBJSONConnectOperation *operation = [BBJSONConnectOperation operationWithConnectUrl:connectionUrl andPathComponent:nil delegate:self selFail:@selector(operationFailedAssemblies:) selInvalid:@selector(operationInvalidAssemblies:) selSuccess:@selector(operationSuccessAssemblies:)];
    operation.jsonObjectClass = [Assemblies class];
    operation.jsonMappingDictionary = [Assemblies objectMapping];
    operation.isOperationDebugEnabled = NO;
    // [self operationAddAsPending:operation];
    [[BBJSONConnector instance] operationInitiate:operation];
    return YES;
}

- (void) operationSuccessAssemblies:(BBJSONConnectOperation*)operation {
    // if( DEBUG ) NSLog( @"%s: SUCCESS.\nOPERATION: %@", __PRETTY_FUNCTION__, operation );
    [[NSNotificationCenter defaultCenter] postNotificationName:kNOTIFICATION_JSON_SUCCEEDED object:self];
    // [self operationRemoveFromPending:operation];
    Assemblies *assemblies = nil;
    NSInteger itemsInJson = 0;
    @try {
        NSLog( @"WIKI: WORKSHOPSCLASS = %@, OBJECT: %@", NSStringFromClass( [assemblies class] ), assemblies );
        assemblies = (Assemblies*)operation.result;
        itemsInJson = [[assemblies assemblyItems] count];
        if( DEBUG ) NSLog( @"WIKI: ASSEMBLIES FOUND %i items", itemsInJson );
        if( itemsInJson > 0 ) {
            self.semanticWikiAssemblies = [assemblies assemblyItemsSorted];
        }
    }
    @catch (NSException *exception) {
        self.semanticWikiAssemblies = [NSArray array];
        if( DEBUG ) NSLog( @"WIKI: NO ASSEMBLIES FOUND/PARSED" );
    }

    // SAVE ASSEMBLIES TO CACHE...
    BOOL hasStoredFile = NO;
    if( itemsInJson > 0 ) { // DO NOT STORE FUCKINg SHIT...
        NSString *jsonString = operation.currentRequest.responseString;
        NSString *pathToStoreFile = [kFOLDER_DOCUMENTS stringByAppendingPathComponent:kFILE_CACHED_ASSEMBLIES];
        hasStoredFile = [jsonString writeToFile:pathToStoreFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    if( !hasStoredFile ) {
        if( DEBUG ) NSLog( @"WIKI: ASSEMBLY JSON SAVING FAILED!!!" );
    }
    else {
        if( DEBUG ) NSLog( @"WIKI: ASSEMBLY JSON SAVING SUCCEEDED." );
    }
    
    // if( DEBUG ) NSLog( @"ASSEMBLIES: %@", assemblies );
    [self semanticWikiFetchWorkshops];
}

- (void) operationFailedAssemblies:(BBJSONConnectOperation*)operation {
    // [self operationRemoveFromPending:operation];
    if( DEBUG ) NSLog( @"%s: FAIL.\nOPERATION: %@", __PRETTY_FUNCTION__, operation );
    [[NSNotificationCenter defaultCenter] postNotificationName:kNOTIFICATION_JSON_FAILED object:self];
    [self hideHud];
    [self alertWithTag:0 title:LOC( @"Wikiplan" ) andMessage:LOC( @"Derzeit liegen keine\nAssemblydaten vor\num zu Aktualisieren.\n\nProbieren sie es später\nnoch einmal bitte!" )];
}

- (void) operationInvalidAssemblies:(BBJSONConnectOperation*)operation {
    // [self operationRemoveFromPending:operation];
    if( DEBUG ) NSLog( @"%s: INVALID.\nOPERATION: %@", __PRETTY_FUNCTION__, operation );
    [self hideHud];
}


- (BOOL) semanticWikiFetchWorkshops {
    [self showHudWithCaption:LOC( @"Aktualisiere Workshops" ) hasActivity:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNOTIFICATION_JSON_STARTED object:self];
    NSURL *connectionUrl = [NSURL URLWithString:[[MasterConfig sharedConfiguration] urlStringForKey:kURL_KEY_29C3_WORKSHOPS]];
    BBJSONConnectOperation *operation = [BBJSONConnectOperation operationWithConnectUrl:connectionUrl andPathComponent:nil delegate:self selFail:@selector(operationFailedWorkshops:) selInvalid:@selector(operationInvalidWorkshops:) selSuccess:@selector(operationSuccessWorkshops:)];
    operation.jsonObjectClass = [Workshops class];
    operation.jsonMappingDictionary = [Workshops objectMapping];
    operation.isOperationDebugEnabled = NO;
    // [self operationAddAsPending:operation];
    [[BBJSONConnector instance] operationInitiate:operation];
    return YES;
}

- (void) operationSuccessWorkshops:(BBJSONConnectOperation*)operation {
    // if( DEBUG ) NSLog( @"%s: SUCCESS.\nOPERATION: %@", __PRETTY_FUNCTION__, operation );
    [[NSNotificationCenter defaultCenter] postNotificationName:kNOTIFICATION_JSON_SUCCEEDED object:self];
    // [self operationRemoveFromPending:operation];
    Workshops *workshops = nil;
    NSInteger itemsInJson = 0;
    @try {
        workshops = (Workshops*)operation.result;
        NSLog( @"WIKI: WORKSHOPSCLASS = %@, OBJECT: %@", NSStringFromClass( [workshops class] ), workshops );
        itemsInJson = [[workshops workshopItems] count];
        if( DEBUG ) NSLog( @"WIKI: WORKSHOPS FOUND %i items", itemsInJson );
        if( itemsInJson > 0 ) {
            self.semanticWikiWorkshops = [workshops workshopItemsSorted];
        }
    }
    @catch (NSException *exception) {
        self.semanticWikiWorkshops = [NSArray array];
        if( DEBUG ) NSLog( @"WIKI: NO WORKSHOPS FOUND/PARSED" );
    }

    // if( DEBUG ) NSLog( @"WORKSHOPS: %@", workshops );
    BOOL hasStoredFile = NO;
    if( itemsInJson > 0 ) { // DO NOT STORE FUCKINg SHIT...
        NSString *jsonString = operation.currentRequest.responseString;
        NSString *pathToStoreFile = [kFOLDER_DOCUMENTS stringByAppendingPathComponent:kFILE_CACHED_WORKSHOPS];
        hasStoredFile = [jsonString writeToFile:pathToStoreFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    if( !hasStoredFile ) {
        if( DEBUG ) NSLog( @"WIKI: WORKSHOP JSON SAVING FAILED!!!" );
    }
    else {
        if( DEBUG ) NSLog( @"WIKI: WORKSHOP JSON SAVING SUCCEEDED." );
    }

    [self hideHud];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNOTIFICATION_JSON_COMPLETED object:self]; // MARKS END OF FETCHING
}

- (void) operationFailedWorkshops:(BBJSONConnectOperation*)operation {
    // [self operationRemoveFromPending:operation];
    if( DEBUG ) NSLog( @"%s: FAIL.\nOPERATION: %@", __PRETTY_FUNCTION__, operation );
    [[NSNotificationCenter defaultCenter] postNotificationName:kNOTIFICATION_JSON_FAILED object:self];
    [self hideHud];
    [self alertWithTag:0 title:LOC( @"Wikiplan" ) andMessage:LOC( @"Derzeit liegen keine\nWorkshopdaten vor\num zu Aktualisieren.\n\nProbieren sie es später\nnoch einmal bitte!" )];
}

- (void) operationInvalidWorkshops:(BBJSONConnectOperation*)operation {
    // [self operationRemoveFromPending:operation];
    if( DEBUG ) NSLog( @"%s: INVALID.\nOPERATION: %@", __PRETTY_FUNCTION__, operation );
    [self hideHud];
}


- (void) semanticWikiFetchAllData {
    if( DEBUG ) NSLog( @"WIKI: FETCHING DATA..." );
    [self semanticWikiFetchAssemblies];
}

- (void) semanticWikiLoadCached {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *pathToCachedAssemblyFile = [kFOLDER_DOCUMENTS stringByAppendingPathComponent:kFILE_CACHED_ASSEMBLIES];
    NSString *pathToCachedWorkshopFile = [kFOLDER_DOCUMENTS stringByAppendingPathComponent:kFILE_CACHED_WORKSHOPS];
    if( [fm fileExistsAtPath:pathToCachedAssemblyFile] && [fm fileExistsAtPath:pathToCachedWorkshopFile] ) {
        if( DEBUG ) NSLog( @"WIKI: JSON LOADING CACHED..." );
        [self semanticWikiFillCached:YES];
    }
    else {
        NSURL *bundleUrlAssemblies = [[NSBundle mainBundle] URLForResource:@"assemblies" withExtension:@"json"];
        NSURL *bundleUrlWorkshops = [[NSBundle mainBundle] URLForResource:@"workshops" withExtension:@"json"];
        NSData *dataAssemblies = [NSData dataWithContentsOfURL:bundleUrlAssemblies];
        NSData *dataWorkshops = [NSData dataWithContentsOfURL:bundleUrlWorkshops];
        // CLONE FROm BUNDLE
        BOOL hasStoredFileAssemblies = [dataAssemblies writeToFile:pathToCachedAssemblyFile atomically:YES];
        if( !hasStoredFileAssemblies ) {
            if( DEBUG ) NSLog( @"WIKI: JSON CLONING FAILED!!!" );
        }
        else {
            if( DEBUG ) NSLog( @"WIKI: JSON CLONING SUCCEEDED." );
        }
        BOOL hasStoredFileWorkshops = [dataWorkshops writeToFile:pathToCachedWorkshopFile atomically:YES];
        if( !hasStoredFileWorkshops ) {
            if( DEBUG ) NSLog( @"WIKI: JSON CLONING FAILED!!!" );
        }
        else {
            if( DEBUG ) NSLog( @"WIKI: JSON CLONING SUCCEEDED." );
        }
        if( hasStoredFileAssemblies && hasStoredFileWorkshops ) { // REFILL
            [self semanticWikiFillCached:YES];
        }
        // TRY TO UPDATE DATA IMMEDIATELY
        [self semanticWikiRefresh];
    }
}

- (void) semanticWikiRefresh {
    [self semanticWikiFetchAllData];
}

#pragma mark - Fetching & Caching of Images (pentabarf data)

- (void) barfBagImagesRefresh {
    [self showHudWithCaption:LOC( @"Aktualisiere Bilder" ) hasActivity:YES];
    NSArray *allPersons = [self conference].allPersons;
    if( allPersons && [allPersons count] > 0 ) {
        for( Person *currentPerson in allPersons ) {
            NSTimeInterval randomDelay = [self randomFloatBetweenLow:0.0 andHigh:30.0];
            [currentPerson performSelector:@selector(fetchCachedImage) withObject:nil afterDelay:randomDelay];
        }
    }
    [self hideHud];
}

#pragma mark - Fetching, Caching & Parsing of XML (pentabarf data)

// BarfBagParserDelegate

- (void) barfBagParser:(BarfBagParser*)parser parsedConferences:(NSArray *)conferencesArray {
    self.scheduledConferences = conferencesArray;
    
    // CHECK IF WE HAVE VALID DATA
    if( !scheduledConferences || [scheduledConferences count] == 0 ) {
        if( DEBUG ) NSLog( @"BARFBAG: PARSING FAILED (NO DATA FOUND!)" );
        [[NSNotificationCenter defaultCenter] postNotificationName:kNOTIFICATION_PARSER_FAILED object:self];
        return;
    }
    
    // UPDATE VERSION & INFORM USER IF NECESSARY
    Conference *currentConference = nil;
    @try {
        currentConference = (Conference*)[scheduledConferences lastObject];
    }
    @catch (NSException *exception) {
        // do nothing
    }
    if( currentConference ) {
        NSLog( @"BARFBAG: RELEASE = %@", currentConference.release );
        [currentConference computeCachedProperties];
        NSString *versionCurrent = [self barfBagCurrentDataVersion];
        NSString *versionUpdated = currentConference.release;
        [[NSUserDefaults standardUserDefaults] setObject:versionUpdated forKey:kUSERDEFAULT_KEY_DATA_VERSION_UPDATED];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        BOOL shouldDumpObjectGraph = NO; // FOR DEBUGGING PROBLEMS
        if( shouldDumpObjectGraph ) {
            NSLog( @"CREATED CONFERENCE: %@", currentConference );
            NSLog( @"CREATED %i DAYS", [currentConference.days count] );
            for( Day *currentDay in currentConference.days ) {
                NSLog( @"\n\nDAY %i HAS %i EVENTS\n", currentDay.dayIndex, [currentDay.events count] );
                for( Event *currentEvent in currentDay.events ) {
                    //NSLog( @"EVENT (%i): %@ [TIME: %i:%i]", currentEvent.eventId, currentEvent.title, currentEvent.timeHour, currentEvent.timeMinute );
                    NSLog( @"%@", currentEvent );
                }
            }
        }
        
        BOOL hasNewDataVersion = ![versionUpdated isEqualToString:versionCurrent];
        if( hasNewDataVersion ) {
            [[NSUserDefaults standardUserDefaults] setObject:versionUpdated forKey:kUSERDEFAULT_KEY_DATA_VERSION_CURRENT];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self alertWithTag:0 title:LOC( @"Aktualisierung" ) andMessage:[NSString stringWithFormat:LOC( @"Die Plandaten wurden aktualisiert auf %@." ), [NSString placeHolder:@"n.a." forEmptyString:versionUpdated]]];
        }
    }
    if( DEBUG ) NSLog( @"BARFBAG: PARSING COMPLETED." );
    [[NSNotificationCenter defaultCenter] postNotificationName:kNOTIFICATION_PARSER_COMPLETED object:self];
    // FETCH IMAGES IF USER CHOSE TO
    if( [self isConfigOnForKey:kUSERDEFAULT_KEY_BOOL_IMAGEUPDATE defaultValue:YES] ) {
        [self barfBagImagesRefresh];
    }
    else {
        [self hideHud];    
    }
}

- (NSString*) barfBagCurrentDataVersion {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kUSERDEFAULT_KEY_DATA_VERSION_CURRENT];
}

-(void) barfBagFillCached:(BOOL)isCachedContent {
    NSString *pathToStoredFile = nil;
    if( [MasterConfig sharedConfiguration].currentLanguage == MasterConfigLanguageEn ) {
        pathToStoredFile = [kFOLDER_DOCUMENTS stringByAppendingPathComponent:kFILE_CACHED_FAHRPLAN_EN]; // CACHE .xml file
    }
    else {
        pathToStoredFile = [kFOLDER_DOCUMENTS stringByAppendingPathComponent:kFILE_CACHED_FAHRPLAN_DE]; // CACHE .xml file
    }
	BarfBagParser *pentaParser = [[BarfBagParser alloc] init];
	pentaParser.responseData = [NSData dataWithContentsOfFile:pathToStoredFile];
	pentaParser.delegate = self;
	[pentaParser startParsingResponseData];
}

- (void) barfBagFetchContentWithUrlString:(NSString*)urlString {
    if( DEBUG ) NSLog( @"BARFBAG: XML FETCHING FROM %@", urlString );
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                                              cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                          timeoutInterval:kCONNECTION_TIMEOUT];
    
    [self addUserAgentInfoToRequest:theRequest];
    
    BOOL shouldCheckModifiedDate = NO;
    if( shouldCheckModifiedDate ) {
        NSString *modifiedDateString = nil;
        CGFloat secondsForTwoMonths = 60*24*60*60;
        NSDate *lastModifiedDate = [NSDate dateWithTimeIntervalSinceNow:-secondsForTwoMonths];
        @try {
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            df.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'";
            df.locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
            df.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
            modifiedDateString = [df stringFromDate:lastModifiedDate];
            [df release];
        }
        @catch (NSException * e) {
            // do nothing
        }
        NSLog( @"FETCHING STUFF SINCE DATE: %@", lastModifiedDate );
        [theRequest addValue:modifiedDateString forHTTPHeaderField:@"If-Modified-Since"];
    }
    
    // KICK OFF CONNECTION AS BLOCK
    [SinaURLConnection asyncConnectionWithRequest:theRequest completionBlock:^(NSData *data, NSURLResponse *response) {
        NSInteger statusCode = ((NSHTTPURLResponse*)response).statusCode;
        if( DEBUG ) NSLog( @"BARFBAG: XML CONNECTION RESPONSECODE: %i", statusCode );
        // REPLACE STORED OFFLINE DATA
        if( statusCode != 200 ) {
            [self alertWithTag:0 title:LOC( @"Fahrplan" ) andMessage:LOC( @"Derzeit liegen keine\nFahrplandaten vor\num zu Aktualisieren.\n\nProbieren sie es später\nnoch einmal bitte!" )];
        }
        else {
            BOOL isCached = NO;
            if( data && [data length] > 500 ) {
                isCached = NO;
                // SAVE INFOS
                NSString *pathToStoreFile = nil;
                if( [MasterConfig sharedConfiguration].currentLanguage == MasterConfigLanguageEn ) {
                    pathToStoreFile = [kFOLDER_DOCUMENTS stringByAppendingPathComponent:kFILE_CACHED_FAHRPLAN_EN]; // CACHE .xml file
                }
                else {
                    pathToStoreFile = [kFOLDER_DOCUMENTS stringByAppendingPathComponent:kFILE_CACHED_FAHRPLAN_DE]; // CACHE .xml file
                }
                BOOL hasStoredFile = [data writeToFile:pathToStoreFile atomically:YES];
                if( !hasStoredFile ) {
                    if( DEBUG ) NSLog( @"BARFBAG: XML SAVING FAILED!!!" );
                }
                else {
                    if( DEBUG ) NSLog( @"BARFBAG: XML SAVING SUCCEEDED." );
                }
                [self barfBagFillCached:isCached];
            }
            else {
                isCached = YES;
                [self barfBagFillCached:isCached];
            }
        }
        [self hideHud];
    } errorBlock:^(NSError *error) {
        if( DEBUG ) NSLog( @"BARFBAG: NO INTERNET CONNECTION." );
        [self alertWithTag:0 title:LOC( @"Verbindungsproblem" ) andMessage:[NSString stringWithFormat:LOC( @"Derzeit besteht scheinbar\nkeine Internetverbindung zum\nAktualisieren der Daten.\n\nSie verwenden derzeit\n%@ der Daten." ), [NSString placeHolder:@"n.a." forEmptyString:[self barfBagCurrentDataVersion]]]];
        // TODO: DISPLAY SOME ERROR...
        BOOL isCached = YES;
        [self barfBagFillCached:isCached];
        [self hideHud];
    } uploadProgressBlock:^(float progress) {
        // do nothing
    } downloadProgressBlock:^(float progress) {
        // TODO: UPDATE PROGRESS DISPLAY ...
    } cancelBlock:^(float progress) {
        // do nothing
        [self hideHud];
    }];
}

- (void) barfBagLoadCached {
    NSString *pathToCachedFile = [kFOLDER_DOCUMENTS stringByAppendingPathComponent:kFILE_CACHED_FAHRPLAN_EN]; // CACHE .xml file
    NSFileManager *fm = [NSFileManager defaultManager];
    if( [fm fileExistsAtPath:pathToCachedFile] ) {
        if( DEBUG ) NSLog( @"BARFBAG: XML LOADING CACHED..." );
        [self barfBagFillCached:YES];
    }
    else {
        // MOVE ONE COPY FROM BUNDLE
        NSURL *bundleUrlEn = [[NSBundle mainBundle] URLForResource:@"fahrplan_en" withExtension:@"xml"];
        NSURL *bundleUrlDe = [[NSBundle mainBundle] URLForResource:@"fahrplan_de" withExtension:@"xml"];
        NSData *dataEn = [NSData dataWithContentsOfURL:bundleUrlEn];
        NSData *dataDe = [NSData dataWithContentsOfURL:bundleUrlDe];
        NSString *pathToStoreFileEn = [kFOLDER_DOCUMENTS stringByAppendingPathComponent:kFILE_CACHED_FAHRPLAN_EN]; // CACHE .xml file
        NSString *pathToStoreFileDe = [kFOLDER_DOCUMENTS stringByAppendingPathComponent:kFILE_CACHED_FAHRPLAN_DE]; // CACHE .xml file
        BOOL hasStoredFileEn = [dataEn writeToFile:pathToStoreFileEn atomically:YES];
        if( !hasStoredFileEn ) {
            if( DEBUG ) NSLog( @"BARFBAG: XML EN CLONING FAILED!!!" );
        }
        else {
            if( DEBUG ) NSLog( @"BARFBAG: XML EN CLONING SUCCEEDED." );
        }
        BOOL hasStoredFileDe = [dataDe writeToFile:pathToStoreFileDe atomically:YES];
        if( !hasStoredFileDe ) {
            if( DEBUG ) NSLog( @"BARFBAG: XML DE CLONING FAILED!!!" );
        }
        else {
            if( DEBUG ) NSLog( @"BARFBAG: XML DE CLONING SUCCEEDED." );
        }
        if( hasStoredFileDe && hasStoredFileEn ) { // FILL NOW
            [self barfBagFillCached:YES];
        }
        
        // TRY TO UPDATE DATA IMMEDIATELY
        [self barfBagRefresh];
    }
}

- (void) barfBagRefresh {
    [self showHudWithCaption:LOC( @"Aktualisiere Fahrplan" ) hasActivity:YES];
    [self barfBagFetchContentWithUrlString:[[MasterConfig sharedConfiguration] urlStringForKey:kURL_KEY_29C3_FAHRPLAN]];
}

#pragma mark - Manage Full Auto Update Run & Master Configuration

- (NSString*) masterConfigRemoteStringForKey:(NSString*)key {
    if( !masterConfiguration || [masterConfiguration count] == 0 ) return nil;
    return nil;
}

- (void) allDataLoadCached {
    [self barfBagLoadCached];
    [self semanticWikiLoadCached];
}

- (void) allDataRefreshDelayed { // START REAL UPDATES 15 SECONDS DELAYED
    [self barfBagRefresh];
    [self semanticWikiRefresh];
}

- (void) allDataRefresh { // FIRST UPDATE MASTER CONFIG
    [self performSelector:@selector(allDataRefreshDelayed) withObject:nil afterDelay:0.3];
}

- (void) manageCloudStorage {
    if( DEBUG ) NSLog( @"CLOUD: STATUS CHANGED" );
    if( [[MKiCloudSync instance] isDeviceCloudEnabled] ) {
        if( [self isConfigOnForKey:kUSERDEFAULT_KEY_BOOL_USE_CLOUD_SYNC defaultValue:YES] ) {
            if( DEBUG ) NSLog( @"CLOUD: WILL START CLOUD SYNC..." );
            [[MKiCloudSync instance] start];
        }
    }
    else {
        if( DEBUG ) NSLog( @"CLOUD: WILL STOP CLOUD SYNC..." );
        [[MKiCloudSync instance] stop];
    }
}

- (void) activateCloudSupport {
    // START SYNC TO ICLOUD
    // MONITOR ICLOUD AVAILABILITY
    if( ![[UIDevice currentDevice] isLowerThanOS_6] ) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(manageCloudStorage)
                                                     name:NSUbiquityIdentityDidChangeNotification                                                    object:nil];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(signalCloudSyncToUser) name:kMKiCloudSyncNotification object:nil];
    
    if( [self isConfigOnForKey:kUSERDEFAULT_KEY_BOOL_USE_CLOUD_SYNC defaultValue:YES] ) {
        if( DEBUG ) NSLog( @"CLOUD: USER WANTS IT." );
        [[MKiCloudSync instance] start];
    }
    else {
        if( DEBUG ) NSLog( @"CLOUD: USER DOES NOT WANT IT." );
    }
}

#pragma mark - Application Launching & State Transitions

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    self.themeColor = [self randomColor];

    // CONFIGURE APP
    [MasterConfig sharedConfiguration].delegate = self;
    // WILL REFRESH CONFIG FROM CACHE/BUNDLE
    [[MasterConfig sharedConfiguration] initialize];
        
    // CONFIGURE CUSTOM UI APPEARANCE
    [self configureAppearance];
    
    // SETUP ROOT CONTROLLER
    NSMutableArray *viewControllers = [NSMutableArray array];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [viewControllers addObject:[[[ScheduleNavigationController alloc] initWithNibName:@"ScheduleNavigationController" bundle:nil] autorelease]];
        [viewControllers addObject:[[[ScheduleSemanticNavigationController alloc] initWithNibName:@"ScheduleSemanticNavigationController" bundle:nil] autorelease]];
        [viewControllers addObject:[[[FavouritesNavigationController alloc] initWithNibName:@"FavouritesNavigationController" bundle:nil] autorelease]];
        [viewControllers addObject:[[[VideoStreamNavigationController alloc] initWithNibName:@"VideoStreamNavigationController" bundle:nil] autorelease]];
        [viewControllers addObject:[[[ConfigurationNavigationController alloc] initWithNibName:@"ConfigurationNavigationController" bundle:nil] autorelease]];
    }
    else {
        [viewControllers addObject:[[[ScheduleNavigationController alloc] initWithNibName:@"ScheduleNavigationController" bundle:nil] autorelease]];
        [viewControllers addObject:[[[ScheduleSemanticNavigationController alloc] initWithNibName:@"ScheduleSemanticNavigationController" bundle:nil] autorelease]];
        [viewControllers addObject:[[[FavouritesNavigationController alloc] initWithNibName:@"FavouritesNavigationController" bundle:nil] autorelease]];
        [viewControllers addObject:[[[VideoStreamNavigationController alloc] initWithNibName:@"VideoStreamNavigationController" bundle:nil] autorelease]];
        [viewControllers addObject:[[[ConfigurationNavigationController alloc] initWithNibName:@"ConfigurationNavigationController" bundle:nil] autorelease]];
    }
    self.tabBarController = [[[GenericTabBarController alloc] init] autorelease];
    _tabBarController.viewControllers = viewControllers;
    _window.rootViewController = self.tabBarController;
    [_window makeKeyAndVisible];
    
    // ADD WELCOME CONTROLLER ON TOP
    WelcomeViewController *controller = [[[WelcomeViewController alloc] initWithNibName:@"WelcomeViewController" bundle:nil] autorelease];
    CGFloat width = _window.bounds.size.width;
    CGFloat height = _window.bounds.size.height;
    CGRect windowRect = CGRectMake(0.0, 0.0, width, height);
    controller.view.frame = windowRect;
    [_window.rootViewController.view addSubview:controller.view];
    
    // WELCOME CONTROLLER WILL TRIGGER UPDATE OF DATA WHEN IT DISMISSES ITSELF
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (BOOL) shouldExecuteAutoUpdate {
    if( [self isConfigOnForKey:kUSERDEFAULT_KEY_BOOL_AUTOUPDATE defaultValue:YES] ) {
        NSDate *dateLastUpdated = [[NSUserDefaults standardUserDefaults] objectForKey:kUSERDEFAULT_KEY_DATE_LAST_UPDATED];
        if( !dateLastUpdated ) return YES;
        NSTimeInterval intervalInSeconds = fabs( [dateLastUpdated timeIntervalSinceNow] );
        CGFloat maxInterval = 30.0f * 60.0f; // 30 minutes
        BOOL shouldUpdate = ( intervalInSeconds > maxInterval );
        NSLog( @"AUTOUPDATE: %.0f MINUTES OLD. %@", floorf(( intervalInSeconds / 60.0f )), shouldUpdate ? @"WILL UPDATE." : @"STILL GOOD ENOUGH." );
        return shouldUpdate;
    }
    else {
        NSLog( @"AUTOUPDATE: DEACTIVATED BY USER." );
        return NO;
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kNOTIFICATION_MASTER_CONFIG_COMPLETED object:nil];
    }
    @catch (NSException *exception) {}
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(allDataRefresh) name:kNOTIFICATION_MASTER_CONFIG_COMPLETED object:nil];

    // CHECK IF WE NEED TO UPDATE
    if( [self shouldExecuteAutoUpdate] ) {
        [[MasterConfig sharedConfiguration] refreshFromMothership];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
}
*/


/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed
{
}
*/

#pragma mark - Headup Display Management

- (void) showHudWithCaption:(NSString*)caption hasActivity:(BOOL)hasActivity {
#if SCREENSHOTMODE
    return;
#endif
    // ADD HUD VIEW
    if( !hud ) {
        self.hud = [[ATMHud alloc] initWithDelegate:self];
        [_window.rootViewController.view addSubview:hud.view];
    }
    [hud setCaption:caption];
    [hud setActivity:hasActivity];
    [hud show];
}

- (void) hideHud {
    [hud hideAfter:1.0];
}

- (void) userDidTapHud:(ATMHud *)_hud {
	[_hud hide];
}


@end
