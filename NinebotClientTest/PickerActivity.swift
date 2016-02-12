//
//  PickerActivity.swift
//  NinebotClientTest
//
//  Created by Francisco Gorina Vanrell on 11/2/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

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
