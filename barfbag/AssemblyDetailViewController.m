//
//  AssemblyDetailViewController.m
//  barfbag
//
//  Created by Lincoln Six Echo on 09.12.12.
//  Copyright (c) 2012 appdoctors. All rights reserved.
//

#import "AssemblyDetailViewController.h"
#import  "MasterConfig.h"

@implementation AssemblyDetailViewController

@synthesize detailHeaderViewController;
@synthesize assembly;
@synthesize sectionKeys;
@synthesize sectionArrays;
@synthesize navigationTitle;

- (void) dealloc {
    self.assembly = nil;
    self.detailHeaderViewController = nil;
    self.sectionKeys = nil;
    self.sectionArrays = nil;
    self.navigationTitle = nil;
    [super dealloc];
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction) actionMultiActionButtonTapped:(UIBarButtonItem*)item {
    [self presentActionSheetForObject:assembly fromBarButtonItem:item];
}

- (IBAction) actionOpenWikiPage:(id)sender {
    [self actionOpenInWiki:assembly.itemTitle];
}

- (void) actionOpenInWiki:(NSString*)wikiPath {
    NSString* urlString = [[MasterConfig sharedConfiguration] urlStringWikiPageWithPath:wikiPath];
    NSURL *url = [NSURL URLWithString:urlString];
    [self loadSimpleWebViewWithURL:url shouldScaleToFit:YES];
}

- (void) setupTableViewFooter {
    CGFloat width = self.tableView.frame.size.width;
    UIView *footerView = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, width, 70.0)] autorelease];
    footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    footerView.backgroundColor = [self themeColor];
    UIButton *buttonOpenWiki = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 250.0, 40.0)];
    [buttonOpenWiki addTarget:self action:@selector(actionOpenWikiPage:) forControlEvents:UIControlEventTouchUpInside];
    [footerView addSubview:buttonOpenWiki];
    [buttonOpenWiki setTitle:LOC( @"Wikiseite öffnen" ) forState:UIControlStateNormal];
    [buttonOpenWiki.titleLabel setFont:[UIFont boldSystemFontOfSize:buttonOpenWiki.titleLabel.font.pointSize]];
    [buttonOpenWiki setTitleColor:kCOLOR_WHITE forState:UIControlStateNormal];
    buttonOpenWiki.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    buttonOpenWiki.center = footerView.center;
    self.tableView.tableFooterView = footerView;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = navigationTitle;
    self.navigationItem.rightBarButtonItem = [self actionBarButtonItem];
    if( !detailHeaderViewController ) {
        self.detailHeaderViewController = [[[GenericDetailViewController alloc] initWithNibName:@"GenericDetailViewController" bundle:nil] autorelease];
    }
    self.tableView.tableHeaderView = detailHeaderViewController.view;

    detailHeaderViewController.titleLabel.text = assembly.label;
    detailHeaderViewController.subtitleLabel.text = [NSString placeHolder:@"" forEmptyString:assembly.itemSubtitle];
    detailHeaderViewController.timeStart.text = assembly.locationOpenedAt;
    detailHeaderViewController.timeDuration.text = @"";
    detailHeaderViewController.roomLabel.text = assembly.itemLocation;
    detailHeaderViewController.dateLabel.text = @"";
    detailHeaderViewController.languageLabel.text = [NSString stringWithFormat:LOC( @"%i Plätze (Members)" ), assembly.numMemberSeats];
    detailHeaderViewController.trackLabel.text = [NSString stringWithFormat:LOC( @"%i Plätze (Lecture)" ), assembly.numLectureSeats];
    detailHeaderViewController.speakerLabel.text = assembly.personOrganizing;

    [self setupTableViewFooter];
    
    // SETUP SECTION ORDER
    self.sectionKeys = [NSArray arrayWithObjects:
                        @"descriptionText",
                        @"orgaContact",
                        @"plannedWorkshops",
                        @"webLinks",
                        @"planningNotes",
                        @"bringsStuff",
                        nil];
    
    // SETUP DATA
    self.sectionArrays = [NSMutableDictionary dictionary];
    NSMutableArray *neededSectionKeys = [NSMutableArray array];
    NSArray *currentArray = nil;
    for( NSString *currentPropertyName in sectionKeys ) {
        currentArray = [assembly arrayForPropertyWithName:currentPropertyName];
        if( [currentArray count] > 0 ) {
            [neededSectionKeys addObject:currentPropertyName];
            [sectionArrays setObject:currentArray forKey:currentPropertyName];
        }
        else {
            // do nothing
        }
    }
    self.sectionKeys = [NSArray arrayWithArray:neededSectionKeys];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *sectionKey = [sectionKeys objectAtIndex:section];
    return LOC( sectionKey );
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [sectionKeys count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *sectionKey = [sectionKeys objectAtIndex:section];
    return [[sectionArrays objectForKey:sectionKey] count];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    CGFloat height20 = [[UIDevice currentDevice] isPad] ? 40.0f : 20.0f;
    return height20;
}

- (NSString*) textToDisplayForIndexPath:(NSIndexPath*)indexPath {
    NSString *sectionKey = [sectionKeys objectAtIndex:indexPath.section];
    NSString *itemString = [[sectionArrays objectForKey:sectionKey] objectAtIndex:indexPath.row];
    return [NSString placeHolder:LOC( @"Kein Eintrag" ) forEmptyString:itemString];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self textSizeNeededForString:[self textToDisplayForIndexPath:indexPath]].height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.contentView.backgroundColor = kCOLOR_BACK;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;
    // clean existing cell
    while( [cell.contentView.subviews count] > 0 ) {
        [[cell.contentView.subviews lastObject] removeFromSuperview];
    }
    CGSize textSize = [self textSizeNeededForString:[self textToDisplayForIndexPath:indexPath]];
    CGFloat offset5 = [[UIDevice currentDevice] isPad] ? 10.0f : 5.0f;
    UILabel *cellTextLabel = [self cellTextLabelWithRect:CGRectMake(offset5, 0.0, textSize.width-(2.0*offset5), textSize.height)];
    [cell.contentView addSubview:cellTextLabel];
    
    // Configure the cell...
    if( [[sectionKeys objectAtIndex:indexPath.section] isEqualToString:@"webLinks"] ) {
        cell.accessoryView = [ColoredAccessoryView disclosureIndicatorViewWithColor:[self themeColor]];
    }
    if( [[sectionKeys objectAtIndex:indexPath.section] isEqualToString:@"orgaContact"] ) {
        cell.accessoryView = [ColoredAccessoryView disclosureIndicatorViewWithColor:[self themeColor]];
    }
    cellTextLabel.text = [self textToDisplayForIndexPath:indexPath];
    return cell;
}

/*
// Configure the cell...
    NSString *sectionKey = [sectionKeys objectAtIndex:indexPath.section];
    NSString *itemString = [[sectionArrays objectForKey:sectionKey] objectAtIndex:indexPath.row];
    cell.textLabel.text = itemString;
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
    if( [[sectionKeys objectAtIndex:indexPath.section] isEqualToString:@"webLinks"] ) {
        NSLog( @"TOUCHED LINK" );
        NSURL *url = [NSURL URLWithString:[[self textToDisplayForIndexPath:indexPath] httpUrlString]];
        [self loadSimpleWebViewWithURL:url shouldScaleToFit:YES];
    }
    if( [[sectionKeys objectAtIndex:indexPath.section] isEqualToString:@"orgaContact"] ) {
        NSLog( @"TOUCHED MAILTO" );
    }
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
}

@end
