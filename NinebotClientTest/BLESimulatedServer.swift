//
//  BLESimulatedServer.swift
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

class BLESimulatedServer: NSObject, CBPeripheralManagerDelegate {
    
    let manager : CBPeripheralManager
    var transmiting = false
    var scanning = false
    
    var serviceId = "FFE0"
    var serviceName = "HMSoft"
    var charId = "FFE1"
    
    
    var caracteristica : CBMutableCharacteristic?
    var servei : CBMutableService?
    
    weak var delegate : BLENinebotServerDelegate?
        
    override init() {
        
        self.manager = CBPeripheralManager()
        super.init()
        self.manager.delegate = self
        
    }
    
    
    // MARK: PeripheralManagerDelegate
    
    func peripheralManagerDidUpdateState(_ peripheral : CBPeripheralManager){
    
        switch(peripheral.state){
            
        case .poweredOn: // Configurem el servei
            self.buildService()
            self.startTransmiting()
            
        default:        // Powerdown
            
            self.transmiting = false
            peripheral.stopAdvertising()
         }
        
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        
        if let del = self.delegate {
            
            del.remoteDeviceSubscribedToCharacteristic(characteristic, central: central)
        }
        
        
        
        // Build a NSData amb la resposta. Quina es????
        
 //       let data = NSData(bytes: [0x55, 0xAA, 4, 9, 1, 25, 0x76, 6, 0x50, 0xff] as [UInt8], length: 10)
        
//        self.manager.updateValue(data, forCharacteristic: self.caracteristica!, onSubscribedCentrals: nil);
        
        
    
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        
        if let del = self.delegate {
            
            del.remoteDeviceUnsubscribedToCharacteristic(characteristic, central: central)
        }
        
        
    }
    
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest){
        
        peripheral.respond(to: request, withResult: CBATTError.Code.success)
        
    }

    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {

        for request in requests {
            let value = request.value
            
            if let data = value {
                
                if let dele = self.delegate{
                        dele.writeReceived(request.characteristic, data: data)
                    
                }
             }
            peripheral.respond(to: request, withResult: CBATTError.Code.success)
        }
    }
    
    
 
    
    //MARK: Auxiliar
    
    func updateValue(_ data : Data){
        
        if let car = self.caracteristica{
        
            self.manager.updateValue(data, for: car, onSubscribedCentrals: nil);
        }
        
    }
    
    func buildService(){
        
        let  userDesc = CBMutableDescriptor(type: CBUUID(string:CBUUIDCharacteristicUserDescriptionString), value: "HMSoft")
        
        self.caracteristica = CBMutableCharacteristic(type: CBUUID(string: charId), properties:[CBCharacteristicProperties.notify,CBCharacteristicProperties.read,CBCharacteristicProperties.writeWithoutResponse], value: nil, permissions: [CBAttributePermissions.readable,CBAttributePermissions.writeable])
        
        self.caracteristica?.descriptors = [userDesc]
        
        if let car = self.caracteristica {
            self.servei = CBMutableService(type: CBUUID(string: self.serviceId), primary: true)
        
            if let serv = self.servei {
                serv.characteristics = [car]
                self.manager.add(serv)
               
             }
        }
    }
    
    func startTransmiting(){
        
        let dict : Dictionary = [CBAdvertisementDataServiceUUIDsKey : [CBUUID(string: self.serviceId)],
            CBAdvertisementDataLocalNameKey : "NOE002"] as [String : Any]
        
        self.manager.startAdvertising(dict)
        self.transmiting = true

        
    }
    
    func stopTransmiting(){
        
        self.manager.stopAdvertising()
        self.transmiting = false
        
    }
}
