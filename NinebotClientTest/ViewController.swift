//
//  ViewController.swift
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

class ViewController: UIViewController , UITableViewDataSource, UITableViewDelegate{
    
    
    
    
    enum stateValues {
        case Waiting
        case MiM
        case Client
        case Server
        
    }
    
    struct fileSection {
        
        var section : Int
        var description : String
        var files : [NSURL]
    }
    
    
    var ninebot : BLENinebot = BLENinebot()
    var server : BLESimulatedServer?
    var client : BLESimulatedClient?
    
    var state : stateValues = .Waiting
    
    var firstField = 185      // Primer camp a llegir
    var nFields = 10         // Numero de camps a llegir
    var timerStep = 0.01   // Segons per repetir el enviar
    
    
    
    var dashboard : BLENinebotDashboard?
    
    var files = [NSURL]()
    var sections = [fileSection]()
    var actualDir : NSURL?
    var currentFile : NSURL?
    
    @IBOutlet weak var tableView : UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let editButton = self.editButtonItem();
        editButton.target = self
        editButton.action = "editFiles:"
        self.navigationItem.leftBarButtonItem = editButton;
        // Lookup files
        let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        
        let docsUrl = appDelegate?.applicationDocumentsDirectory()
        
        if let docs = docsUrl{
            
            loadLocalDirectoryData(docs)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func creationDate(url : NSURL) -> NSDate?{
        var rsrc : AnyObject? = nil
        
        do{
            try url.getResourceValue(&rsrc, forKey: NSURLCreationDateKey)
        }
        catch{
            NSLog("Error reading creation date of file %", url)
        }
        
        let date = rsrc as? NSDate
        
        return date
        
    }
    
    
    func dateToSection(dat : NSDate) -> Int{
        
        let today = NSDate()
        
        let calendar = NSCalendar.currentCalendar()
        
        if calendar.isDateInToday(dat){
            return 0
        }
            
        else if calendar.isDateInYesterday(dat){
            return 1
        }
            
        else if calendar.isDate(today, equalToDate: dat, toUnitGranularity: NSCalendarUnit.WeekOfYear){
            return 2
        }
        else if calendar.isDate(today, equalToDate: dat, toUnitGranularity: NSCalendarUnit.Month){
            return 3
        }
        
        // OK, here we have the normal ones. Now for older in same year we return the
        // month of the year
        
        
        let todayComponents = calendar.components(NSCalendarUnit.Day, fromDate: today)
        
        let dateComponents = calendar.components(NSCalendarUnit.Day, fromDate: today)
        
        if dateComponents.year == todayComponents.year {
            return 3 + todayComponents.month - dateComponents.month
        }
        
        // OK now we return just the difference in years. January of this year was
        
        return 2 + todayComponents.month + todayComponents.year - dateComponents.year
        
        
        
    }
    
    func sectionLabel(section : Int) -> String{
        
        let today = NSDate()
        
        let todayComponents = NSCalendar.currentCalendar().components(NSCalendarUnit.Day, fromDate: today)
        
        
        switch section {
            
        case 0 : return "Today"
            
        case 1:
            return "Yesterday"
            
        case 2:
            return "This Week"
            
        case 3:
            return "This Month"
            
        case 4..<(3 + todayComponents.month) :
            
            let month =  todayComponents.month + 2 - section // Indexed at 0
            let df = NSDateFormatter()
            return df.standaloneMonthSymbols[month]
            
        default :
            return String(todayComponents.year - (section - 2 - todayComponents.month))
            
            
        }
        
    }
    
    func sortFilesIntoSections(files:[NSURL]){
        
        
        self.sections.removeAll()   // Clear all section
        
        for f in files {
            
            let date = self.creationDate(f)
            
            if let d = date{
                
                let s = self.dateToSection(d)
                
                
                while self.sections.count - 1 < s{
                    
                    let newSection = self.sections.count
                    self.sections.append(fileSection(section: newSection, description: self.sectionLabel(newSection), files: [NSURL]()))
                    
                }
                
                self.sections[s].files.append(f)
            }
        }
        
        var i = 0
        
        while i < self.sections.count {
            
            if self.sections[i].files.count == 0{
                self.sections.removeAtIndex(i)
            }else{
                i++
            }
        }
    }
    
    func loadLocalDirectoryData(dir : NSURL){
        
        self.actualDir = dir
        
        files.removeAll()
        
        let mgr = NSFileManager()
        
        
        let enumerator = mgr.enumeratorAtURL(dir, includingPropertiesForKeys: nil, options: [NSDirectoryEnumerationOptions.SkipsHiddenFiles, NSDirectoryEnumerationOptions.SkipsSubdirectoryDescendants]) { (url:NSURL, err:NSError) -> Bool in
            NSLog("Error enumerating files %@", err)
            return true
        }
        
        if let arch = enumerator{
            
            for url in arch {
                
                files.append(url as! NSURL)
                
            }
        }
        
        // OK ara hauriem de ordenar els documents
        
        files.sortInPlace { (url1: NSURL, url2: NSURL) -> Bool in
            
            let date1 = self.creationDate(url1)
            let date2 = self.creationDate(url2)
            
            if let dat1 = date1, dat2 = date2 {
                return dat1.timeIntervalSince1970 > dat2.timeIntervalSince1970
            }
            else{
                return true
            }
            
        }
        
        self.sortFilesIntoSections(self.files)
        
        
    }
    
    func urlForIndexPath(indexPath: NSIndexPath) -> NSURL?{
        
        if indexPath.section < self.sections.count {
            let section = self.sections[indexPath.section]
            if indexPath.row < section.files.count{
                let url = section.files[indexPath.row]
                return url
            }
        }
        return nil
        
    }
    
    @IBAction func MiM(){
        
    }
    
    
    @IBAction func Server(){
    }
    
    @IBAction func Client(){
    }
    
    
    func startClient (){
    }
    
    func stopClient(){
        
    }
    
    
    @IBAction func openSettings(src : AnyObject){
    
     let but = src as? UIButton
        
        let alert = UIAlertController(title: "Options", message: "Select an option", preferredStyle: UIAlertControllerStyle.ActionSheet);
        
        alert.popoverPresentationController?.sourceView = but
        
        var action = UIAlertAction(title: "Close", style: UIAlertActionStyle.Cancel) { (action: UIAlertAction) -> Void in
            
            
        }
        alert.addAction(action)
        
        action = UIAlertAction(title: "Settings", style: UIAlertActionStyle.Default, handler: { (action : UIAlertAction) -> Void in
            self.performSegueWithIdentifier("settingsSegue", sender: self)
        })
    
        alert.addAction(action)
    
        
        action = UIAlertAction(title: "Debug Server", style: UIAlertActionStyle.Default, handler: { (action : UIAlertAction) -> Void in
            
            self.performSegueWithIdentifier("mimSegue", sender: self)
        })
        
        alert.addAction(action)
        
        action = UIAlertAction(title: "About 9B Metrics", style: UIAlertActionStyle.Default, handler: { (action : UIAlertAction) -> Void in
            self.performSegueWithIdentifier("docSegue", sender: self)   
        })
        
        alert.addAction(action)

        
        
        self.presentViewController(alert, animated: true) { () -> Void in
            
            
        }
    
    }
    
    
    // MARK: UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return self.sections.count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?{
        if section < self.sections.count{
            return self.sections[section].description
        }else{
            return "Unknown"
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section < self.sections.count{
            return self.sections[section].files.count
        }else{
            return 0
        }
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("fileCellIdentifier", forIndexPath: indexPath)
        
        let urls = urlForIndexPath(indexPath)
        
        if let url = urls {
            
            let name = NSFileManager.defaultManager().displayNameAtPath(url.path!)
            let date = self.creationDate(url)
            
            cell.textLabel!.text = name
            
            if let dat = date {
                
                let fmt = NSDateFormatter()
                fmt.dateStyle = NSDateFormatterStyle.ShortStyle
                fmt.timeStyle = NSDateFormatterStyle.ShortStyle
                
                let s = fmt.stringFromDate(dat)
                
                cell.detailTextLabel!.text = s
            }
        }
        
        return cell
    }
    
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 28
    }
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
    // MARK: UITableViewDelegate
    
    
    // Override to support editing the table view.
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == .Delete {
            
            let url = self.sections[indexPath.section].files[indexPath.row]
            
            let mgr = NSFileManager.defaultManager()
            do {
                try mgr.removeItemAtURL(url)
                
                self.sections[indexPath.section].files.removeAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                
                if self.sections[indexPath.section].files.count == 0{
                    self.sections.removeAtIndex(indexPath.section)
                    tableView.deleteSections(NSIndexSet(index: indexPath.section), withRowAnimation: UITableViewRowAnimation.Automatic)
                }
           }catch{
                NSLog("Error removing %@", url)
            }
            // Delete the row from the data source
            
            
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    
    
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        
        let urls = urlForIndexPath(indexPath)
        
        if let url = urls {
            
            self.currentFile = url
            
            var srcView : UIView = tableView
            
            let cellView = tableView.cellForRowAtIndexPath(indexPath)
            
            if let cv = cellView   {
                
                srcView = cv
                
                for v in cv.subviews{
                    if v.isKindOfClass(UIButton){
                        srcView = v
                    }
                }
            }
             
            self.shareData(self.currentFile, src: srcView)
        }
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let urls = urlForIndexPath(indexPath)
        
        if let url = urls {
            
            self.currentFile = url
            
            if let file = self.currentFile{
                self.ninebot.loadTextFile(file)
            }
            
            
            self.performSegueWithIdentifier("openFileSegue", sender: self)
        }
    }
    
    
    // MARK : Navigatiom
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "dashboardSegue" {
            if let dash = segue.destinationViewController as? BLENinebotDashboard{
                dash.delegate = self
                self.ninebot.clearAll()
                dash.ninebot = self.ninebot
                self.dashboard = dash
                dash.connect()
                
            }
        }else if segue.identifier == "openFileSegue"{
            if let dash = segue.destinationViewController as? BLENinebotDashboard{
                dash.delegate = self
                dash.ninebot = self.ninebot
                self.dashboard = dash
                
                //self.startClient() // Tan sols en algun cas potser depenent del sender?
                
            }
        }else if segue.identifier == "settingsSegue"{
        
            if let settings = segue.destinationViewController as? SettingsViewController{
                
                settings.delegate = self
            }
        
        
        }
    }
    
    // MARK: Feedback
    
    func serverStarted(){
        
    }
    
    
    func serverStopped(){
        
    }
    
    func clientStarted(){
    }
    
    func clientStopped(){
        
        let aFile = self.ninebot.createTextFile()
        self.shareData(aFile, src: self.tableView)
        
    }
    
    @IBAction func  editFiles(src: AnyObject){
        if self.tableView.editing{
            self.tableView.editing = false
            self.navigationItem.leftBarButtonItem!.title  = "Edit"
            self.navigationItem.leftBarButtonItem!.style = UIBarButtonItemStyle.Plain
        }
        else{
            self.tableView.editing = true
            self.navigationItem.leftBarButtonItem!.title = "Done"
            self.navigationItem.leftBarButtonItem!.style = UIBarButtonItemStyle.Done
        }
        
    }
    
    // Create a file with actual data and share it
    
    func shareData(file: NSURL?, src:AnyObject){
        
        
        if let aFile = file {
            
            
            let activityViewController = UIActivityViewController(
                activityItems: [aFile.lastPathComponent!,   aFile],
                applicationActivities: [PickerActivity()])
            
            
            activityViewController.completionWithItemsHandler = {(a : String?, completed:Bool, objects:[AnyObject]?, error:NSError?) in
                
            }
            
            activityViewController.popoverPresentationController?.sourceView = src as? UIView
            
            activityViewController.modalPresentationStyle = UIModalPresentationStyle.Popover
             
            self.presentViewController(activityViewController,
                animated: true,
                completion: nil)
            
        }
        
    }
    
    
    // MARK: Other functions
    
    func appendToLog(s : String){
        //
        //self.tview.text = self.tview.text + "\n" + s
    }
    
    
    
    
    //MARK: View management
    
    override func viewWillAppear(animated: Bool) {
        
        if let dash = self.dashboard{
            if dash.client != nil{
                dash.stop(self)
            }
            self.dashboard = nil // Released dashboard
        }
        // Now reload all data foir
        let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        
        let docsUrl = appDelegate?.applicationDocumentsDirectory()
        
        if let docs = docsUrl{
            
            loadLocalDirectoryData(docs)
            self.tableView.reloadData()
        }
    }
    
}


