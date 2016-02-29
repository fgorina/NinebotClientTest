//
//  BLEDeviceSelector.swift
//  NinebotClientTest
//
//  Created by Francisco Gorina Vanrell on 13/2/16.
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

class BLEDeviceSelector: UIViewController {
    
    @IBOutlet weak var tableView : UITableView?
    
    var devices : [CBPeripheral] = [CBPeripheral] ()
    weak var delegate : BLENinebotDashboard?
    
    
    func clearDevices(){
        self.devices.removeAll()
    }
    
    func addDevices(devices : [CBPeripheral]){
        self.devices.appendContentsOf(devices)
        
        if let table = self.tableView{
            table.reloadData()
        }
    }
    
    func deviceSelected(peripheral:CBPeripheral){
        
        if let dele = self.delegate {
            dele.connectToPeripheral(peripheral)
        }
         
    }
}

extension BLEDeviceSelector : UITableViewDataSource{
    

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return self.devices.count
        }else{
            return 0
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("peripheralCellIdentifier", forIndexPath: indexPath)
        
        let name = self.devices[indexPath.row].name
    
        if let nam = name {
            cell.textLabel!.text = nam 
        }
        
        return cell
    }
}

extension BLEDeviceSelector : UITableViewDelegate{
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
        let peripheral = self.devices[indexPath.row]
        self.deviceSelected(peripheral)
    }

}