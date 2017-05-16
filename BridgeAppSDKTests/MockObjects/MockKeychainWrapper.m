//
//  MockKeychainWrapper.m
//  BridgeAppSDK
//
//  Copyright © 2017 Sage Bionetworks. All rights reserved.
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

#import "MockKeychainWrapper.h"

@implementation MockKeychainWrapper

- (instancetype)init {
    self = [super init];
    if (self) {
        _keychain = [NSMutableDictionary new];
        _errorMap = [NSMutableDictionary new];
    }
    return self;
}

- (BOOL)setObject:(id<NSSecureCoding>)object forKey:(NSString *)key error:(NSError * _Nullable *)error {
    NSError *err = _errorMap[key];
    if (err) {
        *error = err;
        return false;
    }
    else {
        _keychain[key] = object;
        return true;
    }
}

- (id<NSSecureCoding>)objectForKey:(NSString *)key error:(NSError * _Nullable *)error {
    NSError *err = _errorMap[key];
    if (err) {
        *error = err;
        return nil;
    }
    else {
        return _keychain[key];
    }
}

- (BOOL)removeObjectForKey:(NSString *)key error:(NSError * _Nullable *)error {
    NSError *err = _errorMap[key];
    if (err) {
        *error = err;
        return false;
    }
    else {
        [_keychain removeObjectForKey:key];
        return true;
    }
}

- (BOOL)resetKeychainWithError:(NSError * _Nullable *)error {
    self.reset_called = YES;
    [_keychain removeAllObjects];
    return true;
}

@end
