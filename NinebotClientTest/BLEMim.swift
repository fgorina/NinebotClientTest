//
//  BLEMim.swift
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



import UIKit
import CoreBluetooth

class BLEMim: UIViewController {
    
    @IBOutlet weak var tableView : UITableView!
    @IBOutlet weak var startStopButton : UIBarButtonItem!
    @IBOutlet weak var ninebotButton : UIButton!
    @IBOutlet weak var iPhoneButton : UIButton!
    
    
    enum Direction : Int {
        case nb2iphone = 0
        case iphone2nb
    }
    
    struct Exchange {
        var dir : Direction = .nb2iphone
        var data : String = ""
    }
    
    let client : BLEConnection = BLEConnection()
    let server : BLESimulatedServer = BLESimulatedServer()
    
    var startDate : NSDate?
    
    var log = [Exchange]()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.setup()
    
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        self.setup()
    }
    
    override func viewDidLoad() {
        self.iPhoneButton.enabled = false
        self.ninebotButton.enabled = false
    }
    func setup(){
        
        client.delegate = self
        server.delegate = self
        
        // start connection
        self.connectToClient()
        
        // Start Connection
        // Start Server
        
        // Wait by bye
        
    }
    
    func isConnected() -> Bool{
        
        return self.client.subscribed && self.server.transmiting
        
    }
    
    func connectToClient(){
        
        // First we recover the last device and try to connect directly
        
        let store = NSUserDefaults.standardUserDefaults()
        let device = store.stringForKey(BLESimulatedClient.kLast9BDeviceAccessedKey)
        
        if let dev = device {
            self.client.connectToDeviceWithUUID(dev)
        }
    }

    func stop(){
        
        if self.client.connected{
            self.client.stopConnection()
        }
        if self.server.transmiting {
            self.server.stopTransmiting()
        }
        self.startStopButton.title = "Start"
    }
    
    func start(){
        
        if !self.client.connected {
            self.connectToClient()
        }
        if !self.server.transmiting{
            self.server.startTransmiting()
        }
        self.startStopButton.title = "Stop"

    
    }
    
    @IBAction func flip(src: AnyObject){
        
        if isConnected() {
            stop()
        }
        else{
            start()
        }
    }
    @IBAction func doSave(src: AnyObject){
        _ = self.save()
    }
    
    func save() -> NSURL?{
        
        if startDate == nil {
            startDate = NSDate()
        }
       
        let ldateFormatter = NSDateFormatter()
        let enUSPOSIXLocale = NSLocale(localeIdentifier: "en_US_POSIX")
        
        ldateFormatter.locale = enUSPOSIXLocale
        ldateFormatter.dateFormat = "'9B_'yyyyMMdd'_'HHmmss'.log'"
        let newName = ldateFormatter.stringFromDate(startDate!)
        
        let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        
        let path : String
        
        if let dele = appDelegate {
            path = (dele.applicationDocumentsDirectory()?.path)!
        }
        else
        {
            return nil
        }
        
        let tempFile = (path + "/" ).stringByAppendingString(newName )
        
        
        let mgr = NSFileManager.defaultManager()
        
        mgr.createFileAtPath(tempFile, contents: nil, attributes: nil)
        let file = NSURL.fileURLWithPath(tempFile)
        
        
        
        do{
            let hdl = try NSFileHandle(forWritingToURL: file)
            // Get time of first item
            
            ldateFormatter.dateFormat = "yyyy MM dd'_'HH:mm:ss"
           
            let s = ldateFormatter.stringFromDate(startDate!) + "\n"
            hdl.writeData(s.dataUsingEncoding(NSUTF8StringEncoding)!)
            
            
            for v in self.log {
                
                var s : String?
                
                if v.dir == .iphone2nb {
                    
                    s = String(format:"< %@\n", v.data)
                    
                }else {
                    s = String(format:"> %@\n", v.data)
                }
                
                if let vn = s!.dataUsingEncoding(NSUTF8StringEncoding){
                    hdl.writeData(vn)
                }
                
             }
            
            hdl.closeFile()
            
          return file
            
        }
        catch{
            NSLog("Error al obtenir File Handle")
        }
        
        return nil
    }
    
    func nsdata2HexString(data : NSData) -> String{
        
        
        let count = data.length
        var buffer = [UInt8](count: count, repeatedValue: 0)
        data.getBytes(&buffer, length:count * sizeof(UInt8))

        var out = ""
        
        for i in 0..<count {
            let str = String(format: "%02x", buffer[i])
            out.appendContentsOf(str)
        }
        
        return out
        
    }

}

extension BLEMim : BLENinebotConnectionDelegate{

    func deviceConnected(peripheral : CBPeripheral ){
        if let s = peripheral.name{
            NSLog("Device %@ connected", s)
            self.ninebotButton.enabled = true
            self.startDate = NSDate()
        }
    }
    func deviceDisconnectedConnected(peripheral : CBPeripheral ){
        if let s = peripheral.name{
            NSLog("Device %@ disconnected", s)
            self.ninebotButton.enabled = false
            
        }
    }
    func charUpdated(char : CBCharacteristic, data: NSData){
        self.server.updateValue(data)
        let hexdat = self.nsdata2HexString(data)
        
        let entry = Exchange(dir: .nb2iphone, data: hexdat)
        self.log.append(entry)
        self.tableView.reloadData() 

        
    }

}
extension BLEMim : BLENinebotServerDelegate {
    
    func writeReceived(char : CBCharacteristic, data: NSData){
        self.client.writeValue(data)

        let hexdat = self.nsdata2HexString(data)
        
        let entry = Exchange(dir: .iphone2nb, data: hexdat)
        self.log.append(entry)
        self.tableView.reloadData()
        
    }
    func remoteDeviceSubscribedToCharacteristic(characteristic : CBCharacteristic, central : CBCentral){
        NSLog("Device subscribed %@", central)
        self.iPhoneButton.enabled = true
    }
    func remoteDeviceUnsubscribedToCharacteristic(characteristic : CBCharacteristic, central : CBCentral){
        NSLog("Device unsubscribed %@", central)
        self.iPhoneButton.enabled = false
    }

}

extension BLEMim : UITableViewDataSource{
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.log.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("logEntryCellIdentifier", forIndexPath: indexPath)
        
        let entry = log[indexPath.row]
        
        let img : UIImage?
        
        if entry.dir == .nb2iphone{
            img = UIImage(named: "9b2iPhone")
        }
        else{
            img = UIImage(named: "iPhone29b")
        }
        
        
        if let iv = cell.imageView  {
            iv.image = img
        }
        
        
        
        cell.textLabel!.text = entry.data
        
        return cell
    }
    
    
    
}