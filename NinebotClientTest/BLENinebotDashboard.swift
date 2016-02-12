//
//  BLENinebotDashboard.swift
//  NinebotClientTest
//
//  Created by Francisco Gorina Vanrell on 8/2/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

import UIKit

class BLENinebotDashboard: UITableViewController {
    
    @IBOutlet weak var titleField   : UINavigationItem!
    
    
    weak var delegate : ViewController?
    
    func update(){
        self.tableView.reloadData()
    }
    
    func updateTitle(title : String){
        
        self.titleField.title = title
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
       
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       
        
        switch(section){
            
        case 0 :
            return 5
            
        case 1 :
            return 6
            
        default:
            return 0
        }
        

        
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch(section){
        case 0:
            return "Technical Info"
            
        case 1:
            return "General Info"
            
        default:
            return "--- ??? ---"
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("dashboardCellIdentifier", forIndexPath: indexPath)
        
        if let nb = self.delegate?.datos{
            
            let section = indexPath.section
            let i = indexPath.row
            
            if  section == 0 {
                switch(i) {
                    
                case 0:
                    cell.textLabel!.text = "Speed"
                    cell.detailTextLabel!.text = String(format:"%5.2f Km/h", nb.speed())
                    
                    
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
                    cell.textLabel!.text = "Total Distance"
                    cell.detailTextLabel!.text = String(format:"%6.2f Km", nb.totalMileage())
                    
                case 2:
                    
                    let (h, m, s) = nb.totalRuntimeHMS()
                    cell.textLabel!.text = "Total Time Running"
                    cell.detailTextLabel!.text = String(format:"%02d:%02d:%02d", h, m, s)
                  
                    
                case 3:
                    cell.textLabel!.text = "Remaining Distance"
                    cell.detailTextLabel!.text = String(format:"%6.2f Km", nb.remainingMileage())
                    
                case 4:
                    cell.textLabel!.text = "Battery level"
                    cell.detailTextLabel!.text = String(format:"%4.0f %%", nb.batteryLevel())
                    
                    
                case 5:
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
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "turnSegueIdentifier" {
            if let vc = segue.destinationViewController as? GraphViewController  {
                
                if let dele = self.delegate{
                    vc.ninebot = dele.datos
                    vc.delegate = self
                }
                
            }
    
        }
    
    }
    
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        if size.width > size.height{
        
            self.performSegueWithIdentifier("turnSegueIdentifier", sender: self)
        }
    }
    
 
    
    

    
}
