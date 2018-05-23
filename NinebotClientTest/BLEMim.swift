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
    
    var startDate : Date?
    
    var log = [Exchange]()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.setup()
    
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        self.setup()
    }
    
    override func viewDidLoad() {
        self.iPhoneButton.isEnabled = false
        self.ninebotButton.isEnabled = false
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
        
        let store = UserDefaults.standard
        let device = store.string(forKey: BLESimulatedClient.kLast9BDeviceAccessedKey)
        
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
    
    @IBAction func flip(_ src: AnyObject){
        
        if isConnected() {
            stop()
        }
        else{
            start()
        }
    }
    @IBAction func doSave(_ src: AnyObject){
        _ = self.save()
    }
    
    func save() -> URL?{
        
        if startDate == nil {
            startDate = Date()
        }
       
        let ldateFormatter = DateFormatter()
        let enUSPOSIXLocale = Locale(identifier: "en_US_POSIX")
        
        ldateFormatter.locale = enUSPOSIXLocale
        ldateFormatter.dateFormat = "'9B_'yyyyMMdd'_'HHmmss'.log'"
        let newName = ldateFormatter.string(from: startDate!)
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        let path : String
        
        if let dele = appDelegate {
            path = (dele.applicationDocumentsDirectory()?.path)!
        }
        else
        {
            return nil
        }
        
        let tempFile = (path + "/" ) + newName
        
        
        let mgr = FileManager.default
        
        mgr.createFile(atPath: tempFile, contents: nil, attributes: nil)
        let file = URL(fileURLWithPath: tempFile)
        
        
        
        do{
            let hdl = try FileHandle(forWritingTo: file)
            // Get time of first item
            
            ldateFormatter.dateFormat = "yyyy MM dd'_'HH:mm:ss"
           
            let s = ldateFormatter.string(from: startDate!) + "\n"
            hdl.write(s.data(using: String.Encoding.utf8)!)
            
            
            for v in self.log {
                
                var s : String?
                
                if v.dir == .iphone2nb {
                    
                    s = String(format:"< %@\n", v.data)
                    
                }else {
                    s = String(format:"> %@\n", v.data)
                }
                
                if let vn = s!.data(using: String.Encoding.utf8){
                    hdl.write(vn)
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
    
    func nsdata2HexString(_ data : Data) -> String{
        
        
        let count = data.count
        var buffer = [UInt8](repeating: 0, count: count)
        (data as NSData).getBytes(&buffer, length:count * MemoryLayout<UInt8>.size)

        var out = ""
        
        for i in 0..<count {
            let str = String(format: "%02x", buffer[i])
            out.append(str)
        }
        
        return out
        
    }

}

extension BLEMim : BLENinebotConnectionDelegate{

    func deviceConnected(_ peripheral : CBPeripheral ){
        if let s = peripheral.name{
            NSLog("Device %@ connected", s)
            self.ninebotButton.isEnabled = true
            self.startDate = Date()
        }
    }
    func deviceDisconnectedConnected(_ peripheral : CBPeripheral ){
        if let s = peripheral.name{
            NSLog("Device %@ disconnected", s)
            self.ninebotButton.isEnabled = false
            
        }
    }
    func charUpdated(_ char : CBCharacteristic, data: Data){
        self.server.updateValue(data)
        let hexdat = self.nsdata2HexString(data)
        
        let entry = Exchange(dir: .nb2iphone, data: hexdat)
        self.log.append(entry)
        self.tableView.reloadData() 

        
    }

}
extension BLEMim : BLENinebotServerDelegate {
    
    func writeReceived(_ char : CBCharacteristic, data: Data){
        self.client.writeValue(data)

        let hexdat = self.nsdata2HexString(data)
        
        let entry = Exchange(dir: .iphone2nb, data: hexdat)
        self.log.append(entry)
        self.tableView.reloadData()
        
    }
    func remoteDeviceSubscribedToCharacteristic(_ characteristic : CBCharacteristic, central : CBCentral){
        NSLog("Device subscribed %@", central)
        self.iPhoneButton.isEnabled = true
    }
    func remoteDeviceUnsubscribedToCharacteristic(_ characteristic : CBCharacteristic, central : CBCentral){
        NSLog("Device unsubscribed %@", central)
        self.iPhoneButton.isEnabled = false
    }

}

extension BLEMim : UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.log.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "logEntryCellIdentifier", for: indexPath)
        
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
