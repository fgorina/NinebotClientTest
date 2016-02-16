//
//  BLENinebotServerDelegate.swift
//  NinebotClientTest
//
//  Created by Francisco Gorina Vanrell on 15/2/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

import Foundation
import CoreBluetooth

@objc protocol BLENinebotServerDelegate {
    
    func remoteDeviceSubscribedToCharacteristic(characteristic : CBCharacteristic, central : CBCentral)
    func remoteDeviceUnsubscribedToCharacteristic(characteristic : CBCharacteristic, central : CBCentral)
    func writeReceived(char : CBCharacteristic, data: NSData)
    
}