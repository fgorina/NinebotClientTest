//
//  BLESimulatedClient.swift
//  NinebotClientTest
//
//  Created by Francisco Gorina Vanrell on 2/2/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreMotion
import WatchConnectivity

class BLESimulatedClient: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    
    internal let kUUIDDeviceInfoService = "180A"
    internal let kUUIDManufacturerNameVariable = "2A29"
    internal let kUUIDModelNameVariable = "2A24"
    internal let kUUIDSerialNumberVariable = "2A25"
    internal let kUUIDHardwareVersion = "2A27"
    internal let kUUIDFirmwareVersion = "2A26"
    internal let kUUIDSoftwareVersion = "2A28"
    internal static let kLast9BDeviceAccessedKey = "9BDEVICE"
    
    var serviceId = "FFE0"
    var serviceName = "HMSoft"
    var charId = "FFE1"
    
    var buffer = [UInt8]()

    
    var centralManager : CBCentralManager?
    var discoveredPeripheral : CBPeripheral?
    var caracteristica : CBCharacteristic?
    
    var altimeter : CMAltimeter?
    var altQueue : NSOperationQueue?
    
    var scanning = false
    var connected = false
    var subscribed = false
    
    // Devide id
    
    var manufacturer : String?
    var model : String?
    var serial : String?
    var hardwareVer : String?
    var firmwareVer : String?
    var softwareVer : String?
    
    var log : [UInt8] = [UInt8]()
    
    var timer : NSTimer?
    var count : Int = 0
    var rep : Int = 0
    
    
    var wcsession : WCSession?
    var sendToWatch = false
    
    var oldState : Dictionary<String, Double>?
    
    weak var cntrl : ViewController?
    
    override init() {
        
        super.init()
        
        if WCSession.isSupported(){
            
            let session = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
            self.wcsession = session
            
            let paired = session.paired
            let installed = session.watchAppInstalled
            
            if paired {
                NSLog("Session Paired")
                
            }
            
            if installed {
                NSLog("Session Installed" )
            }
            
            if session.paired && session.watchAppInstalled{
                self.sendToWatch = true
            }
        }
        
        
        
        
    }
    
    
    internal func startScanning()
    {
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        
    }
    internal func stopScanning()
    {
        self.scanning = false
        if let cm = self.centralManager {
            cm.stopScan()
        }
        if let altm = self.altimeter{
            altm.stopRelativeAltitudeUpdates()
        }
        if let tim = self.timer{
            tim.invalidate()
            self.timer = nil
        }
        self.cleanup()
        self.centralManager = nil
        
    }
    
    
    internal func cleanup() {
        
        // See if we are subscribed to a characteristic on the peripheral
        
        if let thePeripheral = self.discoveredPeripheral  {
            if let theServices = thePeripheral.services {
                
                for service : CBService in theServices {
                    
                    if let theCharacteristics = service.characteristics {
                        for characteristic : CBCharacteristic in theCharacteristics {
                            if characteristic.UUID == CBUUID(string:self.charId) {
                                if characteristic.isNotifying {
                                    self.discoveredPeripheral!.setNotifyValue(false, forCharacteristic:characteristic)
                                    //return;
                                }
                            }
                        }
                    }
                }
                
            }
            if let peri = self.discoveredPeripheral {
                if let central = self.centralManager{
                    central.cancelPeripheralConnection(peri)
                }
            }
        }
        
        self.connected = false
        self.discoveredPeripheral = nil;
    }
    
    func getAppState() -> [String : Double]?{
        
        
        if let cntl = self.cntrl{
            
            var dict  = [String : Double]()
            let nb = cntl.datos
            
            dict["temps"] = nb.singleRuntime()
            dict["distancia"]  = nb.singleMileage()
            dict["speed"]  =  nb.speed()
            dict["battery"]  =  nb.batteryLevel()
            dict["remaining"]  =  nb.remainingMileage()
            return dict
        }
        else{
            return nil
        }
        
    }
    
    func checkState(state_1 :[String : Double]?, state_2:[String : Double]?) -> Bool{
        
        if state_1 == nil || state_2 == nil{
            return false
        }
        
        
        if let st1 = state_1, st2 = state_2 {
            
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
    
    func sendStateToWatch(timer: NSTimer){
        if self.sendToWatch{
            
            let info = self.getAppState()
            
            if !self.checkState(info, state_2: self.oldState){
               if let session = wcsession, inf = info {
                    NSLog("Sending data to Watch")
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
    
    
    //MARK: CBCentralManagerDelegate
    
    
    internal func centralManagerDidUpdateState(central : CBCentralManager)
    {
        
        self.scanning = false;
        
        
        if central.state != CBCentralManagerState.PoweredOn {
            return;
        }
        
        if central.state == CBCentralManagerState.PoweredOn {
            
            // Check to see if we have a device already registered to avoid scanning
            let store = NSUserDefaults.standardUserDefaults()
            let device = store.stringForKey(BLESimulatedClient.kLast9BDeviceAccessedKey)
            
            if device != nil   // Try to connect to last connected peripheral
            {
                
                let ids = [NSUUID(UUIDString:device!)!]
                
                
                
                let devs : [CBPeripheral] = self.centralManager!.retrievePeripheralsWithIdentifiers(ids)
                if devs.count > 0
                {
                    let peri : CBPeripheral = devs[0]
                    
                    self.centralManager(central,  didDiscoverPeripheral:peri, advertisementData:["Hello":"Hello"],  RSSI:NSNumber())
                    return
                }
                
            }
            
            // If we are here we may try to look for a connected device known to the central manager
            
            let services = [CBUUID(string:self.serviceId)]
            let moreDevs : [CBPeripheral] = self.centralManager!.retrieveConnectedPeripheralsWithServices(services)
            
            if  moreDevs.count > 0
            {
                let peri : CBPeripheral = moreDevs[0]
                
                self.centralManager(central, didDiscoverPeripheral:peri,  advertisementData:["Hello": "Hello"],  RSSI:NSNumber(double: 0.0))
                return
            }
            
            // OK, nothing works so we go for the scanning
            
            self.doRealScan()
            
        }
        
    }
    
    func doRealScan()
    {
        self.scanning = true
        
        
        // Scan for devices    @[[CBUUID UUIDWithString:@"1819"]]
        self.centralManager!.scanForPeripheralsWithServices([CBUUID(string:self.serviceId)], options:[CBCentralManagerScanOptionAllowDuplicatesKey : false ])
        
        NSLog("Scanning started")
    }
    
    
    internal func centralManager(central: CBCentralManager,
        didDiscoverPeripheral peripheral: CBPeripheral,
        advertisementData: [String : AnyObject],
        RSSI: NSNumber){
            
            NSLog("Discovered %@ - %@", peripheral.name!, peripheral.identifier);
            
            self.discoveredPeripheral = peripheral;
            NSLog("Connecting to peripheral %@", peripheral);
            self.centralManager!.connectPeripheral(peripheral, options:nil)
            
    }
    
    func connectPeripheral(peripheral : CBPeripheral)
    {
        
        NSLog("Connecting to HR peripheral %@", peripheral);
        
        self.centralManager!.stopScan()
        
        self.discoveredPeripheral = peripheral;
        self.centralManager!.connectPeripheral(peripheral, options:nil)
    }
    
    
    internal func centralManager(central : CBCentralManager, didFailToConnectPeripheral peripheral : CBPeripheral,  error : NSError?)
    {
        
        NSLog("Failed to connect to Ninebot %@", peripheral.identifier);
        
        if !self.scanning // If not scanning try to do it
        {
            self.doRealScan()
            
        }
        else
        {
            
            self.cleanup()
        }
        
    }
    
    
    internal func centralManager(central : CBCentralManager, didConnectPeripheral peripheral :CBPeripheral){
        NSLog("Connected");
        
        if self.scanning
        {
            self.centralManager!.stopScan()
            self.scanning = false
            NSLog("Scanning stopped")
        }
        
        peripheral.delegate = self;
        
        //[peripheral discoverServices:nil];
        
        manufacturer = ""
        model = ""
        serial = ""
        hardwareVer = ""
        firmwareVer = ""
        softwareVer = ""
        
        
        peripheral.discoverServices([CBUUID(string:self.serviceId)])
    }
    
    internal func centralManager(central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: NSError?)
        
    {
        let store = NSUserDefaults.standardUserDefaults()
        let device = store.stringForKey(BLESimulatedClient.kLast9BDeviceAccessedKey)
        
        
        if let dev = device  // Try to connect to last connected peripheral
        {
            
            if let theId = NSUUID(UUIDString:dev){
                
                let ids  = [theId]
                let devs : [CBPeripheral] = self.centralManager!.retrievePeripheralsWithIdentifiers(ids)
                
                if devs.count > 0
                {
                    let peri : CBPeripheral = devs[0]
                    
                    self.centralManager(central,  didDiscoverPeripheral:peri,  advertisementData:["Hello" : "Hello"],  RSSI:NSNumber())
                    return;
                }
            }
        }
        else {
            if let cn = self.cntrl{
                cn.toScreen()
                cn.clientStopped()
            }
        }
        self.discoveredPeripheral = nil;
    }
    
    //MARK: writeValue
    
    func writeValue(data : NSData){
        if let peri = self.discoveredPeripheral {
            peri.writeValue(data, forCharacteristic: self.caracteristica!, type: .WithoutResponse)
        }
    }
    
    //MARK: CBPeripheralDelegate
    
    internal func peripheral(peripheral: CBPeripheral,didDiscoverServices error: NSError?)
    {
        
        
        if let serv = peripheral.services{
            for sr in serv
            {
                NSLog("Service %@", sr.UUID.UUIDString)
                
                if sr.UUID.UUIDString == self.serviceId
                {
                    let charUUIDs = [CBUUID(string:self.charId)]
                    peripheral.discoverCharacteristics(charUUIDs, forService:sr)
                }
            }
        }
    }
    
    func doSend(command:UInt8, data:[UInt8], peripheral : CBPeripheral, ch : CBCharacteristic){
        let msg = BLENinebotMessage(com: command, dat: data)
        
        if let m = msg {
            let nsdat = m.toNSData()
            if let dat = nsdat {
                peripheral.writeValue(dat, forCharacteristic: ch, type: .WithoutResponse)
            }
        }
    }
    
    internal func peripheral(peripheral: CBPeripheral,
        didDiscoverCharacteristicsForService service: CBService,
        error: NSError?)
    {
        
        // Sembla una bona conexio, la guardem per mes endavant
        
        
        // Sembla una bona conexio, la guardem per mes endavant
        let store = NSUserDefaults.standardUserDefaults()
        let idPeripheral = peripheral.identifier.UUIDString
        
        store.setObject(idPeripheral, forKey:BLESimulatedClient.kLast9BDeviceAccessedKey)
        
        
        if let characteristics = service.characteristics {
            for ch in characteristics {
                
                if ch.UUID.UUIDString == self.charId
                {
                    self.caracteristica = ch
                    peripheral.setNotifyValue(true, forCharacteristic:ch)
                    self.connected = true
                    
                    self.startAltimeter()
                    
                    if let ct = self.cntrl {
                        ct.appendToLog(String(format :"Subscrit a la variable del Ninebot : %@", ch.description))
                    }
                    else{
                        NSLog("Subscrit a la variable del Ninebot : %@", ch.description)
                    }
                    if let cn = self.cntrl {
                        cn.clientStarted()
                    }
                    
                    // Start timer for sending info to watch
                    
                    if self.sendToWatch {
                        self.timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector:"sendStateToWatch:", userInfo: nil, repeats: true)
                    }
                    //self.count = 0
                    //self.rep = 0
                    
                    
                }
                else{
                    NSLog("Caracteristica desconeguda")
                }
                
            }
        }
        
    }
    
    func startAltimeter(){
        
        if CMAltimeter.isRelativeAltitudeAvailable(){
            if self.altimeter == nil{
                self.altimeter = CMAltimeter()
            }
            if self.altQueue == nil{
                self.altQueue = NSOperationQueue()
                self.altQueue!.maxConcurrentOperationCount = 1
            }
            
            
            if let altm = self.altimeter, queue = self.altQueue{
                
                altm.startRelativeAltitudeUpdatesToQueue(queue,
                    withHandler: { (alts : CMAltitudeData?, error : NSError?) -> Void in
                        
                        if let alt = alts {
                            
                            
                            if let cn = self.cntrl{
                                cn.datos.addValue(0, value: Int(floor(alt.relativeAltitude.doubleValue * 10.0)))
                            }
                        }
                })
            }
        }
    }
    
    internal func peripheral(peripheral: CBPeripheral,
        didUpdateValueForCharacteristic characteristic: CBCharacteristic,
        error: NSError?){
            
            // Primer obtenim el TMKPeripheralObject
            
            if characteristic.UUID.UUIDString == self.charId    // Ninebot Char
            {
                
                let data = characteristic.value!
                
                if let cn = self.cntrl{
                    
                    cn.forwardValue(data)
                }
                    
                else{
                    NSLog("<<< %@", data)
                }
                
                
            }
                
                
            else if characteristic.UUID.UUIDString==self.kUUIDManufacturerNameVariable  {
                
                if let data = characteristic.value {
                    self.manufacturer = String(data:data, encoding: NSUTF8StringEncoding)
                    NSLog("Manufacturer : %@", self.manufacturer!)
                }
            }
            else if characteristic.UUID.UUIDString==self.kUUIDModelNameVariable  {
                
                if let data = characteristic.value {
                    self.model = String(data:data, encoding: NSUTF8StringEncoding)
                    NSLog("Model : %@", self.model!)
                }
            }
            else if characteristic.UUID.UUIDString==self.kUUIDSerialNumberVariable  {
                
                if let data = characteristic.value {
                    self.serial = String(data:data, encoding: NSUTF8StringEncoding)
                    NSLog("Serial : %@", self.serial!)
                }
            }
            else if characteristic.UUID.UUIDString==self.kUUIDHardwareVersion  {
                
                if let data = characteristic.value {
                    self.hardwareVer = String(data:data, encoding: NSUTF8StringEncoding)
                    NSLog("Hardware Version : %@", self.hardwareVer!)
                }
            }
            else if characteristic.UUID.UUIDString==self.kUUIDFirmwareVersion  {
                
                if let data = characteristic.value {
                    self.firmwareVer = String(data:data, encoding: NSUTF8StringEncoding)
                    NSLog("Firmware Version : %@", self.firmwareVer!)
                }
            }
            else if characteristic.UUID.UUIDString==self.kUUIDSoftwareVersion {
                
                if let data = characteristic.value {
                    self.softwareVer = String(data:data, encoding: NSUTF8StringEncoding)
                    NSLog("Software Ver : %@", self.softwareVer!)
                }
            }
            
    }
    
    //MARK: Connection management
    
    func appendToBuffer(data : NSData){
        
        
        let count = data.length
        var buf = [UInt8](count: count, repeatedValue: 0)
        data.getBytes(&buf, length:count * sizeof(UInt8))
        
        buffer.appendContentsOf(buf)
        
        
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
                
                for (k, v) in d {
                    let w = datos.data[k].value
                    if w != v{
                        
                        let name = BLENinebot.labels[k]
                        self.appendToLog(String(format:"%@[%d] - %d", name, k, v))
                        updated = true
                    }
                    
                    self.datos.addValue(k, value: v)
                }
                
                if updated{
                    if let dash = self.dashboard {
                        dash.update()
                    }
                    
                }
                
                // self.appendToLog(String(format:">>> %@", m.interpret()))
            }
            
            
            buffer.removeFirst(l+6)
            
        } while buffer.count > 6
        
        
    }
    
    
    
}

extension BLESimulatedClient :  WCSessionDelegate{
    
    func sessionWatchStateDidChange(session: WCSession) {
        
        if session.paired && session.watchAppInstalled{
            self.sendToWatch = true
            self.timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector:"sendStateToWatch:", userInfo: nil, repeats: true)

        }
        else{
            self.sendToWatch = false
            if let tim = self.timer {
                tim.invalidate()
                self.timer = nil
            }
        }
        
    }
    
    func session(session: WCSession, didReceiveMessageData messageData: NSData) {
        
        // For the moment the watch just listens
    }
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject]) {
        
        // Fot the moment the watch just listens 
        
    }
    
}



