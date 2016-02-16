//
//  BLEDeviceSelector.swift
//  NinebotClientTest
//
//  Created by Francisco Gorina Vanrell on 13/2/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

import UIKit
import CoreBluetooth

class BLEDeviceSelector: UITableViewController {
    
    var devices : [CBPeripheral] = [CBPeripheral] ()
    weak var delegate : BLENinebotDashboard?
    
    
    func clearDevices(){
        self.devices.removeAll()
    }
    
    func addDevices(devices : [CBPeripheral]){
        self.devices.appendContentsOf(devices)
        self.tableView.reloadData()
    }
    
    func deviceSelected(peripheral:CBPeripheral){
        
        if let dele = self.delegate {
            dele.connectToPeripheral(peripheral)
        }
         
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return devices.count
        }else{
            return 0
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("peripheralCellIdentifier", forIndexPath: indexPath)
        
        let name = devices[indexPath.row].name
    
        if let nam = name {
            cell.textLabel!.text = nam 
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
        let peripheral = self.devices[indexPath.row]
        self.deviceSelected(peripheral)
    }
    
    
}
