//
//  JSONAssembly.h
//

#import <Foundation/Foundation.h>
#import "NSObject+JTObjectMapping.h"

@interface JSONAssembly : NSObject

@property (nonatomic, retain) NSNumber *objId;
@property (nonatomic, copy) NSString *label;
@property (nonatomic, copy) NSString *descriptionText;
@property (nonatomic, retain) NSNumber *lectureSeats;
@property (nonatomic, retain) NSArray* webLinks;
@property (nonatomic, copy) NSString *bringsStuff;
@property (nonatomic, copy) NSString *plannedWorkshops;
@property (nonatomic, copy) NSString *planningNotes;
@property (nonatomic, copy) NSString *nameOfLocation;
@property (nonatomic, copy) NSString *orgaContact;
@property (nonatomic, copy) NSString *locationOpenedAt;
@property (nonatomic, copy) NSString *personOrganizing;

+ (NSDictionary*) objectMapping;
- (NSString*) description;

- (NSInteger) numLectureSeats;
- (NSString*)abstract;

@end