//
//  SBAPermissionsManager.h
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
 
#import "SBAPermissionsManager.h"
#import <BridgeAppSDK/BridgeAppSDK-Swift.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

SBAPermissionTypeIdentifier const SBAPermissionTypeIdentifierHealthKit = @"healthKit";
SBAPermissionTypeIdentifier const SBAPermissionTypeIdentifierLocation = @"location";
SBAPermissionTypeIdentifier const SBAPermissionTypeIdentifierNotifications = @"notifications";
SBAPermissionTypeIdentifier const SBAPermissionTypeIdentifierCoremotion = @"coremotion";
SBAPermissionTypeIdentifier const SBAPermissionTypeIdentifierMicrophone = @"microphone";
SBAPermissionTypeIdentifier const SBAPermissionTypeIdentifierCamera = @"camera";
SBAPermissionTypeIdentifier const SBAPermissionTypeIdentifierPhotoLibrary = @"photoLibrary";


static NSString * const SBAPermissionsManagerErrorDomain = @"SBAPermissionsManagerErrorDomain";

@interface SBAPermissionsManager () <CLLocationManagerDelegate>

@property (nonatomic, readwrite) HKHealthStore * healthStore;
@property (nonatomic, readwrite) CLLocationManager *locationManager;
@property (nonatomic, readwrite) CMMotionActivityManager *motionActivityManager;

@property (nonatomic) BOOL requestedLocationAlways;
@property (nonatomic, copy) SBAPermissionsBlock locationCompletionBlock;

@property (nonatomic, copy) SBAPermissionsBlock notificationsCompletionBlock;

@end


@implementation SBAPermissionsManager

+ (instancetype)sharedManager {
    static id __instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __instance = [[self alloc] init];
    });
    return __instance;
}

#pragma mark - memory allocation

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _locationManager.delegate = nil;
}

- (SBAPermissionObjectTypeFactory *)permissionsTypeFactory {
    if (_permissionsTypeFactory == nil) {
        _permissionsTypeFactory = [SBAPermissionObjectTypeFactory new];
    }
    return _permissionsTypeFactory;
}

- (HKHealthStore *)healthStore {
    if (_healthStore == nil && [HKHealthStore isHealthDataAvailable]) {
        _healthStore = [[HKHealthStore alloc] init];
    }
    return _healthStore;
}

- (CLLocationManager *)locationManager {
    if (_locationManager == nil) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    return _locationManager;
}

- (CMMotionActivityManager *)motionActivityManager {
    if (_motionActivityManager == nil) {
        _motionActivityManager = [[CMMotionActivityManager alloc] init];
    }
    return _motionActivityManager;
}

- (NSArray<SBAPermissionObjectType *> *)defaultPermissionTypes {
    if (_defaultPermissionTypes == nil) {
        id appDelegate = [[UIApplication sharedApplication] delegate];
        if ([appDelegate conformsToProtocol:@protocol(SBAAppInfoDelegate)]) {
            // First look for the permissions in the bridge info
            NSArray *items = [[appDelegate bridgeInfo] permissionTypeItems];
            if ((items == nil) && [appDelegate respondsToSelector:@selector(requiredPermissions)]) {
                // If not found, check the required permissions
                items = [self typeIdentifiersForPermissionCode:[appDelegate requiredPermissions]];
            }
            _defaultPermissionTypes = [self.permissionsTypeFactory permissionTypesFor:items];
        }
    }
    return _defaultPermissionTypes;
}

#pragma mark - deprecated type conversion

- (NSArray *)typeIdentifierMap {
    static NSArray *_typeIdentifierMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _typeIdentifierMap = @[SBAPermissionTypeIdentifierHealthKit,
                               SBAPermissionTypeIdentifierLocation,
                               SBAPermissionTypeIdentifierNotifications,
                               SBAPermissionTypeIdentifierCoremotion,
                               SBAPermissionTypeIdentifierMicrophone,
                               SBAPermissionTypeIdentifierCamera,
                               SBAPermissionTypeIdentifierPhotoLibrary];
    });
    return _typeIdentifierMap;
}

- (NSUInteger)permissionCodeForTypeIdentifier:(NSString *)typeIdentifier {
    NSUInteger idx = [[self typeIdentifierMap] indexOfObject:typeIdentifier];
    if (idx == NSNotFound) { return 0; }
    return 1 << (idx + 1);
}

- (NSArray<NSString *> *)typeIdentifiersForPermissionCode:(NSUInteger)permissionCode {
    NSMutableArray *identifiers = [NSMutableArray new];
    [[self typeIdentifierMap] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSUInteger code = 1 << (idx + 1);
        if ((permissionCode | code) == code) {
            [identifiers addObject:obj];
        }
    }];
    return [identifiers copy];
}

- (SBAPermissionTypeIdentifier)typeIdentifierForPermissionCode:(NSUInteger)permissionCode {
    return (SBAPermissionTypeIdentifier)[[self typeIdentifiersForPermissionCode:permissionCode] firstObject];
}

- (SBAPermissionsType)permissionsTypeForPermissionObjectTypes:(NSArray<SBAPermissionObjectType *> *)objectTypes {
    NSUInteger permissionCode = 0;
    for (SBAPermissionObjectType *obj in objectTypes) {
        permissionCode = permissionCode | [self permissionCodeForTypeIdentifier:obj.identifier];
    }
    return permissionCode;
}

#pragma mark - public deprecated methods

- (SBAPermissionTypeIdentifier _Nullable)typeIdentifierForForType:(SBAPermissionsType)type {
    return [self typeIdentifierForPermissionCode:type];
}

- (NSArray<SBAPermissionObjectType *> *)typeObjectsForForType:(SBAPermissionsType)type {
    NSArray *typeIdentifiers = [self typeIdentifiersForPermissionCode:type];
    return [self.permissionsTypeFactory permissionTypesFor:typeIdentifiers];
}

- (BOOL)isPermissionsGrantedForType:(SBAPermissionsType)type {
    return [self _isPermissionsGrantedForType:[self typeIdentifierForPermissionCode:type]];
}

- (void)requestPermissionForType:(SBAPermissionsType)type
                  withCompletion:(SBAPermissionsBlock)completion {
    [self _requestPermissionForTypeIdentifier:[self typeIdentifierForPermissionCode:type]
                               withCompletion:completion];
}

#pragma mark - public methods

- (BOOL)isPermissionGrantedForType:(SBAPermissionObjectType *)permissionType {
    
    // Location checks for either always or whenInUse
    if ([permissionType isKindOfClass:[SBALocationPermissionObjectType class]]) {
        SBALocationPermissionObjectType *locationType = (SBALocationPermissionObjectType *)permissionType;
        return [self isPermissionsGrantedForLocation:locationType.always];
    }
    
    // Healthkit uses custom handler
    if ([permissionType isKindOfClass:[SBAHealthKitPermissionObjectType class]]) {
        return [self isPermissionGrantedForHealthKitPermissionType:(SBAHealthKitPermissionObjectType *)permissionType];
    }
    
    // Finally look to the base method
    return [self _isPermissionsGrantedForType:permissionType.identifier];
}

// These cases can be defined using the original Yes/No implementation
- (BOOL)_isPermissionsGrantedForType:(SBAPermissionTypeIdentifier)type {
    if ([type isEqualToString:SBAPermissionTypeIdentifierLocation]) {
        return [self isPermissionsGrantedForLocation:NO];
    }
    else if ([type isEqualToString:SBAPermissionTypeIdentifierNotifications]) {
        return [self isPermissionsGrantedForLocalNotifications];
    }
    else if ([type isEqualToString:SBAPermissionTypeIdentifierCoremotion]) {
        return [self isPermissionsGrantedForCoreMotion];
    }
    else if ([type isEqualToString:SBAPermissionTypeIdentifierMicrophone]) {
        return [self isPermissionsGrantedForMicrophone];
    }
    else if ([type isEqualToString:SBAPermissionTypeIdentifierCamera]) {
        return [self isPermissionsGrantedForCamera];
    }
    else if ([type isEqualToString:SBAPermissionTypeIdentifierPhotoLibrary]) {
        return [self isPermissionsGrantedForPhotoLibrary];
    }
    else {
        return NO;
    }
}

- (void)requestPermissionForType:(SBAPermissionObjectType *)permissionType
                      completion:(SBAPermissionsBlock _Nullable)completion {
    
    // Location
    if ([permissionType isKindOfClass:[SBALocationPermissionObjectType class]]) {
        SBALocationPermissionObjectType *locationType = (SBALocationPermissionObjectType *)permissionType;
        [self requestForPermissionLocation:locationType.always completion:completion];
    }
    
    // Notification
    else if ([permissionType isKindOfClass:[SBANotificationPermissionObjectType class]]) {
        [self requestForPermissionForNotifications:(SBANotificationPermissionObjectType *)permissionType withCompletion:completion];
    }
    
    // Healthkit
    else if ([permissionType isKindOfClass:[SBAHealthKitPermissionObjectType class]]) {
        SBAHealthKitPermissionObjectType *healthKitType = (SBAHealthKitPermissionObjectType *)permissionType;
        [self requestHealthKitPermissionsForReadingTypes:healthKitType.readTypes writingTypes:healthKitType.writeTypes completion:completion];
    }
    
    // Finally look to the base method
    else {
        [self _requestPermissionForTypeIdentifier:permissionType.identifier
                                   withCompletion:completion];
    }
}

- (void)_requestPermissionForTypeIdentifier:(SBAPermissionTypeIdentifier)type withCompletion:(SBAPermissionsBlock)completion {
    if ([type isEqualToString:SBAPermissionTypeIdentifierLocation]) {
        [self requestForPermissionLocation:YES completion:completion];
    }
    else if ([type isEqualToString:SBAPermissionTypeIdentifierNotifications]) {
        [self requestForPermissionForNotifications:nil withCompletion:completion];
    }
    else if ([type isEqualToString:SBAPermissionTypeIdentifierCoremotion]) {
        [self requestForPermissionCoreMotionWithCompletion:completion];
    }
    else if ([type isEqualToString:SBAPermissionTypeIdentifierMicrophone]) {
        [self requestForPermissionMicrophoneWithCompletion:completion];
    }
    else if ([type isEqualToString:SBAPermissionTypeIdentifierCamera]) {
        [self requestForPermissionCameraWithCompletion:completion];
    }
    else if ([type isEqualToString:SBAPermissionTypeIdentifierPhotoLibrary]) {
        [self requestForPermissionPhotoLibraryWithCompletion:completion];
    }
    else {
        NSAssert(false, @"Unsupported Permission type");
        if (completion) {
            completion(NO, [SBAPermissionsManager permissionDeniedErrorForTypeIdentifier:type]);
        }
    }
}

+ (NSError *)permissionDeniedErrorForTypeIdentifier:(SBAPermissionTypeIdentifier)type
{
    NSString *message = nil;
    
    if ([type isEqualToString:SBAPermissionTypeIdentifierLocation]) {
        message = [Localization localizedString:@"SBA_LOCATION_PERMISSIONS_ERROR"];
    }
    else if ([type isEqualToString:SBAPermissionTypeIdentifierNotifications]) {
        message = [Localization localizedString:@"SBA_REMINDER_PERMISSIONS_ERROR"];
    }
    else if ([type isEqualToString:SBAPermissionTypeIdentifierCoremotion]) {
        message = [Localization localizedString:@"SBA_COREMOTION_PERMISSIONS_ERROR"];
    }
    else if ([type isEqualToString:SBAPermissionTypeIdentifierMicrophone]) {
        message = [Localization localizedString:@"SBA_MICROPHONE_PERMISSIONS_ERROR"];
    }
    else if ([type isEqualToString:SBAPermissionTypeIdentifierCamera]) {
        message = [Localization localizedString:@"SBA_CAMERA_PERMISSIONS_ERROR"];
    }
    else if ([type isEqualToString:SBAPermissionTypeIdentifierPhotoLibrary]) {
        message = [Localization localizedString:@"SBA_PHOTOLIBRARY_PERMISSIONS_ERROR"];
    }
    else {
        message = [Localization localizedString:@"SBA_GENERAL_PERMISSIONS_ERROR"];
    }

    NSError *error = [NSError errorWithDomain:SBAPermissionsManagerErrorDomain
                                         code:SBAPermissionsErrorCodeAccessDenied
                                     userInfo:@{NSLocalizedDescriptionKey: message}];
    return error;
}


//---------------------------------------------------------------
#pragma mark - Location
//---------------------------------------------------------------

- (BOOL)isPermissionsGrantedForLocation:(BOOL)always {
#if TARGET_IPHONE_SIMULATOR
    return YES;
#else
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    return [self isPermissionsGrantedForLocation:always status:status];
#endif
}

- (BOOL)isPermissionsGrantedForLocation:(BOOL)always status:(CLAuthorizationStatus)status {
    if (always) {
        return  (status == kCLAuthorizationStatusAuthorizedAlways);
    }
    else {
        return  (status == kCLAuthorizationStatusAuthorizedWhenInUse) ||
                (status == kCLAuthorizationStatusAuthorizedAlways);
    }
}

- (void)requestForPermissionLocation:(BOOL)always
                          completion:(SBAPermissionsBlock)completion {

    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];

    if (status == kCLAuthorizationStatusNotDetermined) {
        // Add pointer to the completion block and fire off request to accept permission
        self.locationCompletionBlock = completion;
        self.requestedLocationAlways = always;
        if (always) {
            [self.locationManager requestAlwaysAuthorization];
        }
        else {
            [self.locationManager requestWhenInUseAuthorization];
        }
    }
    else {
        [self handleLocationPermission:always responseStatus:status completion:completion];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *) __unused error {
    [manager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *) __unused manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status != kCLAuthorizationStatusNotDetermined) {
        [self.locationManager stopUpdatingLocation];
        [self handleLocationPermission:self.requestedLocationAlways responseStatus:status completion:self.locationCompletionBlock];
        self.locationCompletionBlock = nil;
    }
}

- (void)handleLocationPermission:(BOOL)always
                  responseStatus:(CLAuthorizationStatus)responseStatus
                      completion:(SBAPermissionsBlock)completion {
    if (completion) {
        BOOL granted = [self isPermissionsGrantedForLocation:always status:responseStatus];
        NSError *error = granted ? nil : [SBAPermissionsManager permissionDeniedErrorForTypeIdentifier:SBAPermissionTypeIdentifierLocation];
        completion(granted, error);
    }
}

//---------------------------------------------------------------
#pragma mark - notifications
//---------------------------------------------------------------

- (BOOL)isPermissionsGrantedForLocalNotifications {
    return [[UIApplication sharedApplication] currentUserNotificationSettings].types != 0;
}

- (void)requestForPermissionForNotifications:(SBANotificationPermissionObjectType *)permissionType withCompletion:(SBAPermissionsBlock)completion {
    
    if ([[UIApplication sharedApplication] currentUserNotificationSettings].types == UIUserNotificationTypeNone) {
        self.notificationsCompletionBlock = completion;

        UIUserNotificationType notificationTypes = (permissionType != nil) ? permissionType.notificationTypes : UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:notificationTypes
                                                                                 categories:permissionType.categories];

        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        // In the case of notifications, callbacks are used to fire the completion block.
        // Callbacks are delivered to appDidRegisterForRemoteNotifications:
    }
    else {
        // Request previously granted
        [self handleFinishedRegisterForLocalNotifications:YES
                                          completion:completion];
    }
}

- (void)appDidRegisterForNotifications: (UIUserNotificationSettings *)settings {
    BOOL granted = (settings.types != UIUserNotificationTypeNone);
    [self handleFinishedRegisterForLocalNotifications:granted
                                      completion:self.notificationsCompletionBlock];
}

- (void)handleFinishedRegisterForLocalNotifications:(BOOL)granted
                                         completion:(SBAPermissionsBlock)completion {
    NSError *error = granted ? nil : [SBAPermissionsManager permissionDeniedErrorForTypeIdentifier:SBAPermissionTypeIdentifierNotifications];
    if (completion) {
        completion(granted, error);
    }
    self.notificationsCompletionBlock = nil;
}


//---------------------------------------------------------------
#pragma mark - CoreMotion
//---------------------------------------------------------------

- (BOOL)isPermissionsGrantedForCoreMotion {
    return [CMSensorRecorder isAuthorizedForRecording];
}

- (void)requestForPermissionCoreMotionWithCompletion:(SBAPermissionsBlock)completion {
    // Usually this method is called on another thread, but since we are searching
    // within same date to same date, it will return immediately, so put it on the main thread
    [self.motionActivityManager queryActivityStartingFromDate:[NSDate date] toDate:[NSDate date] toQueue:[NSOperationQueue mainQueue] withHandler:^(NSArray * __unused activities, NSError *error) {
        if (completion) {
            BOOL success = (error == nil);
            NSError *err = success ? nil : [SBAPermissionsManager permissionDeniedErrorForTypeIdentifier:SBAPermissionTypeIdentifierCoremotion];
            completion(success, err);
        }
    }];
}


//---------------------------------------------------------------
#pragma mark - Microphone
//---------------------------------------------------------------

- (BOOL)isPermissionsGrantedForMicrophone {
    AVAudioSessionRecordPermission permission = [[AVAudioSession sharedInstance] recordPermission];
    return (permission == AVAudioSessionRecordPermissionGranted);
}

- (void)requestForPermissionMicrophoneWithCompletion:(SBAPermissionsBlock)completion {
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (completion) {
            NSError *error = granted ? nil : [SBAPermissionsManager permissionDeniedErrorForTypeIdentifier:SBAPermissionTypeIdentifierMicrophone];
            completion(granted, error);
        }
    }];
}


//---------------------------------------------------------------
#pragma mark - Camera
//---------------------------------------------------------------
    
- (BOOL)isPermissionsGrantedForCamera {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    return status == AVAuthorizationStatusAuthorized;
}

- (void)requestForPermissionCameraWithCompletion:(SBAPermissionsBlock)completion {
    
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if (completion) {
            NSError *err = granted ? nil : [SBAPermissionsManager permissionDeniedErrorForTypeIdentifier:SBAPermissionTypeIdentifierCamera];
            completion(granted, err);
        }
    }];
}

//---------------------------------------------------------------
#pragma mark - PhotoLibrary
//---------------------------------------------------------------

- (BOOL)isPermissionsGrantedForPhotoLibrary {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    return (status == PHAuthorizationStatusAuthorized);
}

- (void)requestForPermissionPhotoLibraryWithCompletion:(SBAPermissionsBlock)completion {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        BOOL isAuthorized = (status == PHAuthorizationStatusAuthorized);
        NSError *error = isAuthorized ? nil : [SBAPermissionsManager permissionDeniedErrorForTypeIdentifier:SBAPermissionTypeIdentifierPhotoLibrary];
        if (completion) {
            completion(isAuthorized, error);
        }
    }];
}

//---------------------------------------------------------------
#pragma mark - HealthKit
//---------------------------------------------------------------

- (BOOL)isPermissionGrantedForHealthKitPermissionType:(SBAHealthKitPermissionObjectType *)permissionType {
    for (HKObjectType *hkType in permissionType.readTypes) {
        if ([hkType isKindOfClass:[HKSampleType class]]) {
            // Intentionally nest the if statement. This is an early exit from the for-loop if it fail.
            if (![self isPermissionsGrantedForHealthKitType:(HKSampleType*)hkType]) {
                return NO;
            }
        }
        else if ([hkType isKindOfClass:[HKCharacteristicType class]]) {
            // Characteristics are readonly so permission granted can only be checked by attempting to
            // get the value and check if there is an error (either b/c the permission was denied or
            // because it was never granted
            NSError *error = nil;
            if ([[hkType identifier] isEqualToString:HKCharacteristicTypeIdentifierDateOfBirth]) {
                [self.healthStore dateOfBirthWithError:&error];
            }
            else if ([[hkType identifier] isEqualToString:HKCharacteristicTypeIdentifierBloodType]) {
                [self.healthStore bloodTypeWithError:&error];
            }
            else if ([[hkType identifier] isEqualToString:HKCharacteristicTypeIdentifierBiologicalSex]) {
                [self.healthStore biologicalSexWithError:&error];
            }
            else if ([[hkType identifier] isEqualToString:HKCharacteristicTypeIdentifierFitzpatrickSkinType]) {
                [self.healthStore fitzpatrickSkinTypeWithError:&error];
            }
            else if ([[hkType identifier] isEqualToString:HKCharacteristicTypeIdentifierWheelchairUse]) {
                [self.healthStore wheelchairUseWithError:&error];
            }
            if (error != nil) {
                return NO;
            }
        }
        else {
            // If this is *not* a recognized type for writing or a characteristic, then we have no
            // means of determining if the value is available using this method. This does *not*
            // mean that this permission has not been granted, but that the default behavior is for
            // the app to fallback to showing the permissions step and attempt to get permission
            // before continuing.
            return NO;
        }
    }
    return YES;
}

- (BOOL)isPermissionsGrantedForHealthKitType:(HKSampleType *)type {
    HKAuthorizationStatus status = [self.healthStore authorizationStatusForType:type];
    return (status == HKAuthorizationStatusSharingAuthorized);
}

- (void)requestHealthKitPermissionsForReadingTypes:(nullable NSSet<HKObjectType *> *)typesToRead
                                      writingTypes:(nullable NSSet<HKSampleType *> *)typesToWrite
                                        completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    
    if ([HKHealthStore isHealthDataAvailable]) {
        [self.healthStore requestAuthorizationToShareTypes:typesToWrite readTypes:typesToRead completion:^(BOOL success, NSError *error) {
            if (completion) {
                completion(success, error);
            }
        }];
    }
    else {
        completion(NO, nil);
    }
}

@end
