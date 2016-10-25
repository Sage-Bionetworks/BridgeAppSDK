//
//  LearnTableViewController.swift
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

import UIKit
import BridgeAppSDK

class LearnTableViewController: UITableViewController {
    
    fileprivate let learnInfo : SBALearnInfo = SBALearnInfoPList()
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return learnInfo.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "LearnCell", for: indexPath)
        guard let item = learnInfo.item(at: indexPath) else { return cell }
        
        cell.textLabel?.text = item.learnTitle
        cell.imageView?.image = item.learnIconImage
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let cell = sender as? UITableViewCell,
            let indexPath = self.tableView.indexPath(for: cell),
            let learnItem = learnInfo.item(at: indexPath),
            let vc = segue.destination as? SBAWebViewController {
            // Hook up the title and the url for the webview controller
            vc.title = learnItem.learnTitle
            vc.url = learnItem.learnURL
        }
    }
    
}

class LearnMoreTableViewCell: UITableViewCell {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let imageView = self.imageView {
            let originalCenter = imageView.center
            let originalFrame = imageView.frame
            let size: CGFloat = 27
            imageView.frame = CGRect(x: originalFrame.origin.x, y: originalCenter.y - size/2.0, width: size, height: size)
            
            var originalTextFrame = self.textLabel!.frame
            originalTextFrame.origin.x = imageView.frame.maxX + 16
            self.textLabel?.frame = originalTextFrame
        }
    }
    
}
