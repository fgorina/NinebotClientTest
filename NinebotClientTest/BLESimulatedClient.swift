//
//  BLESimulatedClient.swift
//  NinebotClientTest
//
//  Created by Francisco Gorina Vanrell on 2/2/16.
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
import CoreBluetooth
import CoreMotion
import WatchConnectivity

class BLESimulatedClient: NSObject {
    
    static internal let kHeaderDataReadyNotification = "headerDataReadyNotification"
    static internal let kNinebotDataUpdatedNotification = "ninebotDataUpdatedNotification"
    static internal let kConnectionReadyNotification = "connectionReadyNotification"
    static internal let kConnectionLostNotification = "connectionLostNotification"
    static internal let kBluetoothManagerPoweredOnNotification = "bluetoothManagerPoweredOnNotification"
    static internal let kdevicesDiscoveredNotification = "devicesDiscoveredNotification"
    
    static internal let kLast9BDeviceAccessedKey = "9BDEVICE"
    
    var serviceId = "FFE0"
    var serviceName = "HMSoft"
    var charId = "FFE1"
    
    // Ninebot control
    
    var datos : BLENinebot?
    var headersOk = false
    var sendTimer : Timer?    // Timer per enviar les dades periodicament
    var timerStep = 0.01        // Get data every step
    var contadorOp = 0          // Normal data updated every second
    var contadorOpFast = 0      // Special data updated every 1/10th of second
    var listaOp :[(UInt8, UInt8)] = [(34,4), (41, 2), (50,2), (58,5), (71,6), (182, 5)]
    var listaOpFast :[(UInt8, UInt8)] = [(38,1), (80,1), (97,4)]
    
    
    var buffer = [UInt8]()
    
    // Altimeter data
    
    var altimeter : CMAltimeter?
    var altQueue : OperationQueue?
    
    // General State
    
    var scanning = false
    var connected = false
    var subscribed = false
    
    // Watch control
    
    var timer : Timer?
    var wcsession : WCSession?
    var sendToWatch = false
    var oldState : Dictionary<String, Double>?
    
    var connection : BLEConnection
    
    override init() {
        
        self.connection = BLEConnection()
        super.init()
        self.connection.delegate = self
        
        if WCSession.isSupported(){
            
            let session = WCSession.default()
            session.delegate = self
            session.activate()
            self.wcsession = session
            
            let paired = session.isPaired
            let installed = session.isWatchAppInstalled
            
            if paired {
                NSLog("Session Paired")
                
            }
            
            if installed {
                NSLog("Session Installed" )
            }
            
            if session.isPaired && session.isWatchAppInstalled{
                self.sendToWatch = true
            }
        }
    }
    
    func initNotifications()
    {
        NotificationCenter.default.addObserver(self, selector: "updateTitle:", name: NSNotification.Name(rawValue: BLESimulatedClient.kHeaderDataReadyNotification), object: nil)
    }
    
    // Connect is the start connection
    //
    //  First it recovers if it exists a device and calls
    func connect(){
        
        // First we recover the last device and try to connect directly
        
        let store = UserDefaults.standard
        let device = store.string(forKey: BLESimulatedClient.kLast9BDeviceAccessedKey)
        
        if let dev = device {
            self.connection.connectToDeviceWithUUID(dev)
        }
    }
    
    func stop(){
        
        // First we disconnect the device
        
        self.connection.stopConnection()
        
        // Now we save the file
        
        if let nb = self.datos{
            nb.createTextFile()
        }
    }
    
    //MARK: Auxiliary functions
    
    
    class func sendNotification(_ notification: String, data:[AnyHashable: Any]? ){
        
        let notification = Notification(name:Notification.Name(rawValue: notification), object:self, userInfo: data)
        NotificationCenter.default.post(notification)
        
    }
    
    
    func startAltimeter(){
        
        if CMAltimeter.isRelativeAltitudeAvailable(){
            if self.altimeter == nil{
                self.altimeter = CMAltimeter()
            }
            if self.altQueue == nil{
                self.altQueue = OperationQueue()
                self.altQueue!.maxConcurrentOperationCount = 1
            }
            
            
            if let altm = self.altimeter, let queue = self.altQueue{
                
                altm.startRelativeAltitudeUpdates(to: queue,
                    withHandler: { (alts : CMAltitudeData?, error : NSError?) -> Void in
                        
                        if let alt = alts, let nb = self.datos {
                            nb.addValue(0, value: Int(floor(alt.relativeAltitude.doubleValue * 10.0)))
                        }
                } as! CMAltitudeHandler)
            }
        }
    }
    
    
    
    //MARK: AppleWatch Support
    
    func getAppState() -> [String : Double]?{
        
        var dict  = [String : Double]()
        
        if let nb = self.datos{
            
            dict["temps"] = nb.singleRuntime()
            dict["distancia"]  = nb.singleMileage()
            dict["speed"]  =  nb.speed()
            dict["battery"]  =  nb.batteryLevel()
            dict["remaining"]  =  nb.remainingMileage()
            
            let v = nb.speed()
            
            if v >= 18.0 && v < 20.0{
                dict["color"] = 1.0
            }else if v >= 20.0 {
                dict["color"] = 2.0
            }
            else{
                dict["color"] = 0.0
            }
        }
        return dict
    }
    
    func checkState(_ state_1 :[String : Double]?, state_2:[String : Double]?) -> Bool{
        
        if state_1 == nil || state_2 == nil{
            return false
        }
        
        
        if let st1 = state_1, let st2 = state_2 {
            
            if st1.count != st2.count {
                return false
            }
            
            for (k1, v1 ) in st1{
                
                let v2 = st2[k1]
                
                if let vv2 = v2 {
                    if vv2 != v1 {
                        return false
                    }
                }
                else
                {
                    return false
                }
            }
            return true
            
        }
        
        return false
    }
    
    func sendStateToWatch(_ timer: Timer){
        
        if self.sendToWatch{
            
            let info = self.getAppState()
            
            if !self.checkState(info, state_2: self.oldState){
                if let session = wcsession, let inf = info {
                    do {
                        try session.updateApplicationContext(inf)
                        self.oldState = info
                    }
                    catch _{
                        NSLog("Error sending data to watch")
                    }
                }
                
            }
        }
    }
    
    func sendData(_ timer:Timer){
        
        if let nb = self.datos {
            
            if nb.checkHeaders() {  // Get normal data
                
                if !self.headersOk {
                    self.headersOk = true
                    BLESimulatedClient.sendNotification(BLESimulatedClient.kHeaderDataReadyNotification, data:nil)
                    
                }
                contadorOpFast += 1
                let (op, l) = listaOpFast[contadorOpFast]
                let message = BLENinebotMessage(com: op, dat:[ l * 2] )
                if let dat = message?.toNSData(){
                    self.connection.writeValue(dat)
                }
                
                
                if contadorOpFast >= listaOpFast.count{
                    contadorOpFast = 0
                    contadorOp+=1
                    let (op, l) = listaOp[contadorOp]
                    
                    if contadorOp >= listaOp.count{
                        contadorOp = 0
                    }
                    
                    let message = BLENinebotMessage(com: op, dat:[ l * 2] )
                    
                    
                    if let dat = message?.toNSData(){
                        self.connection.writeValue(dat)
                    }
                }
                
                
            } else {    // Get One time data (S/N, etc.)
                
                
                let message = BLENinebotMessage(com: UInt8(16), dat: [UInt8(22)])
                if let dat = message?.toNSData(){
                    self.connection.writeValue(dat)
                }
            }
        }
    }
    
    //MARK: Receiving Data
    
    func appendToBuffer(_ data : Data){
        
        let count = data.count
        var buf = [UInt8](repeating: 0, count: count)
        (data as NSData).getBytes(&buf, length:count * MemoryLayout<UInt8>.size)
        
        buffer.append(contentsOf: buf)
    }
    
    func procesaBuffer()
    {
        // Wait till header
        
        repeat {
            
            while buffer.count > 0 && buffer[0] != 0x55 {
                buffer.removeFirst()
            }
            
            // OK, ara hem de veure si el caracter següent es un aa
            
            if buffer.count < 2{    // Wait for more data
                return
            }
            
            if buffer[1] != 0xaa {  // Fals header. continue cleaning
                buffer.removeFirst()
                procesaBuffer()
                return
            }
            
            if buffer.count < 8 {   // Too small. Wait
                return
            }
            
            // Extract len and check size
            
            let l = Int(buffer[2])
            
            if l + 4 > 250 {
                buffer.removeFirst(3)
                return
            }
            
            if buffer.count < (6 + l){
                return
            }
            
            // OK ara ja podem extreure el block. Te len + 6 bytes
            
            let block = Array(buffer[0..<(l+6)])
            
            
            let msg = BLENinebotMessage(buffer: block)
            
            if let m = msg {
                
                let d = m.interpret()
                
                var updated = false
                
                if let nb = self.datos{
                    
                    for (k, v) in d {
                        if k != 0{
                            let w = nb.data[k].value
                            if w != v{
                                updated = true
                            }
                            
                            nb.addValue(k, value: v)
                        }
                    }
                    
                    if updated{
                        BLESimulatedClient.sendNotification(BLESimulatedClient.kNinebotDataUpdatedNotification, data: nil)
                        
                        //let state = self.getAppState()
                        
                        
                        
                    }
                }
            }
            
            buffer.removeFirst(l+6)
            
        } while buffer.count > 6
    }
}

//MARK: BLENinebotConnectionDelegate

extension BLESimulatedClient : BLENinebotConnectionDelegate{
    
    func deviceConnected(_ peripheral : CBPeripheral ){
        

            self.startAltimeter()
            self.contadorOp = 0
            self.headersOk = false
            self.connected = true
            
            self.sendTimer = Timer.scheduledTimer(timeInterval: self.timerStep, target: self, selector: #selector(BLESimulatedClient.sendData(_:)), userInfo: nil, repeats: true)
            
            
            // Start timer for sending info to watch
            
            if self.sendToWatch {
                self.timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector:#selector(BLESimulatedClient.sendStateToWatch(_:)), userInfo: nil, repeats: true)
            }
    }
    
    func deviceDisconnectedConnected(_ peripheral : CBPeripheral ){
        self.connected = false
        if let tim = self.sendTimer {
            tim.invalidate()
            self.sendTimer = nil
        }
        
        if let tim = self.timer {
            tim.invalidate()
            self.timer = nil
        }
        
        if let altm = self.altimeter{
            altm.stopRelativeAltitudeUpdates()
            self.altimeter = nil
        }
    }
    
    func charUpdated(_ char : CBCharacteristic, data: Data){
        
        self.appendToBuffer(data)
        self.procesaBuffer()
    }
    
}

//MARK: WCSessionDelegate

extension BLESimulatedClient :  WCSessionDelegate{
    
    @available(iOS 9.3, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        sessionWatchStateDidChange(session)
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        sessionWatchStateDidChange(session)
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        sessionWatchStateDidChange(session)
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        
        if session.isPaired && session.isWatchAppInstalled{
            self.sendToWatch = true
            self.timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector:#selector(BLESimulatedClient.sendStateToWatch(_:)), userInfo: nil, repeats: true)
            
        }
        else{
            self.sendToWatch = false
            if let tim = self.timer {
                tim.invalidate()
                self.timer = nil
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        
        
        // For the moment the watch just listens
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        
        // Fot the moment the watch just listens
        
    }
    
}



