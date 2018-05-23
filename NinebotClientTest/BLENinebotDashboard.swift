//
//  BLENinebotDashboard.swift
//  NinebotClientTest
//
//  Created by Francisco Gorina Vanrell on 8/2/16.
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


class BLENinebotDashboard: UITableViewController {
    
    @IBOutlet weak var titleField   : UINavigationItem!
    weak var ninebot : BLENinebot?
    weak var delegate : ViewController?
    var client : BLESimulatedClient?
    
    var devSelector : BLEDeviceSelector?
    var devList = [CBPeripheral]()
    
    var searching = false
    
    // Connected is not necessary because when disconnected client is nill
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.initNotifications()

    
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initNotifications()    
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        //self.updateTitle(nil)
        //self.update(nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Notification support
    
    func initNotifications()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(BLENinebotDashboard.updateTitle(_:)), name: NSNotification.Name(rawValue: BLESimulatedClient.kHeaderDataReadyNotification), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(BLENinebotDashboard.update(_:)), name: NSNotification.Name(rawValue: BLESimulatedClient.kNinebotDataUpdatedNotification), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(BLENinebotDashboard.listDevices(_:)), name: NSNotification.Name(rawValue: BLESimulatedClient.kdevicesDiscoveredNotification), object: nil)

    }

    func update(_ not : Notification?){
        self.tableView.reloadData()
    }
    
    
    func updateTitle(_ not : Notification?){
        
        if let nb = ninebot {
            
            if nb.data[16].value != -1 {
            
                let sn = nb.serialNo()
                let v1 = nb.version()
            
                let title = String(format:"%@ (%d.%d.%d)", sn, v1.0, v1.1, v1.2)
            
                self.titleField.title = title
            } else {
                self.titleField.title = "Connecting"
            }
        }
    }

    // MARK: Device Selection
    
    
    func listDevices(_ notification: Notification){
        
        let devices = notification.userInfo?["peripherals"] as? [CBPeripheral]
        
        // if searching is false we must create a selector
        
        if let devs = devices {
        
            if !self.searching{
 
                self.devList.removeAll()    // Remove old ones
                self.devList.append(contentsOf: devs)
                
                self.performSegue(withIdentifier: "deviceSelectorSegue", sender: self)
            }
            else{
                if let vc = self.devSelector{
                    vc.addDevices(devs)
                }
                
            }
        }
    }
    
    func connect(){
        
        self.client = BLESimulatedClient()
        
        if let cli = self.client{
            cli.datos = self.ninebot
            if let dele = delegate {
                cli.timerStep = dele.timerStep
            }
        }
    }
    
    @IBAction func stop(_ src: AnyObject){
        
        if let cli = self.client{
            cli.stop()
        }
        self.client = nil // Release all data
    }
    
    func connectToPeripheral(_ peripheral : CBPeripheral){
        
        if let cli = self.client{
            cli.connection.connectPeripheral(peripheral)
        }
        self.dismiss(animated: true) { () -> Void in
            
            self.searching = false
            self.devSelector = nil
            self.devList.removeAll()
        }
            
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
       
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       
        
        switch(section){
            
        case 0 :
            return 5
            
        case 1 :
            return 7
            
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch(section){
        case 0:
            return "Technical Info"
            
        case 1:
            return "General Info"
            
        default:
            return "--- ??? ---"
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "dashboardCellIdentifier", for: indexPath)
        
        if let nb = self.ninebot{
            
            let section = indexPath.section
            let i = indexPath.row
            
            if  section == 0 {
                switch(i) {
                    
                case 0:
                    
                    let v = nb.speed()
                    cell.textLabel!.text = "Speed"
                    cell.detailTextLabel!.text = String(format:"%5.2f Km/h", v)
                    
                    if v >= 15.0 && v < 20.0{
                        cell.detailTextLabel!.textColor = UIColor.orange
                    }else if v > 20.0 {
                        cell.detailTextLabel!.textColor = UIColor.red
                    }else{
                        cell.detailTextLabel!.textColor = UIColor.black
                    }
                    
                    
                case 1:
                    cell.textLabel!.text = "Voltage"
                    cell.detailTextLabel!.text = String(format:"%5.2f V", nb.voltage())
                    
                    
                case 2:
                    cell.textLabel!.text = "Current"
                    cell.detailTextLabel!.text = String(format:"%5.2f A", nb.current())
                    
                case 3:
                    cell.textLabel!.text = "Pitch"
                    cell.detailTextLabel!.text = String(format:"%5.2f º", nb.pitch())
                    
                case 4:
                    cell.textLabel!.text = "Roll"
                    cell.detailTextLabel!.text = String(format:"%5.2f º", nb.roll())
                    
                default:
                    
                    cell.textLabel!.text = "Unknown"
                    cell.detailTextLabel!.text = ""
                    
                }
            }
            else if section == 1{
                
                switch(i) {
                    
                case 0:
                    cell.textLabel!.text = "Distance"
                    cell.detailTextLabel!.text = String(format:"%6.2f Km", nb.singleMileage())
                    
                    
                case 1:
                    
                    let (h, m, s) = nb.singleRuntimeHMS()
                    cell.textLabel!.text = "Time"
                    cell.detailTextLabel!.text = String(format:"%02d:%02d:%02d", h, m, s)
                    
                    
                case 2:
                    cell.textLabel!.text = "Total Distance"
                    cell.detailTextLabel!.text = String(format:"%6.2f Km", nb.totalMileage())
                    
                case 3:
                    
                    let (h, m, s) = nb.totalRuntimeHMS()
                    cell.textLabel!.text = "Total Time Running"
                    cell.detailTextLabel!.text = String(format:"%02d:%02d:%02d", h, m, s)
                  
                    
                case 4:
                    cell.textLabel!.text = "Remaining Distance"
                    cell.detailTextLabel!.text = String(format:"%6.2f Km", nb.remainingMileage())
                    
                case 5:
                    cell.textLabel!.text = "Battery level"
                    cell.detailTextLabel!.text = String(format:"%4.0f %%", nb.batteryLevel())
                    
                    
                case 6:
                    cell.textLabel!.text = "Temperature"
                    cell.detailTextLabel!.text = String(format:"%4.1f ºC", nb.temperature())
                  
                default:
                    
                    cell.textLabel!.text = "Unknown"
                    cell.detailTextLabel!.text = ""
                    
                }
                
            }
        }
        
        return cell
    }
    
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return false if you do not want the specified item to be editable.
    return true
    }
    */
    
    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if editingStyle == .Delete {
    // Delete the row from the data source
    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
    } else if editingStyle == .Insert {
    // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
    }
    */
    
    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
    
    }
    */
    
    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return false if you do not want the item to be re-orderable.
    return true
    }
    */
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "turnSegueIdentifier" {
            if let vc = segue.destination as? GraphViewController  {
                vc.ninebot = self.ninebot
                vc.delegate = self
            }
    
        }
        else if segue.identifier == "deviceSelectorSegue" {
            
            if let vc = segue.destination as? BLEDeviceSelector{
                
                self.devSelector = vc
                vc.addDevices(self.devList)
                vc.delegate = self
                self.devList.removeAll()
                self.searching = true

            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if size.width > size.height{
        
            self.performSegue(withIdentifier: "turnSegueIdentifier", sender: self)
        }
    }
}
