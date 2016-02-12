//
//  BLESimulatedServer.swift
//  NinebotClientTest
//
//  Created by Francisco Gorina Vanrell on 2/2/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

import UIKit
import CoreBluetooth

class BLESimulatedServer: NSObject, CBPeripheralManagerDelegate {
    
    let manager : CBPeripheralManager
    var transmiting = false
    var scanning = false
    
    var serviceId = "FFE0"
    var serviceName = "HMSoft"
    var charId = "FFE1"
    
    var nordicServiceId = "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
    var nordicCharId = "6e400003-b5a3-f393-e0a9-e50e24dcca9e"
    var nordicServiceName = "NORDIC"
    
    var caracteristica : CBMutableCharacteristic?
    var servei : CBMutableService?
    
    var nordicChar : CBMutableCharacteristic?
    var nordicServei:CBMutableService?
    
    var answerArray : [String] = ["55aa08090117303030303030b6fe",
            "55aa0409011a353171ff"]

    var timer : NSTimer?
    var contador : Int = 0
    
    weak var cntrl : ViewController?
    
    override init() {
        
        self.manager = CBPeripheralManager()
        super.init()
        self.manager.delegate = self
    }
    
    
    // MARK: PeripheralManagerDelegate
    
    func peripheralManagerDidUpdateState(peripheral : CBPeripheralManager){
    
        switch(peripheral.state){
            
        case .PoweredOn: // Configurem el servei
            self.buildService()
            self.startTransmiting()
            
        default:        // Powerdown
            
            self.transmiting = false
            peripheral.stopAdvertising()
         }
        
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic) {
        
        if let ct = self.cntrl {
            ct.appendToLog(String(format : "Suscripcio a : %@", characteristic.description))
        }
        else{
            NSLog("Suscripcio a : %@", characteristic.description)
        }
        
        // Build a NSData amb la resposta. Quina es????
        
 //       let data = NSData(bytes: [0x55, 0xAA, 4, 9, 1, 25, 0x76, 6, 0x50, 0xff] as [UInt8], length: 10)
        
//        self.manager.updateValue(data, forCharacteristic: self.caracteristica!, onSubscribedCentrals: nil);
        
        
    
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic) {
        
        if let ct = self.cntrl {
            ct.appendToLog(String(format : "Suscripcio cancelada a : %@", characteristic.description))
        }
        else{
             NSLog("Suscripcio cancelada a : %@", characteristic.description)
        }
   
        
        
        
    }
    
    
    func peripheralManager(peripheral: CBPeripheralManager, didReceiveReadRequest request: CBATTRequest) {
        
        if let ct = self.cntrl {
            ct.appendToLog(String(format : "Read request received: %@", request.description))
        }
        else{
            NSLog("Read request received: %@", request.description)
        }
        
        
        peripheral.respondToRequest(request, withResult: CBATTError.Success)
        
        
    }
    

    
    func peripheralManager(peripheral: CBPeripheralManager, didReceiveWriteRequests requests: [CBATTRequest]) {

        for request in requests {
            let value = request.value
            
            
            if let data = value {
                
                if let ct = self.cntrl {
                   // ct.appendToLog(String(format : "Request value : %@", data))
                }
                else{
                    NSLog("Request value : %@", data)
                }

                self.cntrl!.forwardWrite(data)
                
                /*
              
                let count = data.length
                var array = [UInt8](count: count, repeatedValue: 0)
                data.getBytes(&array, length:count * sizeof(UInt8))
                
                let message = BLENinebotMessage(buffer: array)
                
                if let msg = message {
                    
                    if let ct = self.cntrl {
                        ct.appendToLog(String(format : "Received write Request : %@", msg.toString()))
                    }
                    else{
                        NSLog("Received write Request : %@", msg.toString())
                    }
                    
                    // Send back all info as messages
                    // TODO : Analitzar el missatge de resposta del Ninebot
                    //      : Seguir la sequencia
                    //      : Probablement muntar una petita màquina de estats finits
                    //      : Acabar de aclarir totes les variables que s'envien
                    //      : Si volem suportar les modificacions veure com les envia
                    //
                    
                    self.contador = 0
                    self.timer = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: "procesaArray:", userInfo: self.answerArray, repeats: true)


                    
                }
                else
                {
                    NSLog("Received erroneus write Request %@", data)
                }
                */
                
                
             }
            peripheral.respondToRequest(request, withResult: CBATTError.Success)
        }
    }
    
    
    func procesaArray(timer: NSTimer){
        
        let sa = timer.userInfo as! [String]
        
        let s = sa[contador]
        let msg = BLENinebotMessage(string: s)
        
        NSLog("Retornat %@", s)
        if let m = msg {
            let data = m.toNSData()
            if let dat = data {
                self.manager.updateValue(dat, forCharacteristic: self.caracteristica!, onSubscribedCentrals: nil)
                
            }
            
        }
        
        self.contador++
        
        if self.contador >= sa.count {
            if let tim = self.timer {
                tim.invalidate()
            }
            self.timer = nil
            self.contador = 0
        }
        
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, didReceiveWriteRequest request: CBATTRequest) {
        NSLog("Write request received: %@", request.description)
        
        // get the value of the variable
        
        let value = request.characteristic.value
        
        if let data = value {
            
            let count = data.length
            var array = [UInt8](count: count, repeatedValue: 0)
            data.getBytes(&array, length:count * sizeof(UInt8))
            
            let message = BLENinebotMessage(buffer: array)
            
            if let msg = message {
            
                NSLog("Received write Request : %@", msg.toString())
            }
            else
            {
                NSLog("Received erroneus write Request %@", data)
            }
  
            
        }
        
        
        peripheral.respondToRequest(request, withResult: CBATTError.Success)

    }

    
    //MARK: Auxiliar
    
    func updateValue(data : NSData){
        
        if let car = self.caracteristica{
        
            self.manager.updateValue(data, forCharacteristic: car, onSubscribedCentrals: nil);
        }
        
    }
    
    func buildService(){
        
        let  userDesc = CBMutableDescriptor(type: CBUUID(string:CBUUIDCharacteristicUserDescriptionString), value: "HMSoft")

   //     let  clientDesc = CBMutableDescriptor(type: CBUUID(string:CBUUIDClientCharacteristicConfigurationString), value: NSNumber(integer: 0))
        
        
        
        self.caracteristica = CBMutableCharacteristic(type: CBUUID(string: charId), properties:[CBCharacteristicProperties.Notify,CBCharacteristicProperties.Read,CBCharacteristicProperties.WriteWithoutResponse], value: nil, permissions: [CBAttributePermissions.Readable,CBAttributePermissions.Writeable])
        
        self.caracteristica?.descriptors = [userDesc]
        
        
        if let car = self.caracteristica {
            self.servei = CBMutableService(type: CBUUID(string: self.serviceId), primary: true)
        
            if let serv = self.servei {
                serv.characteristics = [car]
                self.manager.addService(serv)
                
                let data = NSData(bytes: [85, 0xAA, 4, 9, 1, 25, 0, 8, 0xc4, 0xff] as [UInt8], length: 10)
                

                self.manager.updateValue(data, forCharacteristic: car, onSubscribedCentrals: nil);
               
             }
        }
        
//        self.nordicChar = CBMutableCharacteristic(type: CBUUID(string: self.nordicCharId), properties:[CBCharacteristicProperties.Read,CBCharacteristicProperties.WriteWithoutResponse, CBCharacteristicProperties.Write], value: nil, permissions: [CBAttributePermissions.Readable,CBAttributePermissions.Writeable])
//
//        if let car = self.nordicChar {
//            self.nordicServei = CBMutableService(type: CBUUID(string: self.nordicServiceId), primary: true)
//            
//            if let serv = self.nordicServei {
//                serv.characteristics = [car]
//                self.manager.addService(serv)
//                
//            }
//        }

        
    }
    
    func startTransmiting(){
        
        let dict : Dictionary = [CBAdvertisementDataServiceUUIDsKey : [CBUUID(string: self.serviceId)],
            CBAdvertisementDataLocalNameKey : "NOE002"]
        
        self.manager.startAdvertising(dict)
        self.transmiting = true

        
    }
    
    func stopTransmiting(){
        
        self.manager.stopAdvertising()
        self.transmiting = false
        
    }
}
