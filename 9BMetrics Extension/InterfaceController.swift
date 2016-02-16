//
//  InterfaceController.swift
//  9BMetrics Extension
//
//  Created by Francisco Gorina Vanrell on 11/2/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


class InterfaceController: WKInterfaceController, WCSessionDelegate {
    
    
    @IBOutlet weak  var distLabel : WKInterfaceLabel!
    @IBOutlet weak  var tempsLabel : WKInterfaceLabel!
    @IBOutlet weak  var speedLabel : WKInterfaceLabel!
    @IBOutlet weak  var batteryLabel : WKInterfaceLabel!
    @IBOutlet weak  var remainingLabel : WKInterfaceLabel!
    
    // State
    
    var skyColor = UIColor(red: 102.0/255.0, green: 204.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    
    var distancia : Double = 0.0
    var temps : Double = 0.0
    var speed : Double = 0.0
    var battery : Double = 0.0
    var remaining : Double = 0.0
    var color : UIColor = UIColor(red: 102.0/255.0, green: 204.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    var oldColor : UIColor = UIColor(red: 102.0/255.0, green: 204.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    var colorLevel : Int = 0
    var oldColorLevel : Int = 0
    var stateChanged = false
    
    var wcsession : WCSession? = WCSession.defaultSession()
    
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        if let session = wcsession{
            session.delegate = self
            session.activateSession()
            
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        self.updateFields()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func updateData(applicationContext: [String : Double]){
        
        self.distancia = applicationContext["distancia"]!
        self.temps = applicationContext["temps"]!
        self.speed = applicationContext["speed"]!
        self.battery = applicationContext["battery"]!
        self.remaining = applicationContext["remaining"]!
        
        
        let cx = applicationContext["color"]
        
        if let c = cx {
            let ci = Int(floor(c))
            
            switch (ci) {
                
            case 1 :
                self.color = UIColor.orangeColor()
                
            case 2 :
                self.color = UIColor.redColor()
                
            default :
                self.color = skyColor
            }
            
            if ci > self.colorLevel {
                WKInterfaceDevice.currentDevice().playHaptic(WKHapticType.DirectionUp)
                self.colorLevel = ci
            }
            else if ci < self.colorLevel {
                WKInterfaceDevice.currentDevice().playHaptic(WKHapticType.DirectionDown)
                self.colorLevel = ci
            }
        }
        else {
            self.color = skyColor
            self.colorLevel = 0
        }
        
        // Check a change in color and generate haptic feedback
        
    
        
        self.stateChanged = true
    }
    
    func updateFields(){
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            if self.distancia < 1.0 {
                
                let units = "m"
                self.distLabel.setText(String(format: "%3.0f %@", self.distancia*1000.0, units))
            }
            else{
                let units = "Km"
                self.distLabel.setText(String(format: "%5.2f %@", self.distancia, units))
            }
            
            let h = Int(floor(self.temps / 3600.0))
            let m = Int(floor(self.temps - Double(h) * 3600.0)/60.0)
            let s = Int(floor(self.temps - Double(h) * 3600.0 - Double(m)*60.0))
            
            if h > 0 {
                self.tempsLabel.setText(String(format: "%2d:%2d:%2d", h, m, s))
            }
            else{
                
                self.tempsLabel.setText(String(format: "%2d:%2d", m, s))
            }
            
            self.speedLabel.setText(String(format: "%5.2f", self.speed))
            self.batteryLabel.setText(String(format: "%2d %%", Int(self.battery)))
            self.remainingLabel.setText(String(format: "%5.2f %@", self.remaining, "Km"))
            
            if self.battery < 30.0{
                self.batteryLabel.setTextColor(UIColor.redColor())
                self.remainingLabel.setTextColor(UIColor.redColor())
            }else{
                self.batteryLabel.setTextColor(UIColor.greenColor())
                self.remainingLabel.setTextColor(UIColor.greenColor())
            }
            
            if self.oldColorLevel != self.colorLevel {
                self.speedLabel.setTextColor(self.color)
                self.oldColor = self.color
                self.oldColorLevel = self.colorLevel

            }
            
            self.stateChanged = false
        })
    }
    
    func sessionWatchStateDidChange(session: WCSession) {
        
        NSLog("WCSessionState changed. Reachable %@", session.reachable)
    }
    
    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]){
        
        if let v = applicationContext as? [String : Double]{
            
            self.updateData(v)
            self.updateFields()
        }
    }
    
    
}
