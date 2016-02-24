//
//  PickerActivity.swift
//  NinebotClientTest
//
//  Created by Francisco Gorina Vanrell on 11/2/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//( at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.

import UIKit

class PickerActivity: UIActivity, UIDocumentPickerDelegate {

    var name : String?
    var originalURL : NSURL?
    var picker : UIDocumentPickerViewController?
    
    override init(){
        super.init()
    }
 
    
    override class func activityCategory() -> UIActivityCategory{
        return UIActivityCategory.Share
    }
    
    
    override func activityType() -> String? {
        return "es.gorina.exportFile"
    }
    
    override func activityTitle() -> String? {
        return "Export"
    }
    
    override func activityImage() -> UIImage? {
        return UIImage(named: "icon_ipad")
    }
    
    override func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool {
        
        if activityItems.count != 2{
            return false
        }
        for obj in activityItems{
            if obj.isKindOfClass(NSURL){
                return true
            }
        }
        return false
    }

    override func prepareWithActivityItems(activityItems: [AnyObject]) {
        for obj in activityItems{
            if obj.isKindOfClass(NSURL){
                self.originalURL = obj as? NSURL
            }else if obj.isKindOfClass(NSString){
                self.name = obj as? String
            }
        }
        
    }
    
    override func activityViewController() -> UIViewController? {
        
        if let url = self.originalURL{
            let controller = UIDocumentPickerViewController(URL: url, inMode: UIDocumentPickerMode.ExportToService)
            
            controller.delegate = self
            
            return controller
        }
        
        return nil
    }
    
    override func activityDidFinish(completed: Bool) {
        
        super.activityDidFinish(completed)
        self.picker = nil
    }
    
    //MARK: UIDocumentPickerDelegate
    
    func documentPicker(controller: UIDocumentPickerViewController, didPickDocumentAtURL url: NSURL) {
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.activityDidFinish(true)
        }
    }
    
    func documentPickerWasCancelled(controller: UIDocumentPickerViewController) {
        
        self.picker = nil
    }
}
