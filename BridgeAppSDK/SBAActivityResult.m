//
//  SBAActivityResult.m
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
#import "SBAActivityResult.h"

@implementation SBAActivityResult

// Include the schema revision in the user info dictionary
- (NSNumber *)schemaRevision {
    return self.userInfo[NSStringFromSelector(@selector(schemaRevision))] ?: @(1);
}

- (void)setSchemaRevision:(NSNumber *)schemaRevision {
    NSParameterAssert(schemaRevision);
    if (schemaRevision == nil) { return; }
    NSMutableDictionary *userInfo = [self.userInfo mutableCopy] ?: [NSMutableDictionary new];
    userInfo[NSStringFromSelector(@selector(schemaRevision))] = schemaRevision;
    self.userInfo = userInfo;
}

// Schema identifier is a drop through to identifier
- (NSString *)schemaIdentifier {
    return self.identifier;
}

- (void)setSchemaIdentifier:(NSString *)schemaIdentifier {
    NSParameterAssert(schemaIdentifier);
    if (schemaIdentifier == nil) { return; }
    self.identifier = schemaIdentifier;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _schedule = [aDecoder decodeObjectOfClass:[SBBScheduledActivity class] forKey:NSStringFromSelector(@selector(schedule))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.schedule forKey:NSStringFromSelector(@selector(schedule))];
}

#pragma mark - NSCopy

- (id)copyWithZone:(NSZone *)zone {
    SBAActivityResult *copy = [super copyWithZone:zone];
    copy.schedule = self.schedule;
    return copy;
}

#pragma mark - Equality

- (BOOL)isEqual:(id)object {
    typeof(self) castObject = object;
    return [super isEqual:object] &&
    [self.schedule isEqual:castObject.schedule];
}

- (NSUInteger)hash {
    return [super hash] | [self.schedule hash];
}

@end
