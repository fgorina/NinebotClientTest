//
//  InterfaceController.swift
//  9BMetrics Extension
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

import WatchKit
import Foundation
import WatchConnectivity


class InterfaceController: WKInterfaceController, WCSessionDelegate {
    
    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    @available(watchOS 2.2, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("session activated")
    }

    
    
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
    
    var wcsession : WCSession? = WCSession.default()
    
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        if let session = wcsession{
            session.delegate = self
            session.activate()
            
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
    
    func updateData(_ applicationContext: [String : Double]){
        
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
                self.color = UIColor.orange
                
            case 2 :
                self.color = UIColor.red
                
            default :
                self.color = skyColor
            }
            
            if ci > self.colorLevel {
                WKInterfaceDevice.current().play(WKHapticType.directionUp)
                self.colorLevel = ci
            }
            else if ci < self.colorLevel {
                WKInterfaceDevice.current().play(WKHapticType.directionDown)
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
        
        DispatchQueue.main.async(execute: { () -> Void in
            
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
                self.batteryLabel.setTextColor(UIColor.red)
                self.remainingLabel.setTextColor(UIColor.red)
            }else{
                self.batteryLabel.setTextColor(UIColor.green)
                self.remainingLabel.setTextColor(UIColor.green)
            }
            
            if self.oldColorLevel != self.colorLevel {
                self.speedLabel.setTextColor(self.color)
                self.oldColor = self.color
                self.oldColorLevel = self.colorLevel

            }
            
            self.stateChanged = false
        })
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]){
        
        if let v = applicationContext as? [String : Double]{
            
            self.updateData(v)
            self.updateFields()
        }
    }
    
    
}
