//
//  SearchableItem.m
//  barfbag
//
//  Created by Lincoln Six Echo on 14.12.12.
//  Copyright (c) 2012 appdoctors. All rights reserved.
//

#import "SearchableItem.h"

@implementation SearchableItem


- (NSString*) itemId {
    return nil;
}

- (NSString*) itemTitle {
    return nil;
}

- (NSString*) itemSubtitle {
    return nil;
}

- (NSString*) itemAbstract {
    return nil;
}

- (NSString*) itemPerson {
    return nil;
}

- (NSDate*) itemDateStart {
    return nil;
}

- (NSDate*) itemDateEnd {
    return nil;
}

- (BOOL) isFavourite {
    return NO;
}

- (NSNumber*) itemSortNumberDateTime {
    return nil;
}

- (NSInteger) itemMinutesFromNow {
    return NSIntegerMax;
}

- (NSInteger) itemMinutesTilStart {
    return NSIntegerMax;
}

- (NSTimeInterval) itemSecondsTilStart {
    return CGFLOAT_MAX;
}

- (NSComparisonResult)itemContinuousTimeCompare:(SearchableItem*)item {
    return NSOrderedSame;
}

- (NSString*) itemLocation {
    return nil;
}

@end
