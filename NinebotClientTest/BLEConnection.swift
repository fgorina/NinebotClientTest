//
//  BLEConnection.swift
//  NinebotClientTest
//
//  Created by Francisco Gorina Vanrell on 12/2/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

import UIKit
import CoreBluetooth

class BLEConnection: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate  {
    
    
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
    
    
    var centralManager : CBCentralManager?
    var discoveredPeripheral : CBPeripheral?
    var caracteristica : CBCharacteristic?
    
    
    var scanning = false
    var connected = false
    var subscribed = false
    
    var connectionRetries = 0
    var maxConnectionRetries = 3
    
    // These characteristics are not used usually
    
    var manufacturer : String?
    var model : String?
    var serial : String?
    var hardwareVer : String?
    var firmwareVer : String?
    var softwareVer : String?
    
    
    var delegate : BLENinebotConnectionDelegate?
    
    internal func startScanning()
    {
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        
    }
    
    internal func connectToDevice(device : String){
        
        if let central = self.centralManager{
            
            let ids = [NSUUID(UUIDString:device)!]
            
            let devs : [CBPeripheral] = self.centralManager!.retrievePeripheralsWithIdentifiers(ids)
            if devs.count > 0
            {
                let peri : CBPeripheral = devs[0]
                
                self.centralManager(central,  didDiscoverPeripheral:peri, advertisementData:["Hello":"Hello"],  RSSI:NSNumber())
                return
            }
        }
    }
    
    
    internal func stopScanning()
    {
        self.scanning = false
        if let cm = self.centralManager {
            cm.stopScan()
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
            
            if let dev = device   // Try to connect to last connected peripheral
            {
                self.connectToDevice(dev)
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
        
        self.connectionRetries = connectionRetries + 1
        
        if connectionRetries < maxConnectionRetries{
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
                self.connectionRetries = 0
                self.delegate?.deviceConnected(peripheral)
            }
            else{
                NSLog("Caracteristica desconeguda")
            }
            
        }
    }
    
}
    
    internal func peripheral(peripheral: CBPeripheral,
        didUpdateValueForCharacteristic characteristic: CBCharacteristic,
        error: NSError?){
            
            // Primer obtenim el TMKPeripheralObject
            
            if characteristic.UUID.UUIDString == self.charId    // Ninebot Char
            {
                if let data = characteristic.value {
                
                    self.delegate?.charUpdated(characteristic, data: data)
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
}
