//
//  WorkshopDetailViewController.h
//  barfbag
//
//  Created by Lincoln Six Echo on 09.12.12.
//  Copyright (c) 2012 appdoctors. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GenericTableViewController.h"
#import "GenericDetailViewController.h"
#import "Workshop.h"

@interface WorkshopDetailViewController : GenericTableViewController {

    GenericDetailViewController *detailHeaderViewController;
    Workshop *workshop;
    NSArray *sectionKeys;
    NSMutableDictionary *sectionArrays;
    NSString *navigationTitle;
}

@property( nonatomic, retain ) GenericDetailViewController *detailHeaderViewController;
@property( nonatomic, retain ) Workshop *workshop;
@property( nonatomic, retain ) NSArray *sectionKeys;
@property( nonatomic, retain ) NSMutableDictionary *sectionArrays;
@property( nonatomic, retain ) NSString *navigationTitle;

@end
