//
//  SBAConsentSignature.swift
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

import Foundation

@objc
public protocol SBAConsentSignatureWrapper : class {
    
    /**
     * Age verification stored with consent
     */
    var signatureBirthdate: Date? { get set }
    
    /**
     * Name used to sign consent
     */
    var signatureName: String? { get set }
    
    /**
     * UIImage representation of consent signature
     */
    var signatureImage: UIImage?  { get set }
    
    /**
     * Date of consent
     */
    var signatureDate: Date? { get set }
}

@objc
open class SBAConsentSignature: NSObject, SBAConsentSignatureWrapper, NSSecureCoding, NSCopying {
    
    open let identifier: String
    open var signatureBirthdate: Date?
    open var signatureName: String?
    open var signatureImage: UIImage?
    open var signatureDate: Date?
    
    public required init(identifier: String) {
        self.identifier = identifier
        super.init()
    }
    
    public convenience init(signature: ORKConsentSignature) {
        self.init(identifier: signature.identifier)
        // Assume given name first
        if signature.givenName != nil || signature.familyName != nil {
            let firstName = signature.givenName ?? ""
            let lastName = signature.familyName ?? ""
            self.signatureName = (firstName + " " + lastName).trim()
        }
        self.signatureImage = signature.signatureImage
        if let dateString = signature.signatureDate, let dateFormat = signature.signatureDateFormatString {
            let formatter = DateFormatter()
            formatter.dateFormat = dateFormat
            self.signatureDate = formatter.date(from: dateString)
        }
    }
    
    // MARK: NSSecureCoding
    
    public static var supportsSecureCoding : Bool {
        return true
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        guard let identifier = aDecoder.decodeObject(forKey: "identifier") as? String else {
            return nil
        }
        self.init(identifier: identifier)
        self.signatureBirthdate = aDecoder.decodeObject(forKey: "signatureBirthdate") as? Date
        self.signatureName = aDecoder.decodeObject(forKey: "signatureName") as? String
        self.signatureImage = aDecoder.decodeObject(forKey: "signatureImage") as? UIImage
        self.signatureDate = aDecoder.decodeObject(forKey: "signatureDate") as? Date
    }
    
    open func encode(with aCoder: NSCoder) {
        aCoder.encode(self.identifier, forKey: "identifier")
        aCoder.encode(self.signatureBirthdate, forKey: "signatureBirthdate")
        aCoder.encode(self.signatureName, forKey: "signatureName")
        aCoder.encode(self.signatureImage, forKey: "signatureImage")
        aCoder.encode(self.signatureDate, forKey: "signatureDate")
    }
    
    // MARK: Copying
    
    open func copy(with zone: NSZone?) -> Any {
        let copy = type(of: self).init(identifier: self.identifier)
        copy.signatureBirthdate = self.signatureBirthdate
        copy.signatureName = self.signatureName
        copy.signatureImage = self.signatureImage
        copy.signatureDate = self.signatureDate
        return copy
    }
    
    // MARK: Equality
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let obj = object as? SBAConsentSignature else {
            return false
        }
        return  SBAObjectEquality(self.identifier, obj.identifier) &&
                SBAObjectEquality(self.signatureBirthdate, obj.signatureBirthdate) &&
                SBAObjectEquality(self.signatureName, obj.signatureName) &&
                SBAObjectEquality(self.signatureImage, obj.signatureImage) &&
                SBAObjectEquality(self.signatureDate, obj.signatureDate)
    }
    
    open override var hash: Int {
        return self.identifier.hash ^
            SBAObjectHash(self.signatureBirthdate) ^
            SBAObjectHash(self.signatureName) ^
            SBAObjectHash(self.signatureImage) ^
            SBAObjectHash(self.signatureDate)
    }
    
}

