//
//  EventsViewController.m
//  barfbag
//
//  Created by Lincoln Six Echo on 03.12.12.
//  Copyright (c) 2012 appdoctors. All rights reserved.
//

#import "FahrplanViewController.h"
#import "AppDelegate.h"
#import "Conference.h"
#import "Day.h"
#import "Event.h"
#import "AppDelegate.h"
#import "EventDetailViewController.h"

@implementation FahrplanViewController

@synthesize sectionKeys;
@synthesize sectionArrays;
@synthesize indexPathMedian;
@synthesize timerUpdateMedian;
@synthesize cachedCellBackgroundImageViews;

- (void) dealloc {
    self.sectionKeys = nil;
    self.sectionArrays = nil;
    self.indexPathMedian = nil;
    self.timerUpdateMedian = nil;
    self.cachedCellBackgroundImageViews = nil;
    [super dealloc];
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) timerStopMedian {
    if( timerUpdateMedian && [timerUpdateMedian isValid] ) {
        [timerUpdateMedian invalidate];
    }
    self.timerUpdateMedian = nil;
}

- (void) timerStartMedian {
    [self timerStopMedian];
    self.timerUpdateMedian = [NSTimer scheduledTimerWithTimeInterval:300 target:self selector:@selector(updateMedianIndexPath) userInfo:nil repeats:YES];
    [self updateMedianIndexPath];
}

- (void) updateMedianIndexPath {
    self.indexPathMedian = [self indexPathOfItemWithMinimumMinutesTilStart];
}

#pragma mark - Convenience Methods

- (void) updateNavigationTitle {
    self.navigationItem.titleView = nil;
    BOOL useCustomTitleView = NO;
    if( useCustomTitleView ) {
        self.navigationItem.titleView = [self navigationTitleView];
    }
    else {
        self.navigationItem.title = [self navigationTitleString];
    }
}

- (UIView*) navigationTitleView {
    CGFloat width = self.view.bounds.size.width-40.0f;
    CGFloat height = self.navigationController.navigationBar.bounds.size.height;
    UILabel *titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, width, height)] autorelease];
    titleLabel.textColor = kCOLOR_WHITE;
    titleLabel.backgroundColor = kCOLOR_CLEAR;
    titleLabel.adjustsFontSizeToFitWidth = YES;
    titleLabel.text = [self navigationTitleString];
    titleLabel.textAlignment = UITextAlignmentCenter;
    titleLabel.font = [UIFont boldSystemFontOfSize:17.0];
    return titleLabel;
}

- (NSString*) navigationTitleString {
    NSString *title = [self conference].title;
    BOOL shouldOverrideScheduleTitle = YES;
    if( shouldOverrideScheduleTitle ) {
        return LOC( @"29C3 Fahrplan" );
    }
    if( !title || [title length] == 0 ) {
        return LOC( @"Ereignisse" );
    }
    else {
        return title;
    }
}

#pragma mark - User Actions

- (void) actionRefreshData {
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [[self appDelegate] barfBagRefresh];
}

- (void) actionUpdateDisplayAfterRefresh {
    [self updateTableFooter];
    // SETUP DATA
    self.sectionArrays = [NSMutableDictionary dictionary];
    NSMutableArray *neededSectionKeys = [NSMutableArray array];
    
    NSArray *days = [[self conference] days];
    NSInteger indexDay = 0;
    NSString *currentDayKey = nil;
    for( Day *currentDay in days ) {
        currentDayKey = [NSString stringWithFormat:@"day%i", indexDay];
        [neededSectionKeys addObject:currentDayKey];
        [sectionArrays setObject:currentDay.eventsSorted forKey:currentDayKey];
        indexDay++;
    }
    
    if( [[self conference].allLinks count] > 0 ) {
        [neededSectionKeys addObject:@"links"];
        [sectionArrays setObject:[self conference].allLinks forKey:@"links"];
    }

    if( [[self conference].allPersons count] > 0 ) {
        [neededSectionKeys addObject:@"persons"];
        [sectionArrays setObject:[self conference].allPersons forKey:@"persons"];
    }

    self.sectionKeys = [NSArray arrayWithArray:neededSectionKeys];

    
    [self.tableView reloadData];
    [self updateNavigationTitle];
    self.navigationItem.rightBarButtonItem.enabled = YES;
    [self timerStartMedian];
}

- (IBAction) actionButtonTapped:(id)sender {
    NSLog( @"BUTTON TAPPED." );
}

- (IBAction) actionSearch:(id)sender {
    
}

- (IBAction) actionMultiActionButtonTapped:(id)sender {
    NSLog( @"ACTION TAPPED." );
    
}

- (void) actionOpenWebPage {
    NSString* urlString = [[MasterConfig sharedConfiguration] urlStringForKey:kURL_KEY_29C3_FAHRPLAN_SITE];
    NSURL *url = [NSURL URLWithString:urlString];
    [self loadSimpleWebViewWithURL:url shouldScaleToFit:YES];
}

- (void) updateTableFooter {
    CGFloat width = self.tableView.frame.size.width;
    UIView *footerView = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, width, 70.0)] autorelease];
    footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    footerView.backgroundColor = [self themeColor];
    UIButton *buttonOpenWiki = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 250.0, 40.0)];
    [buttonOpenWiki addTarget:self action:@selector(actionOpenWebPage) forControlEvents:UIControlEventTouchUpInside];
    [footerView addSubview:buttonOpenWiki];
    [buttonOpenWiki setTitle:[NSString stringWithFormat:@"Fahrplan: %@", [NSString placeHolder:@"n.a." forEmptyString:[self appDelegate].barfBagCurrentDataVersion]] forState:UIControlStateNormal];
    [buttonOpenWiki.titleLabel setFont:[UIFont boldSystemFontOfSize:buttonOpenWiki.titleLabel.font.pointSize]];
    [buttonOpenWiki setTitleColor:kCOLOR_WHITE forState:UIControlStateNormal];
    buttonOpenWiki.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    buttonOpenWiki.center = footerView.center;
    self.tableView.tableFooterView = footerView;
}

- (void)viewDidLoad {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(actionUpdateDisplayAfterRefresh) name:kNOTIFICATION_PARSER_COMPLETED  object:nil];
    [super viewDidLoad];
        
    if( [self tableView:self.tableView numberOfRowsInSection:0] == 0 ) {
        [[self appDelegate] barfBagLoadCached];
    }
    self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:LOC( @"Zurück" ) style:UIBarButtonItemStyleBordered target:nil action:nil] autorelease];
    UIBarButtonItem *item = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(actionRefreshData)] autorelease];
    self.navigationItem.rightBarButtonItem = item;
    [self updateNavigationTitle];
    [self updateTableFooter];
    
    [self actionUpdateDisplayAfterRefresh];
    
    /*
    UIImage *searchFieldBackgroundImage = [self imageGradientWithSize:self.searchDisplayController.searchBar.bounds.size color1:[self themeColor] color2:[self darkColor]];
;
    [self.searchDisplayController.searchBar setSearchFieldBackgroundImage:searchFieldBackgroundImage forState:UIControlStateNormal];
    */
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if( isSearching ) {
        return [NSString stringWithFormat:LOC( @"%i Treffer" ), [searchItemsFiltered count] ];
    }
    else {
        NSString *sectionKey = [sectionKeys objectAtIndex:section];
        NSArray *itemArray = [sectionArrays objectForKey:sectionKey];
        if( [sectionKey isEqualToString:@"links"] ) {
            return [NSString stringWithFormat:LOC( @"Links (%i Einträge)" ), [itemArray count]];
        }
        else if([sectionKey isEqualToString:@"persons"] ) {
            return [NSString stringWithFormat:LOC( @"Persons (%i Einträge)" ), [itemArray count]];
        }
        else { // day1, day2
            NSArray *days = [[self conference] days];
            Day *currentDay = [days objectAtIndex:section];
            return [NSString stringWithFormat:LOC( @"%@  –  %i Events" ),[self stringShortDayForDate:currentDay.date], [itemArray count]];
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if( isSearching ) {
        return 1;
    }
    else {
        return [sectionKeys count];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if( isSearching ) {
        return [searchItemsFiltered count];
    }
    else {
        NSString *sectionKey = [sectionKeys objectAtIndex:section];
        return [[sectionArrays objectForKey:sectionKey] count];
    }
}

- (NSIndexPath*) indexPathOfItemWithMinimumMinutesTilStart {
    NSArray *allItems = [self appDelegate].conference.allEvents;
    SearchableItem *itemFound = nil;
    NSIndexPath *indexPathFound = nil;
    NSInteger indexFound = 0;
    NSInteger index = 0;
    NSTimeInterval minimumInterval = CGFLOAT_MAX;
    
    for( SearchableItem *currentItem in allItems ) {
        if( currentItem.itemSecondsTilStart > 0 && currentItem.itemSecondsTilStart < minimumInterval ) {
            minimumInterval = currentItem.itemSecondsTilStart;
            itemFound = currentItem;
            indexFound = index;
        }
        index++;
    }
    // FIND ITEM IN SECTIONS
    NSInteger section = 0;
    NSInteger row = 0;
    for( NSString *currentSectionKey in sectionKeys ) {
        NSArray *currentSectionArray = [sectionArrays objectForKey:currentSectionKey];
        if( [currentSectionKey containsString:@"day"] ) { // ONLY SCAN EVENTS
            row = 0;
            for( id currentItem in currentSectionArray ) {
                if( currentItem == itemFound ) {
                    indexPathFound = [NSIndexPath indexPathForRow:row inSection:section];
                    return indexPathFound;
                }
                row++;
            }
        }
        section++;
    }
    return indexPathFound;
}

- (NSIndexPath*) indexPathForPreviousOfIndexPath:(NSIndexPath*)indexPath {
    if( !indexPath ) return nil;
    NSInteger row, section = 0;
    if( indexPath.row > 0 ) {
        row = indexPath.row-1;
        section = indexPath.section;
    }
    else {
        section = indexPath.section-1;
        if( section < 0 ) return nil;
        NSInteger numOfRows = [self tableView:self.tableView numberOfRowsInSection:section];
        row = numOfRows-1;
    }
    return [NSIndexPath indexPathForRow:row inSection:section];
}

- (NSIndexPath*) indexPathForNextOfIndexPath:(NSIndexPath*)indexPath {
    if( !indexPath ) return nil;
    NSInteger row, section = 0;
    NSInteger numOfRows = [self tableView:self.tableView numberOfRowsInSection:indexPath.section];
    if( indexPath.row == numOfRows-1 ) {
        section = indexPath.section+1;
        if( section > [self numberOfSectionsInTableView:self.tableView] ) {
            return nil;
        }
        row = 0;
    }
    else {
        row = indexPath.row +1;
        section = indexPath.section;
    }
    return [NSIndexPath indexPathForRow:row inSection:section];
}

- (NSInteger)rowDistanceForIndexPath:(NSIndexPath*)indexPathTarget fromIndexPath:(NSIndexPath*)indexPathSource {
    BOOL isDistanceNegative = NO;
    if( indexPathTarget.section == indexPathSource.section ) {
        if( indexPathTarget.row == indexPathSource.row ) {
            isDistanceNegative = NO;
            return 0;
        }
        else {
            return( indexPathSource.row - indexPathTarget.row );
        }
    }
    else if( indexPathTarget.section < indexPathSource.section ) {
        NSInteger currentNumOfRows = 0;
        NSInteger distance = 0;
        currentNumOfRows = [self tableView:self.tableView numberOfRowsInSection:indexPathSource.section];
        distance = distance + (indexPathSource.row+1);
        currentNumOfRows = [self tableView:self.tableView numberOfRowsInSection:indexPathTarget.section];
        distance = distance + (currentNumOfRows-(indexPathTarget.row+1));
        if( abs(indexPathTarget.section - indexPathSource.section) > 1 ) {
            for( int i = indexPathTarget.section+1; i < indexPathSource.section; i++ ) {
                currentNumOfRows = [self tableView:self.tableView numberOfRowsInSection:i];
                distance = distance + currentNumOfRows;
            }
        }
        return distance;
    }
    else { // if( indexPathTarget.section > indexPathSource.section )
        NSInteger currentNumOfRows = 0;
        NSInteger distance = 0;
        currentNumOfRows = [self tableView:self.tableView numberOfRowsInSection:indexPathSource.section];
        distance = distance + (currentNumOfRows-(indexPathSource.row+1));
        currentNumOfRows = [self tableView:self.tableView numberOfRowsInSection:indexPathTarget.section];
        distance = distance + ((indexPathTarget.row+1));
        if( abs(indexPathTarget.section - indexPathSource.section) >= 1 ) {
            for( int i = indexPathSource.section+1; i < indexPathTarget.section; i++ ) {
                currentNumOfRows = [self tableView:self.tableView numberOfRowsInSection:i];
                distance = distance + currentNumOfRows;
            }
        }
        return -abs(distance);
    }
}

- (UIColor*) backgroundColorForCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath {
    NSInteger rowScope = 7;
    NSInteger indexDistance = [self rowDistanceForIndexPath:indexPath fromIndexPath:indexPathMedian];
    NSInteger absIndexDistance = abs(indexDistance);
    if( absIndexDistance > rowScope ) return nil;
    
    CGFloat intensityValue = 1.0-[[NSNumber numberWithInt:abs(indexDistance)] floatValue] / [[NSNumber numberWithInt:rowScope] floatValue];
    
    UIColor *color1 = kCOLOR_BACK;
    UIColor *colorPre = [self themeColor];
    CGFloat huePre = [colorPre hue];
    UIColor *color2 = [UIColor colorWithHue:huePre saturation:1.0 brightness:0.4 alpha:1.0];
    
    CGFloat rDiff = [color2 red] - [color1 red];
    CGFloat gDiff = [color2 green] - [color1 green];
    CGFloat bDiff = [color2 blue] - [color1 blue];
    
    CGFloat red = [color1 red]+(intensityValue * rDiff);
    CGFloat green = [color1 green]+(intensityValue * gDiff);
    CGFloat blue = [color1 blue]+(intensityValue * bDiff);
    
    /*
    CGFloat hue1 = [color1 hue];
    CGFloat brightness1 = [color1 brightness]+((1.0-[color1 brightness]) * 0.6*intensityValue);
    // CGFloat saturation1 = isPastEvent ? [color1 saturation]*0.5 : [color1 saturation];
    // CGFloat alpha1 = isPastEvent ? 0.5+(0.3*intensityValue) : 0.5+(0.5*intensityValue);
    color1 =  [UIColor colorWithHue:hue1 saturation:[color1 saturation] brightness:brightness1 alpha:1.0];
     */
    color1 =  [UIColor colorWithRed:red green:green blue:blue alpha:1.0];

    return color1;
}

- (UIColor*) textLabelColorForCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath withColor:(UIColor*)colorInput {
    NSInteger rowScope = 7;
    NSInteger indexDistance = [self rowDistanceForIndexPath:indexPath fromIndexPath:indexPathMedian];
    NSInteger absIndexDistance = abs(indexDistance);
    if( absIndexDistance > rowScope ) return colorInput;
    
    CGFloat intensityValue = 1.0-[[NSNumber numberWithInt:abs(indexDistance)] floatValue] / [[NSNumber numberWithInt:rowScope] floatValue];
    
    UIColor *color1 = colorInput;
    
    CGFloat hue1 = [color1 hue];
    CGFloat brightness1 = [color1 brightness];
    CGFloat saturation1 = [color1 saturation]+((1.0-[color1 saturation]) * 0.8*intensityValue);
    // CGFloat alpha1 = isPastEvent ? 0.5+(0.3*intensityValue) : 0.5+(0.5*intensityValue);
    color1 =  [UIColor colorWithHue:hue1 saturation:saturation1 brightness:brightness1 alpha:1.0];
    return color1;
}

- (UIView*) backgroundViewForCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath {
    if( !cachedCellBackgroundImageViews ) {
        self.cachedCellBackgroundImageViews = [NSMutableDictionary dictionary];
    }
    NSInteger rowScope = 7;
    NSInteger indexDistance = [self rowDistanceForIndexPath:indexPath fromIndexPath:indexPathMedian];
    NSInteger absIndexDistance = abs(indexDistance);
    if( absIndexDistance > rowScope ) return nil;
    // BOOL isPastEvent = ( indexDistance < 0 );
    NSString *cacheKey = [NSString stringWithFormat:@"%i", indexDistance];
    
    if( [cachedCellBackgroundImageViews objectForKey:cacheKey] ) {
        // NSLog( @"CACHE READ %@", cacheKey );
        return [cachedCellBackgroundImageViews objectForKey:cacheKey];
    }
    CGFloat intensityValue = 1.0-[[NSNumber numberWithInt:abs(indexDistance)] floatValue] / [[NSNumber numberWithInt:rowScope] floatValue];
    
    UIColor *color1 = kCOLOR_BACK;
    UIColor *color2 = kCOLOR_BACK;
    
    CGFloat hue1 = [color1 hue];
    CGFloat brightness1 = [color1 brightness]+((1.0-[color1 brightness]) * 0.8*intensityValue);
    // CGFloat saturation1 = isPastEvent ? [color1 saturation]*0.5 : [color1 saturation];
    // CGFloat alpha1 = isPastEvent ? 0.5+(0.3*intensityValue) : 0.5+(0.5*intensityValue);
    color1 =  [UIColor colorWithHue:hue1 saturation:[color1 saturation] brightness:brightness1 alpha:1.0];
    
    CGFloat hue2 = [color2 hue];
    CGFloat brightness2 = [color2 brightness]+((1.0-[color2 brightness]) * 0.4 *intensityValue);
    // CGFloat saturation2 = isPastEvent ? [color2 saturation]*0.5 : [color2 saturation];
    // CGFloat alpha2 = isPastEvent ? 0.2+(0.3*intensityValue) : 0.5+(0.5*intensityValue);
    color2 =  [UIColor colorWithHue:hue2 saturation:[color2 saturation] brightness:brightness2 alpha:1.0];
    
    
    UIImage *gradientImage = [self imageGradientWithSize:cell.bounds.size color1:color1 color2:color2];
    UIView *normalBackgroundView = [[UIImageView alloc] initWithImage:gradientImage];
    normalBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    normalBackgroundView.contentMode = UIViewContentModeScaleAspectFill;
    normalBackgroundView.backgroundColor = [self darkColor];
    // NSLog( @"CACHE WRITE %@", cacheKey );
    [cachedCellBackgroundImageViews setObject:normalBackgroundView forKey:cacheKey];
    return normalBackgroundView;
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.imageView.backgroundColor = [self darkColor];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
    // COLORIZE CELL
    // cell.textLabel.textColor = [self textLabelColorForCell:cell atIndexPath:indexPath withColor:[self brighterColor]];
    if( [[self appDelegate] isConfigOnForKey:kUSERDEFAULT_KEY_BOOL_USE_TIME_FOCUS defaultValue:YES] ) {
        cell.backgroundColor = [self backgroundColorForCell:cell atIndexPath:indexPath];
    }
    cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:cell.detailTextLabel.font.pointSize];    
    UIView *colorMarker = [cell.contentView viewWithTag:kCELL_ATTACHED_VIEW_TAG];
    if( colorMarker ) {
        colorMarker.center = CGPointMake(3.0, cell.contentView.center.y);
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        cell.textLabel.textColor = [self brighterColor];
        cell.detailTextLabel.textColor = [self themeColor];
        cell.textLabel.backgroundColor = kCOLOR_CLEAR;
        cell.detailTextLabel.backgroundColor = kCOLOR_CLEAR;
        cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:cell.detailTextLabel.font.pointSize];
        UIView *backgroundView = [[[UIView alloc] initWithFrame:CGRectNull] autorelease];
        backgroundView.backgroundColor = [self backgroundColor];
        cell.backgroundView = backgroundView;
        UIImage *gradientImage = [self imageGradientWithSize:cell.bounds.size color1:[self themeColor] color2:[self darkerColor]];
        UIView *selectedBackgroundView = [[[UIImageView alloc] initWithImage:gradientImage] autorelease];
        selectedBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        selectedBackgroundView.backgroundColor = [self darkColor];
        // cell.selectedBackgroundView = selectedBackgroundView;
        cell.selectedBackgroundView = selectedBackgroundView;
        /*
        UIButton *favButton = [UIButton buttonWithType:UIButtonTypeCustom];
        favButton.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
        [favButton setImage:[UIImage imageNamed:@"favourites.png"] forState:UIControlStateNormal];
        [favButton addTarget:self action:@selector(actionButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
         */
        cell.accessoryView = nil;
    }
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.imageView.image = nil;
    cell.backgroundView = nil;
    cell.textLabel.textColor = [self brighterColor];
    cell.detailTextLabel.textColor = [self themeColor];
    UIView *oldView = [cell.contentView viewWithTag:kCELL_ATTACHED_VIEW_TAG];
    if( oldView ) {
        [oldView removeFromSuperview];
    }
    // Configure the cell...
    NSString *sectionKey = [sectionKeys objectAtIndex:indexPath.section];
    NSArray *sectionItems = [sectionArrays objectForKey:sectionKey];

    if( [sectionKey containsString:@"day"] ) {
        Event *currentEvent = nil;
        if( isSearching ) {
            currentEvent = [searchItemsFiltered objectAtIndex:indexPath.row];
        }
        else {
            currentEvent = (Event*)[sectionItems objectAtIndex:indexPath.row];
        }
        // NSLog( @"EVENT: %@", currentEvent );
        cell.textLabel.text = [NSString stringWithFormat:@"%@ %@",[currentEvent.start placeHolderWhenEmpty:@"<start>"], [currentEvent.title placeHolderWhenEmpty:@"<title>"]];
        NSString *subTitleString = [NSString placeHolder:@"" forEmptyString:currentEvent.itemSubtitle];
        BOOL hasSubTitle = [subTitleString length] > 0;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@%@%@",[NSString placeHolder:@"" forEmptyString:currentEvent.itemLocation], hasSubTitle ? @": " : @"" ,subTitleString];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        // CHECK FAVOURITE
        cell.accessoryView = [currentEvent isFavourite] ? [ColoredAccessoryView checkmarkViewWithColor:[self themeColor]] : [ColoredAccessoryView disclosureIndicatorViewWithColor:[self themeColor]];
            
        // ADD TRACK INFO
        UIColor *trackColor = [[self conference] colorForTrack:currentEvent.track];
        // trackColor = [UIColor greenColor];
        UIView *colorMarker = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 6.0, 44.0)];
        colorMarker.tag = kCELL_ATTACHED_VIEW_TAG;
        colorMarker.backgroundColor = trackColor;
        colorMarker.opaque = NO;
        [cell.contentView addSubview:colorMarker];
        
        if( DEBUG ) {
            NSLog( @"indexPathSource = %i/%i (items: %i)", indexPathMedian.section, indexPathMedian.row, [self tableView:self.tableView numberOfRowsInSection:indexPathMedian.section] );
            NSLog( @"indexPathtarget = %i/%i (items: %i)", indexPath.section, indexPath.row, [self tableView:self.tableView numberOfRowsInSection:indexPath.section] );
            NSLog( @"rowDistanceForIndexPath = %i\n", [self rowDistanceForIndexPath:indexPath fromIndexPath:indexPathMedian] );
        }
    }
    else if( [sectionKey isEqualToString:@"links"] ) {
        Link *currentLink = (Link*)[sectionItems objectAtIndex:indexPath.row];
        cell.textLabel.text = [NSString placeHolder:@"" forEmptyString:currentLink.title];
        cell.detailTextLabel.text = [NSString placeHolder:@"" forEmptyString:currentLink.href];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    else if( [sectionKey isEqualToString:@"persons"] ) {
        Person *currentPerson = (Person*)[sectionItems objectAtIndex:indexPath.row];
        cell.textLabel.text = [NSString placeHolder:@"" forEmptyString:currentPerson.personName];
        cell.detailTextLabel.text = [NSString placeHolder:@"" forEmptyString:currentPerson.personIdKey];
        cell.imageView.image = [currentPerson cachedImage];
        /*
        UIImageView *personImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 40.0, 40.0)];
        personImageView.backgroundColor = [self darkColor];
        personImageView.image = [currentPerson cachedImage];
        personImageView.contentMode = UIViewContentModeScaleAspectFill;
        personImageView.layer.cornerRadius = 7.0;
        personImageView.layer.masksToBounds = YES;
        personImageView.layer.borderColor = [[self darkerColor] colorWithAlphaComponent:0.3].CGColor;
        personImageView.layer.borderWidth = 1.0;
        cell.accessoryView = personImageView;
         */
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    
    return cell;
}

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
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *sectionKey = [sectionKeys objectAtIndex:indexPath.section];
    NSArray *sectionItems = [sectionArrays objectForKey:sectionKey];

    if( isSearching ) {
        EventDetailViewController *detailViewController = [[EventDetailViewController alloc] initWithNibName:@"EventDetailViewController" bundle:nil];
        Event *currentEvent = [searchItemsFiltered objectAtIndex:indexPath.row];
        Day *currentDay = currentEvent.day;
        detailViewController.day = currentDay;
        detailViewController.event = currentEvent;
        [self.navigationController pushViewController:detailViewController animated:YES];
        [detailViewController release];
    }
    else {
        if( [sectionKey containsString:@"day"] ) {
            EventDetailViewController *detailViewController = [[EventDetailViewController alloc] initWithNibName:@"EventDetailViewController" bundle:nil];
            NSArray *days = [[self conference] days];
            Day *currentDay = [days objectAtIndex:indexPath.section];
            Event *currentEvent = [currentDay.eventsSorted objectAtIndex:indexPath.row];
            detailViewController.day = currentDay;
            detailViewController.event = currentEvent;
            [self.navigationController pushViewController:detailViewController animated:YES];
            [detailViewController release];
        } else if ( [sectionKey isEqualToString:@"links"] ) {
            Link *currentLink = (Link*)[sectionItems objectAtIndex:indexPath.row];
            if( currentLink.href ) {
                NSURL *linkUrl = [NSURL URLWithString:[currentLink.href httpUrlString]];
                [self loadSimpleWebViewWithURL:linkUrl shouldScaleToFit:YES];
            }
        } else if ( [sectionKey isEqualToString:@"persons"] ) {
            Person *currentPerson = (Person*)[sectionItems objectAtIndex:indexPath.row];
            if( currentPerson.websiteHref ) {
                NSURL *linkUrl = [NSURL URLWithString:[currentPerson.websiteHref httpUrlString]];
                [self loadSimpleWebViewWithURL:linkUrl shouldScaleToFit:YES];
            }
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }
}

#pragma mark - UISearchBarDelegate

- (NSArray*) allSearchableItems {
    // ATTN: NEEDS TO BE OVERRIDDEN IN SUBCLASS TO HAVE SEARCH WORKING
    return [[self conference] allEvents];
}

@end
