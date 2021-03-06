//
//  JSONArtist.m
//

#import "JSONWorkshops.h"
#import "JSONProperties.h"
#import "JSONWorkshop.h"

@implementation JSONWorkshops

@synthesize objId;
@synthesize properties;
@synthesize workshopItems;

+ (NSDictionary*) objectMapping {
    NSDictionary *mappingDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"objId", @"id",
                                 [JSONWorkshop mappingWithKey:@"workshopItems" mapping:[JSONWorkshop objectMapping]],@"items",
                                 nil];
    return mappingDict;
}

//                                  [JSONProperties mappingWithKey:@"properties" mapping:[JSONProperties objectMapping]],@"properties",


- (NSString*) description {
    NSMutableString *string = [NSMutableString string];
    [string appendFormat:@"id = %@\n", objId];
    [string appendFormat:@"properties = %@\n", properties];
    [string appendFormat:@"workshopItems = %@\n", workshopItems];
    return string;
}

- (NSArray*) workshopItemsSorted {
    NSMutableArray *itemsUnsorted = [NSMutableArray arrayWithArray:workshopItems];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"itemSortNumberDateTime" ascending:TRUE];
    [itemsUnsorted sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    NSArray *itemsSorted = [NSArray arrayWithArray:itemsUnsorted];
    return itemsSorted;
}

@end
