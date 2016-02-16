//
//  BLENinebotConnectionDelegate.swift
//  NinebotClientTest
//
//  Created by Francisco Gorina Vanrell on 12/2/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

import Foundation
import CoreBluetooth

@objc protocol BLENinebotConnectionDelegate {

    func deviceConnected(peripheral : CBPeripheral )
    func deviceDisconnectedConnected(peripheral : CBPeripheral )
    func charUpdated(char : CBCharacteristic, data: NSData)

}