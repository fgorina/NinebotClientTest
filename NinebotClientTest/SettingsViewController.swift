//
//  SettingsViewController.swift
//  NinebotClientTest
//
//  Created by Francisco Gorina Vanrell on 19/2/16.
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

class SettingsViewController: UIViewController {

    @IBOutlet weak var refreshField: UISlider!
    @IBOutlet weak var uuidLabel: UILabel!
    
    weak var delegate : ViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let dele = delegate {
            
            refreshField.value = Float(dele.timerStep)
            let store = NSUserDefaults.standardUserDefaults()
            if let uuid = store.objectForKey(BLESimulatedClient.kLast9BDeviceAccessedKey) as? String{
                uuidLabel.text = uuid 
            }
            
        }
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
       // setupNotifications()
    }
    
    override func viewWillDisappear(animated: Bool) {
     //   removeNotifications()
        super.viewWillDisappear(animated)
    }
    
//    func setupNotifications(){
//        
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
//
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillChange:", name: UIKeyboardWillChangeFrameNotification, object: nil)
//
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardDidChange:", name: UIKeyboardDidChangeFrameNotification, object: nil)
//
//    }
//    
//    func removeNotifications(){
//        NSNotificationCenter.defaultCenter().removeObserver(self)
//    }
//    
//    func keyboardWillHide(notification : NSNotification){
//        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
//            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
//            var frame = self.view.frame
//            frame.size.height = frame.size.height - keyboardSize.height
//            self.view.frame = frame
//        }
//    }
//    func keyboardWillShow(notification : NSNotification){
//        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
//            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
//            var frame = self.view.frame
//            frame.size.height = frame.size.height + keyboardSize.height
//            self.view.frame = frame
//       }
//     }
//    func keyboardWillChange(not : NSNotification){
//        
//    }
//    func keyboardDidChange(not : NSNotification){
//        
//    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func clearUUID(src : AnyObject){
        
        let store = NSUserDefaults.standardUserDefaults()
        store.removeObjectForKey(BLESimulatedClient.kLast9BDeviceAccessedKey)
        self.uuidLabel.text = ""
        
    }
    
    @IBAction func sliderValueChanged(src : AnyObject){
        
        let f = self.refreshField.value
        
        if let dele = delegate {
            dele.timerStep = Double(f)
        }
    }
    
 
}
