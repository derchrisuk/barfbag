//
//  JSONAssembly.m
//

#import "JSONAssembly.h"
#import "FavouriteManager.h"
#import "MasterConfig.h"

@implementation JSONAssembly

@synthesize objId;
@synthesize label;
@synthesize descriptionText;
@synthesize lectureSeats;
@synthesize memberSeats;
@synthesize webLinks;
@synthesize bringsStuff;
@synthesize plannedWorkshops;
@synthesize planningNotes;
@synthesize nameOfLocation;
@synthesize orgaContact;
@synthesize locationOpenedAt;
@synthesize personOrganizing;

+ (NSDictionary*) objectMapping {
    NSDictionary *mappingDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"objId", @"id",
                                 @"label", @"label",
                                 @"descriptionText", @"description",
                                 @"lectureSeats", @"lecture_seats",
                                 @"memberSeats", @"member_seats",
                                 @"webLinks", @"weblink",
                                 @"bringsStuff", @"brings_stuff",
                                 @"plannedWorkshops", @"planned_workshops",
                                 @"planningNotes", @"planning_notes",
                                 @"nameOfLocation", @"name_of_location",
                                 @"orgaContact", @"orga_contact",
                                 @"locationOpenedAt", @"location_opened_at",
                                 @"personOrganizing", @"person_organizing",
nil];
    return mappingDict;
}

/**
 * I don't get it why this fucking semantic wiki stuff throws out arrays for single item properties
 * this is such a huge data structure fuckup... *throwingmyheadagainstthewall* *facepalm*
 * It is also completely in the blue which timezone these dates are in... this will get very funny...
 */

- (id) singlePropertyFromObject:(id)arrayOrObject {
    if( [arrayOrObject isKindOfClass:[NSArray class]] || [arrayOrObject isKindOfClass:[NSMutableArray class]] ) {
        return [arrayOrObject lastObject];
    }
    else {
        return arrayOrObject;
    }
}

- (NSArray*) arrayForPropertyWithName:(NSString*)propertyName {
    SEL selector = NSSelectorFromString(propertyName);
    id value = [self performSelector:selector];
    if( [value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSMutableArray class]] ) {
        return value;
    }
    else if( value ) {
        return [NSArray arrayWithObject:value];
    }
    else {
        return [NSArray array];
    }
}

- (NSString*) abstract {
    return [self singlePropertyFromObject:descriptionText];
}

- (NSInteger) numLectureSeats {
    NSNumber *seats = [self singlePropertyFromObject:lectureSeats];
    ;
    if( seats ) {
        return [seats integerValue];
    }
    else {
        return 0;
    }
}

- (NSInteger) numMemberSeats {
    NSNumber *seats = [self singlePropertyFromObject:memberSeats];
    ;
    if( seats ) {
        return [seats integerValue];
    }
    else {
        return 0;
    }
}

- (NSString*) websiteHref {
    NSString* urlString = [[MasterConfig sharedConfiguration] urlStringWikiPageWithPath:[self itemTitle]];
    return urlString;
}

- (NSString*) stringRepresentationMail {
    return [NSString stringWithFormat:@"<b>%@</b><br>%@", [NSString placeHolder:@"(Kein Titel)" forEmptyString:[self itemTitle]], [NSString placeHolder:@"(Kein Ort)" forEmptyString:[self itemLocation]]];
}

- (NSString*) stringRepresentationTwitter {
    NSString *linkString = [self websiteHref];
    return [NSString stringWithFormat:@"\"%@\" %@", [NSString placeHolder:@"(Kein Titel)" forEmptyString:[self itemTitle]], [NSString placeHolder:@"" forEmptyString:linkString]];
}

- (NSString*) description {
    NSMutableString *string = [NSMutableString string];
    [string appendFormat:@"id = %@\n", objId];
    [string appendFormat:@"label = %@\n", label];
    [string appendFormat:@"descriptionText = %@\n", descriptionText];
    [string appendFormat:@"lectureSeats = %@\n", lectureSeats];
    [string appendFormat:@"webLinks = %@\n", webLinks];
    [string appendFormat:@"bringsStuff = %@\n", bringsStuff];
    [string appendFormat:@"plannedWorkshops = %@\n", plannedWorkshops];
    [string appendFormat:@"planningNotes = %@\n", planningNotes];
    [string appendFormat:@"nameOfLocation = %@\n", nameOfLocation];
    [string appendFormat:@"orgaContact = %@\n", orgaContact];
    [string appendFormat:@"locationOpenedAt = %@\n", locationOpenedAt];
    [string appendFormat:@"personOrganizing = %@\n", personOrganizing];
    return string;
}

// SEARCHABLE ITEM

- (NSString*) itemId {
    return [[self singlePropertyFromObject:label] normalizedString];
}

- (NSString*) itemTitle {
    return [self singlePropertyFromObject:label];
}

- (NSString*) itemSubtitle {
    return [self singlePropertyFromObject:plannedWorkshops];
}
- (NSString*) itemAbstract {
    return [self singlePropertyFromObject:descriptionText];
}

- (NSString*) itemPerson {
    NSMutableString *personsString = [NSMutableString string];
    if( orgaContact ) [personsString appendString:orgaContact];
    if( personOrganizing ) {
        if( [personsString length] > 0 ) {
            [personsString appendString:@","];
        }
        [personsString appendString:personOrganizing];
    }
    return personsString;
}

 // NO DATES AVAILABLE FOR ASSEMBLIES
- (NSDate*) itemDateStart {
    return nil;
}

- (NSDate*) itemDateEnd {
    return nil;
}

- (BOOL) isFavourite {
    return [[FavouriteManager sharedManager] hasStoredFavourite:self];
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

- (NSString*) itemLocation {
    return [self singlePropertyFromObject:nameOfLocation];
}

@end
