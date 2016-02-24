//
//  BLENinebotServerDelegate.swift
//  NinebotClientTest
//
//  Created by Francisco Gorina Vanrell on 15/2/16.
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


import Foundation
import CoreBluetooth

@objc protocol BLENinebotServerDelegate {
    
    func remoteDeviceSubscribedToCharacteristic(characteristic : CBCharacteristic, central : CBCentral)
    func remoteDeviceUnsubscribedToCharacteristic(characteristic : CBCharacteristic, central : CBCentral)
    func writeReceived(char : CBCharacteristic, data: NSData)
    
}