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
@import BridgeAppSDK;

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
MAKE_TEST_INIT(ORKStep, ^{return [self initWithIdentifier:[NSUUID UUID].UUIDString];});
MAKE_TEST_INIT(SBADataObject, ^{return [self initWithIdentifier:[NSUUID UUID].UUIDString];});
MAKE_TEST_INIT(ORKOrderedTask, ^{return [self initWithIdentifier:@"test1" steps:nil];});
MAKE_TEST_INIT(SBAConsentSignature, ^{return [self initWithIdentifier:[NSUUID UUID].UUIDString];});
MAKE_TEST_INIT(ORKFormItem, ^{return [self initWithIdentifier:[NSUUID UUID].UUIDString text:[NSUUID UUID].UUIDString answerFormat:nil];});
MAKE_TEST_INIT(ORKQuestionResult, ^{return [self initWithIdentifier:[NSUUID UUID].UUIDString];});

@interface SBAEqualityTests : XCTestCase <NSKeyedUnarchiverDelegate>

@end

@implementation SBAEqualityTests

- (NSArray <Class> *)classesWithCopyingAndCoding {
    // Swift classes are not registered with obj-c runtime so instead just use a list
    return @[[SBATrackedDataObjectCollection class],
             [SBAMedication class],
             [SBATrackedDataObject class],
             [SBADataObject class],
             //[SBAActivityResult class], TODO: FIXME!! syoung 07/15/2016 BridgeSDK objects do not implement Equality or Encoding
             [SBAConsentSignature class],
             [SBANavigableOrderedTask class],
             [SBAInstructionStep class],
             [SBASubtaskStep class],
             [SBANavigationFormStep class],
             [SBANavigationSubtaskStep class],
             [SBANavigationFormItem class],
             [SBATrackedSelectionStep class],
             [SBATrackedDataSelectionResult class],
             [SBATrackedActivityFormStep class],
             [SBAExternalIDStep class],
             [SBAPermissionsStep class],
             ];
}

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCoding {
    
    NSArray<Class> *classesWithSecureCoding = [self classesWithCopyingAndCoding];
    
    // Test Each class
    for (Class aClass in classesWithSecureCoding) {
        
        NSLog(@"ENCODE: %@", NSStringFromClass(aClass));
        id instance = [self instanceWithPropertiesSetForClass:aClass];
        
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:instance];
        XCTAssertNotNil(data);
        
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        //unarchiver.requiresSecureCoding = YES;
        unarchiver.delegate = self;
        
        // TODO: syoung 07/15/2016 Research how to use decoding with secure coding in swift
        id unarchivedInstance = [unarchiver decodeObjectForKey:NSKeyedArchiveRootObjectKey];
        //[unarchiver decodeObjectOfClasses:[NSSet setWithArray:classesWithSecureCoding] forKey:NSKeyedArchiveRootObjectKey];
        
        XCTAssertEqual([instance hash], [unarchivedInstance hash]);
        XCTAssertEqualObjects(unarchivedInstance, instance);
        
        if (![instance isEqual:unarchivedInstance]) {
            [self checkPropertiesForClass:aClass instance:instance copiedInstance:unarchivedInstance];
        }
    }
}

- (void)testCopying {
    
    NSArray<Class> *classesWithCopying = [self classesWithCopyingAndCoding];
    
    // Test Each class
    for (Class aClass in classesWithCopying) {
        NSLog(@"COPY: %@", NSStringFromClass(aClass));
        id instance = [self instanceWithPropertiesSetForClass:aClass];
        id copiedInstance = [instance copy];
        XCTAssertEqual([instance hash], [copiedInstance hash]);
        XCTAssertEqualObjects(copiedInstance, instance);
        
        if (![instance isEqual:copiedInstance]) {
            [self checkPropertiesForClass:aClass instance:instance copiedInstance:copiedInstance];
        }
    }
}

- (void)checkPropertiesForClass:(Class)aClass instance:(id)instance copiedInstance:(id)copiedInstance {
    // Predefined exception
    NSArray *propertyExclusionList = [self propertyExclusionList];
    
    // Find all properties of this class
    unsigned int count;
    objc_property_t *props = class_copyPropertyList(aClass, &count);
    for (int i = 0; i < count; i++) {
        objc_property_t property = props[i];
        ClassProperty *p = [[ClassProperty alloc] initWithObjcProperty:property];
        
        if ([propertyExclusionList containsObject: p.propertyName] == NO) {
            if (p.isPrimitiveType == NO) {
                id instanceProp = [instance valueForKey:p.propertyName];
                id copyProp = [copiedInstance valueForKey:p.propertyName];
                if (instanceProp == nil) {
                    XCTAssertNil(copyProp, @"%@", p.propertyName);
                }
                else {
                    XCTAssertEqualObjects(instanceProp, copyProp, @"%@", p.propertyName);
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

static NSString *classPrefix = @"SBA";

- (NSArray <NSString *> *)propertyExclusionList {
    return @[@"superclass",
             @"description",
             @"debugDescription",
             @"hash",
             @"choiceDetail",
             @"requestedHealthKitTypesForReading",
             @"learnMoreHTMLContent",
             @"trackedItemIdentifier",
             @"trackedResultIdentifier",
             ];
}

- (id)instanceForClass:(Class)c {
    if ([c instancesRespondToSelector:@selector(test_init)]) {
        return [[c alloc] test_init];
    } else {
        return [[c alloc] init];
    }
}

- (id)instanceWithPropertiesSetForClass:(Class)aClass {
    
    id instance = [self instanceForClass:aClass];
    
    // Predefined exception
    NSArray *propertyExclusionList = [self propertyExclusionList];

    // Find all properties of this class
    unsigned int count;
    objc_property_t *props = class_copyPropertyList(aClass, &count);
    for (int i = 0; i < count; i++) {
        objc_property_t property = props[i];
        ClassProperty *p = [[ClassProperty alloc] initWithObjcProperty:property];
        
        // Set the value for properties that are simple to something non-nil
        if (([propertyExclusionList containsObject: p.propertyName] == NO) &&
            (p.isPrimitiveType == NO) &&
            ([instance valueForKey:p.propertyName] == nil)) {
            [self applySomeValueToClassProperty:p forObject:instance index:0];
        }
    }
    
    return instance;
}

- (BOOL)applySomeValueToClassProperty:(ClassProperty *)p forObject:(id)instance index:(NSInteger)index {
    // return YES if the index makes it distinct
    
    Class aClass = [instance class];
    // Assign value to object type property
    if (p.propertyClass == [NSObject class] && (aClass == [ORKTextChoice class]|| aClass == [ORKImageChoice class] || (aClass == [ORKQuestionResult class])))
    {
        // Map NSObject to string, since it's used where either a string or a number is acceptable
        [instance setValue:(index ? @"test1" : @"test2") forKey:p.propertyName];
    }
    else if (p.propertyClass == [NSString class]) {
        [instance setValue:(index ? @"test1" : @"test2") forKey:p.propertyName];
    }
    else if (p.propertyClass == [NSNumber class]) {
        [instance setValue:(index ? @123 : @12) forKey:p.propertyName];
    }
    else if (p.propertyClass == [NSURL class]) {
        NSURL *url = [NSURL fileURLWithFileSystemRepresentation:[(index ? @"test1" : @"test2") UTF8String] isDirectory:NO relativeToURL:[NSURL fileURLWithPath:NSHomeDirectory()]];
        [instance setValue:url forKey:p.propertyName];
        [[NSFileManager defaultManager] createFileAtPath:[url path] contents:nil attributes:nil];
    }
    else if (p.propertyClass == [NSPredicate class]) {
        [instance setValue:[NSPredicate predicateWithFormat:index ? @"1 == 2" : @"1 == 1"] forKey:p.propertyName];
    }
    else if (p.propertyClass == [UIImage class]) {
        // do nothing - meaningless for the equaliy check
        return NO;
    } else {
        id instanceForChild = [self instanceForClass:p.propertyClass];
        [instance setValue:instanceForChild forKey:p.propertyName];
        return NO;
    }
    return YES;
}



@end
