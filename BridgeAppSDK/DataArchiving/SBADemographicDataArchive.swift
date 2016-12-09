//
//  SBADemographicDataArchive.swift
//  BridgeAppSDK
//
// Copyright © 2016 Sage Bionetworks. All rights reserved.
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

import UIKit

// ===== WORK IN PROGRESS =====
// TODO: WIP syoung 12/06/2016 This is unfinished but b/c it is wrapped up with the profile
// and onboarding stuff, I don't want the branch lingering unmerged. This is ported from
// AppCore and is still untested and *not* intended for production use.
// ============================

public class SBADemographicDataArchive: SBADataArchive, SBASharedInfoController {
    
    lazy open var sharedAppDelegate: SBAAppInfoDelegate = {
        return UIApplication.shared.delegate as! SBAAppInfoDelegate
    }()
    
    fileprivate var metadata = [String: AnyObject]()
    
    fileprivate let kTaskIdentifierKey              = "NonIdentifiableDemographicsTask"
    fileprivate let kFileIdentifierKey              = "NonIdentifiableDemographics.json"
    fileprivate let kPatientInformationKey          = "item"
    fileprivate let kSchemaRevisionKey              = "schemaRevision"
    
    public init?(dataConverter: SBADemographicDataConverter, demographicIdentifiers: [SBADemographicDataIdentifier], jsonValidationMapping: [String: NSPredicate]? = nil) {
        let identifier = kTaskIdentifierKey
        super.init(reference: identifier, jsonValidationMapping: jsonValidationMapping)
        
        // set the revision (if available)
        if let schemaRevision = sharedBridgeInfo.schemaReferenceWithIdentifier(identifier)?.schemaRevision {
            self.setArchiveInfoObject(schemaRevision, forKey: kSchemaRevisionKey)
        }
        
        // Loop through each identifier and convert
        var demographics: [String: Any] = [ kPatientInformationKey: kFileIdentifierKey ]
        for demographicIdentifier in demographicIdentifiers {
            if let uploadObject = dataConverter.uploadObject(for: demographicIdentifier) {
                demographics[uploadObject.key] = uploadObject.value
                if let unit = uploadObject.unit {
                    let unitKey = "\(uploadObject.key)Unit"
                    demographics[unitKey] = unit
                }
            }
            else {
                // If the response is nil then add a Null value for the key
                demographics[demographicIdentifier.rawValue] = NSNull()
            }
        }
        
        // Add to archive
        insertDictionary(intoArchive: demographics, filename: kFileIdentifierKey)
    }
}
