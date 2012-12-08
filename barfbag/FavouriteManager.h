//
//  FavouriteManager.h
//  barfbag
//
//  Created by Lincoln Six Echo on 08.12.12.
//  Copyright (c) 2012 appdoctors. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FavouriteManager : NSObject {

    NSMutableArray *favouriteCacheArray;
    BOOL hasPendingChangesFavouriteCache;
    NSTimer *timerSaveFavourites;

}

@property( nonatomic, assign ) BOOL hasPendingChangesFavouriteCache;
@property( nonatomic, retain ) NSMutableArray *favouriteCacheArray;
@property( nonatomic, retain ) NSTimer *timerSaveFavourites;

+ (FavouriteManager*) sharedManager;

- (NSArray*) favouritedItemsOfType:(FavouriteItemType)itemType;
- (BOOL) hasStoredFavouriteForId:(NSNumber*)itemId forItemType:(FavouriteItemType)itemType;
- (BOOL) favouriteAddedId:(NSNumber*)itemId forItemType:(FavouriteItemType)itemType name:(NSString*)favouriteName;
- (BOOL) favouriteRemovedId:(NSNumber*)itemId forItemType:(FavouriteItemType)itemType;

@end