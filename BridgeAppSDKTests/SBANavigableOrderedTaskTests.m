//
//  SBANavigableOrderedTaskTests.m
//  BridgeAppSDK
//
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
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
#import <ResearchKit/ResearchKit.h>
@import BridgeAppSDK;

#import "MockORKTask.h"

@interface SBANavigableOrderedTaskTests : XCTestCase

@end

@interface MockActiveStep : ORKActiveStep
@property (nonatomic, readwrite, nullable) NSSet<HKObjectType *> *requestedHealthKitTypesForReading;
@end

@implementation SBANavigableOrderedTaskTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCreateSBANavigableOrderedTask {
    // Purpose of this test is to ensure that a swift class can be instantiated with an
    // obj-c initializer.
    SBANavigableOrderedTask *task = [[SBANavigableOrderedTask alloc] initWithIdentifier:@"Test" steps:nil];
    XCTAssertNotNil(task);
}

- (void)testNavigationWithSubtasks {
    
    // Note: This test checks basic subtask navigation forward and backward
    
    ORKOrderedTask *baseTask = [self createOrderedTaskWithIdentifier:@"base" numberOfSteps:5];
    SBASubtaskStep *subtaskStepA = [[SBASubtaskStep alloc] initWithSubtask:[self createOrderedTaskWithIdentifier:@"A" numberOfSteps:3]];
    SBASubtaskStep *subtaskStepB = [[SBASubtaskStep alloc] initWithSubtask:[self createOrderedTaskWithIdentifier:@"B" numberOfSteps:2]];
    NSMutableArray *steps = [baseTask.steps mutableCopy];
    [steps insertObject:subtaskStepA atIndex:2];
    [steps insertObject:subtaskStepB atIndex:3];
    ORKTaskResult *taskResult = [[ORKTaskResult alloc] initWithIdentifier:@"base"];
    
    SBANavigableOrderedTask *task = [[SBANavigableOrderedTask alloc] initWithIdentifier:@"base" steps:steps];
    
    NSArray *expectedOrder = @[@"step1", @"step2", @"A.step1", @"A.step2", @"A.step3", @"B.step1", @"B.step2", @"step3", @"step4", @"step5"];
    NSInteger idx = 0;
    ORKStep *step = nil;
    NSString *expectedIdentifier = nil;
    
    // -- test stepAfterStep:withResult:
    
    do {
        // Add result for the given step
        if (step) {
            ORKStepResult *stepResult = [[ORKStepResult alloc] initWithIdentifier:step.identifier];
            if (taskResult.results) {
                taskResult.results = [taskResult.results arrayByAddingObject:stepResult];
            }
            else {
                taskResult.results = @[stepResult];
            }
        }
        
        // Get the next step
        expectedIdentifier = expectedOrder[idx];
        step = [task stepAfterStep:step withResult:taskResult];

        // Check expectations
        XCTAssertNotNil(step);
        XCTAssertEqualObjects(step.identifier, expectedIdentifier);
        
    } while ((step != nil) && [step.identifier isEqualToString:expectedIdentifier] && (++idx < expectedOrder.count));
    
    // Check that exited while loop for expected reason
    XCTAssertNotNil(step);
    XCTAssertEqual(idx, expectedOrder.count);
    idx--;
    
    // -- test stepBeforeStep:withResult:
    
    while ((step != nil) && [step.identifier isEqualToString:expectedIdentifier] && (--idx >= 0)) {
        // Get the step before
        expectedIdentifier = expectedOrder[idx];
        step = [task stepBeforeStep:step withResult:taskResult];
        
        // Check expectations
        XCTAssertNotNil(step);
        XCTAssertEqualObjects(step.identifier, expectedIdentifier);
        
        // Lop off the last result
        taskResult.results = [taskResult.results subarrayWithRange:NSMakeRange(0, taskResult.results.count - 1)];
    }
    
}

- (void)testNavigationWithRules {
    
    NSMutableArray *steps = [self createStepsWithPrefix:@"step" numberOfSteps:2];
    SBAInstructionStep *stepA1 = [[SBAInstructionStep alloc] initWithIdentifier:@"stepA.1"];
    [steps addObject:stepA1];
    SBAInstructionStep *stepA2 = [[SBAInstructionStep alloc] initWithIdentifier:@"stepA.2"];
    [steps addObject:stepA2];
    ORKInstructionStep *stepB1 = [[ORKInstructionStep alloc] initWithIdentifier:@"stepB.1"];
    [steps addObject:stepB1];
    SBAInstructionStep *stepB2 = [[SBAInstructionStep alloc] initWithIdentifier:@"stepB.2"];
    [steps addObject:stepB2];
    
    stepA1.nextStepIdentifier = @"stepB.1";
    stepB2.nextStepIdentifier = @"stepA.2";
    stepA2.nextStepIdentifier = @"Exit";
    
    ORKTaskResult *taskResult = [[ORKTaskResult alloc] initWithIdentifier:@"base"];
    
    SBANavigableOrderedTask *task = [[SBANavigableOrderedTask alloc] initWithIdentifier:@"base" steps:steps];
    
    NSArray *expectedOrder = @[@"step1", @"step2", @"stepA.1", @"stepB.1", @"stepB.2", @"stepA.2"];
    NSInteger idx = 0;
    ORKStep *step = nil;
    NSString *expectedIdentifier = nil;
    
    // -- test stepAfterStep:withResult:
    
    do {
        // Add result for the given step
        if (step) {
            ORKStepResult *stepResult = [[ORKStepResult alloc] initWithIdentifier:step.identifier];
            if (taskResult.results) {
                taskResult.results = [taskResult.results arrayByAddingObject:stepResult];
            }
            else {
                taskResult.results = @[stepResult];
            }
        }
        
        // Get the next step
        expectedIdentifier = expectedOrder[idx];
        step = [task stepAfterStep:step withResult:taskResult];
        
        // ORKTaskViewController will look ahead to the next step and then look back to
        // see what navigation rules it should be using for buttons. Need to honor that flow.
        [task stepAfterStep:step withResult:taskResult];
        [task stepBeforeStep:step withResult:taskResult];
        
        // Check expectations
        XCTAssertNotNil(step);
        XCTAssertEqualObjects(step.identifier, expectedIdentifier);
        
    } while ((step != nil) && [step.identifier isEqualToString:expectedIdentifier] && (++idx < expectedOrder.count));
    
    // Check that exited while loop for expected reason
    XCTAssertNotNil(step);
    XCTAssertEqual(idx, expectedOrder.count);
    idx--;
    
    // Check that the step after the last step is nil
    ORKStep *afterLast = [task stepAfterStep:step withResult:taskResult];
    XCTAssertNil(afterLast);
    
    // -- test stepBeforeStep:withResult:
    
    while ((step != nil) && [step.identifier isEqualToString:expectedIdentifier] && (--idx >= 0)) {
        // Get the step before
        expectedIdentifier = expectedOrder[idx];
        step = [task stepBeforeStep:step withResult:taskResult];
        
        // Check expectations
        XCTAssertNotNil(step);
        XCTAssertEqualObjects(step.identifier, expectedIdentifier);
        
        // Lop off the last result
        taskResult.results = [taskResult.results subarrayWithRange:NSMakeRange(0, taskResult.results.count - 1)];
    }
    
}


- (void)testOptionalORKTaskMethodsArePassedThrough_BaseDefault {
    ORKOrderedTask *baseTask = [self createOrderedTaskWithIdentifier:@"base" numberOfSteps:5];
    MockORKTaskWithOptionals *subtask = [MockORKTaskWithOptionals new];
    SBASubtaskStep *subtaskStepA = [[SBASubtaskStep alloc] initWithSubtask:subtask];
    SBASubtaskStep *subtaskStepB = [[SBASubtaskStep alloc] initWithSubtask:[MockORKTaskWithoutOptionals new]];
    NSMutableArray *steps = [baseTask.steps mutableCopy];
    [steps insertObject:subtaskStepA atIndex:2];
    [steps insertObject:subtaskStepB atIndex:3];
    
    SBANavigableOrderedTask *task = [[SBANavigableOrderedTask alloc] initWithIdentifier:@"base" steps:steps];
    
    XCTAssertNoThrow([task validateParameters]);
    XCTAssertTrue(subtask.validateParameters_called);
    
    XCTAssertEqualObjects(task.requestedHealthKitTypesForReading, subtask.requestedHealthKitTypesForReading);
    XCTAssertEqual(task.requestedPermissions, subtask.requestedPermissions);
    XCTAssertTrue(task.providesBackgroundAudioPrompts);
}

- (void)testOptionalORKTaskMethodsArePassedThrough_BaseHasValues {
    
    // Start with base task
    ORKOrderedTask *baseTask = [self createOrderedTaskWithIdentifier:@"base" numberOfSteps:5];
    
    // Add a mock with values defined
    MockORKTaskWithOptionals *subtask = [MockORKTaskWithOptionals new];
    SBASubtaskStep *subtaskStepA = [[SBASubtaskStep alloc] initWithSubtask:subtask];
    NSMutableArray *steps = [baseTask.steps mutableCopy];
    [steps insertObject:subtaskStepA atIndex:2];
    
    // Create an active step with additional healthkit and
    MockActiveStep *activeStep = [[MockActiveStep alloc] initWithIdentifier:@"activeStep1"];
    activeStep.requestedHealthKitTypesForReading = [NSSet setWithArray:@[[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMassIndex]]];
    [steps insertObject:activeStep atIndex:4];
    
    SBANavigableOrderedTask *task = [[SBANavigableOrderedTask alloc] initWithIdentifier:@"base" steps:steps];
    
    NSSet *expectedHKTypes = [NSSet setWithArray:@[[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMassIndex],
                                                   [HKObjectType workoutType]]];
    XCTAssertEqualObjects(task.requestedHealthKitTypesForReading, expectedHKTypes);
    
    ORKPermissionMask expectedPermissions = subtask.requestedPermissions | activeStep.requestedPermissions;
    XCTAssertEqual(task.requestedPermissions, expectedPermissions);

}

#pragma mark - helper methods

- (NSMutableArray*)createStepsWithPrefix:(NSString*)prefix numberOfSteps:(NSUInteger)numberOfSteps {
    NSMutableArray *steps = [NSMutableArray new];
    for (int ii=1; ii <= numberOfSteps; ii++) {
        ORKStep *step = [[ORKInstructionStep alloc] initWithIdentifier:[NSString stringWithFormat:@"%@%@", prefix, @(ii)]];
        step.title = [NSString stringWithFormat:@"Step %@", @(ii)];
        [steps addObject:step];
    }
    return steps;
}

- (ORKOrderedTask*)createOrderedTaskWithIdentifier:(NSString*)identifier numberOfSteps:(NSUInteger)numberOfSteps {
    ORKOrderedTask *task = [[ORKOrderedTask alloc] initWithIdentifier:identifier
                                                                steps:[self createStepsWithPrefix:@"step" numberOfSteps:numberOfSteps]];
    return task;
}


@end

@implementation MockActiveStep

@synthesize requestedHealthKitTypesForReading;

- (ORKPermissionMask)requestedPermissions {
    return ORKPermissionCoreLocation | ORKPermissionCoreMotionAccelerometer;
}

@end
