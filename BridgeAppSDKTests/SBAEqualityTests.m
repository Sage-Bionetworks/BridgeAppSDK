//
//  SBAEqualityTests.m
//  BridgeAppSDK
//
//  Copyright (c) 2015, Apple Inc.
//  Copyright (c) 2016 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import <stdio.h>
#import <stdlib.h>
#import <ResearchKit/ResearchKit.h>
#import <ResearchKit/ResearchKit_private.h>
#import <CoreMotion/CoreMotion.h>
#import <HealthKit/HealthKit.h>
#import <MapKit/MapKit.h>

@interface ClassProperty : NSObject

@property (nonatomic, copy) NSString *propertyName;
@property (nonatomic, strong) Class propertyClass;
@property (nonatomic) BOOL isPrimitiveType;

- (instancetype)initWithObjcProperty:(objc_property_t)property;

@end

@implementation ClassProperty

- (instancetype)initWithObjcProperty:(objc_property_t)property {
    
    self = [super init];
    if (self) {
        const char *name = property_getName(property);
        self.propertyName = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
        
        const char *type = property_getAttributes(property);
        NSString *typeString = [NSString stringWithUTF8String:type];
        NSArray *attributes = [typeString componentsSeparatedByString:@","];
        NSString *typeAttribute = attributes[0];
        
        _isPrimitiveType = YES;
        if ([typeAttribute hasPrefix:@"T@"]) {
            _isPrimitiveType = NO;
            Class typeClass = nil;
            if (typeAttribute.length > 4) {
                NSString *typeClassName = [typeAttribute substringWithRange:NSMakeRange(3, typeAttribute.length-4)];  //turns @"NSDate" into NSDate
                typeClass = NSClassFromString(typeClassName);
            } else {
                typeClass = [NSObject class];
            }
            self.propertyClass = typeClass;
            
        } else if ([@[@"Ti", @"Tq", @"TI", @"TQ"] containsObject:typeAttribute]) {
            self.propertyClass = [NSNumber class];
        }
    }
    return self;
}

@end

// Classes that do not have an
#define MAKE_TEST_INIT(class, block) \
@interface class (SBAEqualityTests) \
- (instancetype)test_init; \
@end \
\
@implementation class (SBAEqualityTests) \
- (instancetype)test_init { \
return block(); \
} \
@end \

// List of all classes with known special-case initializers b/c the [self init] is marked as unavailable
MAKE_TEST_INIT(ORKStepNavigationRule, ^{return [super init];});
MAKE_TEST_INIT(ORKSkipStepNavigationRule, ^{return [super init];});
MAKE_TEST_INIT(ORKAnswerFormat, ^{return [super init];});
MAKE_TEST_INIT(ORKLoginStep, ^{return [self initWithIdentifier:[NSUUID UUID].UUIDString title:@"title" text:@"text" loginViewControllerClass:NSClassFromString(@"ORKLoginStepViewController") ];});
MAKE_TEST_INIT(ORKVerificationStep, ^{return [self initWithIdentifier:[NSUUID UUID].UUIDString text:@"text" verificationViewControllerClass:NSClassFromString(@"ORKVerificationStepViewController") ];});
MAKE_TEST_INIT(ORKStep, ^{return [self initWithIdentifier:[NSUUID UUID].UUIDString];});
MAKE_TEST_INIT(ORKReviewStep, ^{return [[self class] standaloneReviewStepWithIdentifier:[NSUUID UUID].UUIDString steps:@[] resultSource:[ORKTaskResult new]];});
MAKE_TEST_INIT(ORKOrderedTask, ^{return [self initWithIdentifier:@"test1" steps:nil];});
MAKE_TEST_INIT(ORKImageChoice, ^{return [super init];});
MAKE_TEST_INIT(ORKTextChoice, ^{return [super init];});
MAKE_TEST_INIT(ORKPredicateStepNavigationRule, ^{return [self initWithResultPredicates:@[[ORKResultPredicate predicateForBooleanQuestionResultWithResultSelector:[ORKResultSelector selectorWithResultIdentifier:@"test"] expectedAnswer:YES]] destinationStepIdentifiers:@[@"test2"]];});
MAKE_TEST_INIT(ORKResultSelector, ^{return [self initWithResultIdentifier:@"resultIdentifier"];});
MAKE_TEST_INIT(ORKRecorderConfiguration, ^{return [self initWithIdentifier:@"testRecorder"];});
MAKE_TEST_INIT(ORKAccelerometerRecorderConfiguration, ^{return [super initWithIdentifier:@"testRecorder"];});
MAKE_TEST_INIT(ORKHealthQuantityTypeRecorderConfiguration, ^{ return [super initWithIdentifier:@"testRecorder"];});
MAKE_TEST_INIT(ORKAudioRecorderConfiguration, ^{ return [super initWithIdentifier:@"testRecorder"];});
MAKE_TEST_INIT(ORKDeviceMotionRecorderConfiguration, ^{ return [super initWithIdentifier:@"testRecorder"];});
MAKE_TEST_INIT(ORKLocation, (^{
    ORKLocation *location = [self initWithCoordinate:CLLocationCoordinate2DMake(2.0, 3.0) region:[[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(2.0, 3.0) radius:100.0 identifier:@"identifier"] userInput:@"addressString" addressDictionary:@{@"city":@"city", @"street":@"street"}];
    return location;
}));




@interface SBAEqualityTests : XCTestCase <NSKeyedUnarchiverDelegate>

@end

@implementation SBAEqualityTests



- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)todo_testORKSecureCoding {
    
    NSArray<Class> *classesWithSecureCoding = [self classesWithSecureCoding];
    
    // Predefined exception
    NSArray *knownNotSerializedProperties = @[];
    NSArray *propertyExclusionList = [self propertyExclusionList];
    
    // Test Each class
    for (Class aClass in classesWithSecureCoding) {
        id instance = [self instanceForClass:aClass];
        
        // Find all properties of this class
        NSMutableArray *propertyNames = [NSMutableArray array];
        unsigned int count;
        objc_property_t *props = class_copyPropertyList(aClass, &count);
        for (int i = 0; i < count; i++) {
            objc_property_t property = props[i];
            ClassProperty *p = [[ClassProperty alloc] initWithObjcProperty:property];
            
            if ([propertyExclusionList containsObject: p.propertyName] == NO) {
                if (p.isPrimitiveType == NO) {
                    [self applySomeValueToClassProperty:p forObject:instance index:0 forEqualityCheck:YES];
                }
                [propertyNames addObject:p.propertyName];
            }
        }
        
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:instance];
        XCTAssertNotNil(data);
        
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        unarchiver.requiresSecureCoding = YES;
        unarchiver.delegate = self;
        id newInstance = [unarchiver decodeObjectOfClasses:[NSSet setWithArray:classesWithSecureCoding] forKey:NSKeyedArchiveRootObjectKey];
        
        // Set of classes we can check for equality. Would like to get rid of this once we implement
        NSSet *checkableClasses = [NSSet setWithObjects:[NSNumber class], [NSString class], [NSDictionary class], [NSURL class], nil];
        // All properties should have matching fields in dictionary (allow predefined exceptions)
        for (NSString *pName in propertyNames) {
            id newValue = [newInstance valueForKey:pName];
            id oldValue = [instance valueForKey:pName];
            
            if (newValue == nil) {
                NSString *notSerializedProperty = [NSString stringWithFormat:@"%@.%@", NSStringFromClass(aClass), pName];
                BOOL success = [knownNotSerializedProperties containsObject:notSerializedProperty];
                if (!success) {
                    XCTAssertTrue(success, "Unexpected notSerializedProperty = %@", notSerializedProperty);
                }
            }
            for (Class c in checkableClasses) {
                if ([oldValue isKindOfClass:c]) {
                    if ([newValue isKindOfClass:[NSURL class]] || [oldValue isKindOfClass:[NSURL class]]) {
                        if (![[newValue absoluteString] isEqualToString:[oldValue absoluteString]]) {
                            XCTAssertTrue([[newValue absoluteString] isEqualToString:[oldValue absoluteString]]);
                        }
                    } else {
                        XCTAssertEqualObjects(newValue, oldValue);
                    }
                    break;
                }
            }
        }
        
        // NSData and NSDateComponents in your properties mess up the following test.
        // NSDateComponents - seems to be due to serializing and then deserializing introducing a leap month:no flag.
        if (aClass == [NSDateComponents class] || aClass == [ORKDateQuestionResult class] || aClass == [ORKDateAnswerFormat class] || aClass == [ORKDataResult class]) {
            continue;
        }
        
        NSData *data2 = [NSKeyedArchiver archivedDataWithRootObject:newInstance];
        
        NSKeyedUnarchiver *unarchiver2 = [[NSKeyedUnarchiver alloc] initForReadingWithData:data2];
        unarchiver2.requiresSecureCoding = YES;
        unarchiver2.delegate = self;
        id newInstance2 = [unarchiver2 decodeObjectOfClasses:[NSSet setWithArray:classesWithSecureCoding] forKey:NSKeyedArchiveRootObjectKey];
        NSData *data3 = [NSKeyedArchiver archivedDataWithRootObject:newInstance2];
        
        if (![data isEqualToData:data2]) { // allow breakpointing
            if (![aClass isSubclassOfClass:[ORKConsentSection class]]) {
                // ORKConsentSection mis-matches, but it is still "equal" because
                // the net custom animation URL is a match.
                XCTAssertEqualObjects(data, data2, @"data mismatch for %@", NSStringFromClass(aClass));
            }
        }
        if (![data2 isEqualToData:data3]) { // allow breakpointing
            XCTAssertEqualObjects(data2, data3, @"data mismatch for %@", NSStringFromClass(aClass));
        }
        
        if (![newInstance isEqual:instance]) {
            XCTAssertEqualObjects(newInstance, instance, @"equality mismatch for %@", NSStringFromClass(aClass));
        }
        if (![newInstance2 isEqual:instance]) {
            XCTAssertEqualObjects(newInstance2, instance, @"equality mismatch for %@", NSStringFromClass(aClass));
        }
    }
}

- (void)todo_testCopying {
    
    NSArray<Class> *classesWithCopying = [self classesWithCopying];
    
    // Predefined exception
    NSArray *propertyExclusionList = [self propertyExclusionList];
    
    // Test Each class
    for (Class aClass in classesWithCopying) {
        id instance = [self instanceForClass:aClass];
        
        // Find all properties of this class
        NSMutableArray *propertyNames = [NSMutableArray array];
        unsigned int count;
        objc_property_t *props = class_copyPropertyList(aClass, &count);
        for (int i = 0; i < count; i++) {
            objc_property_t property = props[i];
            ClassProperty *p = [[ClassProperty alloc] initWithObjcProperty:property];
            
            if ([propertyExclusionList containsObject: p.propertyName] == NO) {
                if (p.isPrimitiveType == NO) {
                    if ([instance valueForKey:p.propertyName] == nil) {
                        [self applySomeValueToClassProperty:p forObject:instance index:0 forEqualityCheck:YES];
                    }
                }
                [propertyNames addObject:p.propertyName];
            }
        }
        
        id copiedInstance = [instance copy];
        if (![copiedInstance isEqual:instance]) {
            XCTAssertEqualObjects(copiedInstance, instance);
        }
        
        for (int i = 0; i < count; i++) {
            objc_property_t property = props[i];
            ClassProperty *p = [[ClassProperty alloc] initWithObjcProperty:property];
            
            if ([propertyExclusionList containsObject: p.propertyName] == NO) {
                if (p.isPrimitiveType == NO) {
                    copiedInstance = [instance copy];
                    if (instance == copiedInstance) {
                        // Totally immutable object.
                        continue;
                    }
                    if ([self applySomeValueToClassProperty:p forObject:copiedInstance index:1 forEqualityCheck:YES])
                    {
                        if ([copiedInstance isEqual:instance]) {
                            XCTAssertNotEqualObjects(copiedInstance, instance);
                        }
                        [self applySomeValueToClassProperty:p forObject:copiedInstance index:0 forEqualityCheck:YES];
                        XCTAssertEqualObjects(copiedInstance, instance);
                        
                        [copiedInstance setValue:nil forKey:p.propertyName];
                        XCTAssertNotEqualObjects(copiedInstance, instance);
                    }
                }
            }
        }
    }
}



#pragma mark - NSKeyedUnarchiverDelegate

- (Class)unarchiver:(NSKeyedUnarchiver *)unarchiver cannotDecodeObjectOfClassName:(NSString *)name originalClasses:(NSArray *)classNames {
    NSLog(@"Cannot decode object with class: %@ (original classes: %@)", name, classNames);
    return nil;
}

#pragma mark - helper methods

- (NSArray <NSString *> *)propertyExclusionList {
    return @[@"superclass",
            @"description",
            @"descriptionSuffix",
            @"debugDescription",
            @"hash",
            @"requestedHealthKitTypesForReading",
            @"requestedHealthKitTypesForWriting",
            @"healthKitUnit",
            @"firstResult",
            ];
}

- (NSArray<Class> *)classesWithSecureCoding {
    
    NSArray *classesExcluded = @[]; // classes not intended to be serialized standalone
    NSMutableArray *stringsForClassesExcluded = [NSMutableArray array];
    for (Class c in classesExcluded) {
        [stringsForClassesExcluded addObject:NSStringFromClass(c)];
    }
    
    // Find all classes that conform to NSSecureCoding
    NSMutableArray<Class> *classesWithSecureCoding = [NSMutableArray new];
    int numClasses = objc_getClassList(NULL, 0);
    Class classes[numClasses];
    numClasses = objc_getClassList(classes, numClasses);
    for (int index = 0; index < numClasses; index++) {
        Class aClass = classes[index];
        if ([stringsForClassesExcluded containsObject:NSStringFromClass(aClass)]) {
            continue;
        }
        
        if ([NSStringFromClass(aClass) hasPrefix:@"SBA"] &&
            [aClass conformsToProtocol:@protocol(NSSecureCoding)]) {
            [classesWithSecureCoding addObject:aClass];
        }
    }
    
    return [classesWithSecureCoding copy];
}

- (NSArray <Class> *)classesWithCopying {
    
    NSArray *classesExcluded = @[]; // classes not intended to be serialized standalone
    NSMutableArray *stringsForClassesExcluded = [NSMutableArray new];
    for (Class c in classesExcluded) {
        [stringsForClassesExcluded addObject:NSStringFromClass(c)];
    }
    
    // Find all classes that conform to NSSecureCoding
    NSMutableArray *classesWithCopying = [NSMutableArray new];
    int numClasses = objc_getClassList(NULL, 0);
    Class classes[numClasses];
    numClasses = objc_getClassList(classes, numClasses);
    for (int index = 0; index < numClasses; index++) {
        Class aClass = classes[index];
        if ([stringsForClassesExcluded containsObject:NSStringFromClass(aClass)]) {
            continue;
        }
        
        if ([NSStringFromClass(aClass) hasPrefix:@"ORK"] &&
            [aClass conformsToProtocol:@protocol(NSCopying)]) {
            
            [classesWithCopying addObject:aClass];
        }
    }
    return classesWithCopying;
}

- (id)instanceForClass:(Class)c {
    if ([c instancesRespondToSelector:@selector(test_init)]) {
        return [[c alloc] test_init];
    } else {
        return [[c alloc] init];
    }
}

- (BOOL)applySomeValueToClassProperty:(ClassProperty *)p forObject:(id)instance index:(NSInteger)index forEqualityCheck:(BOOL)equality {
    // return YES if the index makes it distinct
    
    Class aClass = [instance class];
    // Assign value to object type property
    if (p.propertyClass == [NSObject class] && (aClass == [ORKTextChoice class]|| aClass == [ORKImageChoice class] || (aClass == [ORKQuestionResult class])))
    {
        // Map NSObject to string, since it's used where either a string or a number is acceptable
        [instance setValue:index?@"blah":@"test" forKey:p.propertyName];
    } else if (p.propertyClass == [NSNumber class]) {
        [instance setValue:index?@(12):@(123) forKey:p.propertyName];
    } else if (p.propertyClass == [NSURL class]) {
        NSURL *url = [NSURL fileURLWithFileSystemRepresentation:[index?@"xxx":@"blah" UTF8String]  isDirectory:NO relativeToURL:[NSURL fileURLWithPath:NSHomeDirectory()]];
        [instance setValue:url forKey:p.propertyName];
        [[NSFileManager defaultManager] createFileAtPath:[url path] contents:nil attributes:nil];
    } else if (p.propertyClass == [HKUnit class]) {
        [instance setValue:[HKUnit unitFromString:index?@"g":@"kg"] forKey:p.propertyName];
    } else if (p.propertyClass == [HKQuantityType class]) {
        [instance setValue:[HKQuantityType quantityTypeForIdentifier:index?HKQuantityTypeIdentifierActiveEnergyBurned : HKQuantityTypeIdentifierBodyMass] forKey:p.propertyName];
    } else if (p.propertyClass == [HKCharacteristicType class]) {
        [instance setValue:[HKCharacteristicType characteristicTypeForIdentifier:index?HKCharacteristicTypeIdentifierBiologicalSex: HKCharacteristicTypeIdentifierBloodType] forKey:p.propertyName];
    } else if (p.propertyClass == [NSCalendar class]) {
        [instance setValue:index?[NSCalendar calendarWithIdentifier:NSCalendarIdentifierChinese]:[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian] forKey:p.propertyName];
    } else if (p.propertyClass == [NSTimeZone class]) {
        [instance setValue:index?[NSTimeZone timeZoneWithName:[NSTimeZone knownTimeZoneNames][0]]:[NSTimeZone timeZoneForSecondsFromGMT:1000] forKey:p.propertyName];
    } else if (p.propertyClass == [ORKLocation class]) {
        [instance setValue:[[ORKLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(index? 2.0 : 3.0, 3.0) region:[[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(2.0, 3.0) radius:100.0 identifier:@"identifier"] userInput:@"addressString" addressDictionary:@{@"city":@"city", @"street":@"street"}] forKey:p.propertyName];
    } else if (p.propertyClass == [CLCircularRegion class]) {
        [instance setValue:[[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(index? 2.0 : 3.0, 3.0) radius:100.0 identifier:@"identifier"] forKey:p.propertyName];
    } else if (p.propertyClass == [NSPredicate class]) {
        [instance setValue:[NSPredicate predicateWithFormat:index?@"1 == 1":@"1 == 2"] forKey:p.propertyName];
    } else if (equality && (p.propertyClass == [UIImage class])) {
        // do nothing - meaningless for the equality check
        return NO;
    } else if (aClass == [ORKReviewStep class] && [p.propertyName isEqualToString:@"resultSource"]) {
        [instance setValue:[[ORKTaskResult alloc] initWithIdentifier:@"blah"] forKey:p.propertyName];
        return NO;
    } else {
        id instanceForChild = [self instanceForClass:p.propertyClass];
        [instance setValue:instanceForChild forKey:p.propertyName];
        return NO;
    }
    return YES;
}



@end
