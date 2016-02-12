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
    
    var distancia : Double = 0.0
    var temps : Double = 0.0
    var speed : Double = 0.0
    var battery : Double = 0.0
    var remaining : Double = 0.0
    
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
        
        self.stateChanged = true
    }
    
    func updateFields(){
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
                if self.distancia < 1000.0 {
                    
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
