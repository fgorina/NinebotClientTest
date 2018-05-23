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
    var originalURL : URL?
    var picker : UIDocumentPickerViewController?
    
    override init(){
        super.init()
    }
 
    
    override class var activityCategory : UIActivityCategory{
        return UIActivityCategory.share
    }
    
    override var activityType: UIActivityType? {
        return UIActivityType("es.gorina.exportFile")
    }
    
    override var activityTitle : String? {
        return "Export"
    }
    
    override var activityImage : UIImage? {
        return UIImage(named: "icon_ipad")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        
        if activityItems.count != 2{
            return false
        }
        for obj in activityItems{
            if obj is URL {
                return true
            }
        }
        return false
    }

    override func prepare(withActivityItems activityItems: [Any]) {
        for obj in activityItems{
            if obj is URL {
                self.originalURL = obj as? URL
            }else if obj is String {
                self.name = obj as? String
            }
        }
        
    }
    
    override var activityViewController : UIViewController? {
        
        if let url = self.originalURL{
            let controller = UIDocumentPickerViewController(url: url, in: UIDocumentPickerMode.exportToService)
            
            controller.delegate = self
            
            return controller
        }
        
        return nil
    }
    
    override func activityDidFinish(_ completed: Bool) {
        
        super.activityDidFinish(completed)
        self.picker = nil
    }
    
    //MARK: UIDocumentPickerDelegate
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        
        DispatchQueue.main.async { () -> Void in
            self.activityDidFinish(true)
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        
        self.picker = nil
    }
}
