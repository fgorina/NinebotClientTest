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
        case waiting
        case miM
        case client
        case server
        
    }
    
    struct fileSection {
        
        var section : Int
        var description : String
        var files : [URL]
    }
    
    
    var ninebot : BLENinebot = BLENinebot()
    var server : BLESimulatedServer?
    var client : BLESimulatedClient?
    
    var state : stateValues = .waiting
    
    var firstField = 185      // Primer camp a llegir
    var nFields = 10         // Numero de camps a llegir
    var timerStep = 0.01   // Segons per repetir el enviar
    
    
    
    var dashboard : BLENinebotDashboard?
    
    var files = [URL]()
    var sections = [fileSection]()
    var actualDir : URL?
    var currentFile : URL?
    
    @IBOutlet weak var tableView : UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let editButton = self.editButtonItem;
        editButton.target = self
        editButton.action = #selector(ViewController.editFiles(_:))
        self.navigationItem.leftBarButtonItem = editButton;
        // Lookup files
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        let docsUrl = appDelegate?.applicationDocumentsDirectory()
        
        if let docs = docsUrl{
            
            loadLocalDirectoryData(docs as URL)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func creationDate(_ url : URL) -> Date?{
        var rsrc : AnyObject? = nil
        
        do{
            try (url as NSURL).getResourceValue(&rsrc, forKey: URLResourceKey.creationDateKey)
        }
        catch{
            print("Error reading creation date of file %", url)
        }
        
        let date = rsrc as? Date
        
        return date
        
    }
    
    
    func dateToSection(_ dat : Date) -> Int{
        
        let today = Date()
        
        let calendar = Calendar.current
        
        if calendar.isDateInToday(dat){
            return 0
        }
            
        else if calendar.isDateInYesterday(dat){
            return 1
        }
            
        else if (calendar as NSCalendar).isDate(today, equalTo: dat, toUnitGranularity: NSCalendar.Unit.weekOfYear){
            return 2
        }
        else if (calendar as NSCalendar).isDate(today, equalTo: dat, toUnitGranularity: NSCalendar.Unit.month){
            return 3
        }
        
        // OK, here we have the normal ones. Now for older in same year we return the
        // month of the year
        
        
        let todayComponents = (calendar as NSCalendar).components(NSCalendar.Unit.day, from: today)
        
        let dateComponents = (calendar as NSCalendar).components(NSCalendar.Unit.day, from: today)
        
        if dateComponents.year == todayComponents.year {
            return 3 + todayComponents.month! - dateComponents.month!
        }
        
        // OK now we return just the difference in years. January of this year was
        
        return 2 + todayComponents.month! + todayComponents.year! - dateComponents.year!
        
        
        
    }
    
    func sectionLabel(_ section : Int) -> String{
        
        let today = Date()
        
        let todayComponents = (Calendar.current as NSCalendar).components(NSCalendar.Unit.day, from: today)
        
        
        switch section {
            
        case 0 : return "Today"
            
        case 1:
            return "Yesterday"
            
        case 2:
            return "This Week"
            
        case 3:
            return "This Month"
            
        case 4..<(3 + todayComponents.month!) :
            
            let month =  todayComponents.month! + 2 - section // Indexed at 0
            let df = DateFormatter()
            return df.standaloneMonthSymbols[month]
            
        default :
            return String(todayComponents.year! - (section - 2 - todayComponents.month!))
            
            
        }
        
    }
    
    func sortFilesIntoSections(_ files:[URL]){
        
        
        self.sections.removeAll()   // Clear all section
        
        for f in files {
            
            let date = self.creationDate(f)
            
            if let d = date{
                
                let s = self.dateToSection(d)
                
                
                while self.sections.count - 1 < s{
                    
                    let newSection = self.sections.count
                    self.sections.append(fileSection(section: newSection, description: self.sectionLabel(newSection), files: [URL]()))
                    
                }
                
                self.sections[s].files.append(f)
            }
        }
        
        var i = 0
        
        while i < self.sections.count {
            
            if self.sections[i].files.count == 0{
                self.sections.remove(at: i)
            }else{
                i += 1
            }
        }
    }
    
    func loadLocalDirectoryData(_ dir : URL){
        
        self.actualDir = dir
        
        files.removeAll()
        
        let mgr = FileManager()
        
        let enumerator = mgr.enumerator(at: dir, includingPropertiesForKeys: nil, options: [FileManager.DirectoryEnumerationOptions.skipsHiddenFiles, FileManager.DirectoryEnumerationOptions.skipsSubdirectoryDescendants]) { (url:URL, err:Error) -> Bool in
            print("Error enumerating files %@", err)
            return true
        }
        
        if let arch = enumerator{
            
            for url in arch {
                
                files.append(url as! URL)
                
            }
        }
        
        // OK ara hauriem de ordenar els documents
        
        files.sort { (url1: URL, url2: URL) -> Bool in
            
            let date1 = self.creationDate(url1)
            let date2 = self.creationDate(url2)
            
            if let dat1 = date1, let dat2 = date2 {
                return dat1.timeIntervalSince1970 > dat2.timeIntervalSince1970
            }
            else{
                return true
            }
            
        }
        
        self.sortFilesIntoSections(self.files)
        
        
    }
    
    func urlForIndexPath(_ indexPath: IndexPath) -> URL?{
        
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
    
    
    @IBAction func openSettings(_ src : AnyObject){
    
     let but = src as? UIButton
        
        let alert = UIAlertController(title: "Options", message: "Select an option", preferredStyle: UIAlertControllerStyle.actionSheet);
        
        alert.popoverPresentationController?.sourceView = but
        
        var action = UIAlertAction(title: "Close", style: UIAlertActionStyle.cancel) { (action: UIAlertAction) -> Void in
            
            
        }
        alert.addAction(action)
        
        action = UIAlertAction(title: "Settings", style: UIAlertActionStyle.default, handler: { (action : UIAlertAction) -> Void in
            self.performSegue(withIdentifier: "settingsSegue", sender: self)
        })
    
        alert.addAction(action)
    
        
        action = UIAlertAction(title: "Debug Server", style: UIAlertActionStyle.default, handler: { (action : UIAlertAction) -> Void in
            
            self.performSegue(withIdentifier: "mimSegue", sender: self)
        })
        
        alert.addAction(action)
        
        action = UIAlertAction(title: "About 9B Metrics", style: UIAlertActionStyle.default, handler: { (action : UIAlertAction) -> Void in
            self.performSegue(withIdentifier: "docSegue", sender: self)   
        })
        
        alert.addAction(action)

        
        
        self.present(alert, animated: true) { () -> Void in
            
            
        }
    
    }
    
    
    // MARK: UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return self.sections.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?{
        if section < self.sections.count{
            return self.sections[section].description
        }else{
            return "Unknown"
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section < self.sections.count{
            return self.sections[section].files.count
        }else{
            return 0
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fileCellIdentifier", for: indexPath)
        
        let urls = urlForIndexPath(indexPath)
        
        if let url = urls {
            
            let name = FileManager.default.displayName(atPath: url.path)
            let date = self.creationDate(url)
            
            cell.textLabel!.text = name
            
            if let dat = date {
                
                let fmt = DateFormatter()
                fmt.dateStyle = DateFormatter.Style.short
                fmt.timeStyle = DateFormatter.Style.short
                
                let s = fmt.string(from: dat)
                
                cell.detailTextLabel!.text = s
            }
        }
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 28
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
    // MARK: UITableViewDelegate
    
    
    // Override to support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            let url = self.sections[indexPath.section].files[indexPath.row]
            
            let mgr = FileManager.default
            do {
                try mgr.removeItem(at: url)
                
                self.sections[indexPath.section].files.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                
                if self.sections[indexPath.section].files.count == 0{
                    self.sections.remove(at: indexPath.section)
                    tableView.deleteSections(IndexSet(integer: indexPath.section), with: UITableViewRowAnimation.automatic)
                }
           }catch{
                print("Error removing %@", url)
            }
            // Delete the row from the data source
            
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        
        let urls = urlForIndexPath(indexPath)
        
        if let url = urls {
            
            self.currentFile = url
            
            var srcView : UIView = tableView
            
            let cellView = tableView.cellForRow(at: indexPath)
            
            if let cv = cellView   {
                
                srcView = cv
                
                for v in cv.subviews{
                    if v.isKind(of: UIButton.self){
                        srcView = v
                    }
                }
            }
             
            self.shareData(self.currentFile, src: srcView)
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.tableView.deselectRow(at: indexPath, animated: true)
        
        let urls = urlForIndexPath(indexPath)
        
        if let url = urls {
            
            self.currentFile = url
            
            if let file = self.currentFile{
                self.ninebot.loadTextFile(file)
            }
            
            
            self.performSegue(withIdentifier: "openFileSegue", sender: self)
        }
    }
    
    
    // MARK : Navigatiom
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "dashboardSegue" {
            if let dash = segue.destination as? BLENinebotDashboard{
                dash.delegate = self
                self.ninebot.clearAll()
                dash.ninebot = self.ninebot
                self.dashboard = dash
                dash.connect()
                
            }
        }else if segue.identifier == "openFileSegue"{
            if let dash = segue.destination as? BLENinebotDashboard{
                dash.delegate = self
                dash.ninebot = self.ninebot
                self.dashboard = dash
                
                //self.startClient() // Tan sols en algun cas potser depenent del sender?
                
            }
        }else if segue.identifier == "settingsSegue"{
        
            if let settings = segue.destination as? SettingsViewController{
                
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
        self.shareData(aFile as! URL, src: self.tableView)
        
    }
    
    @IBAction func  editFiles(_ src: AnyObject){
        if self.tableView.isEditing{
            self.tableView.isEditing = false
            self.navigationItem.leftBarButtonItem!.title  = "Edit"
            self.navigationItem.leftBarButtonItem!.style = UIBarButtonItemStyle.plain
        }
        else{
            self.tableView.isEditing = true
            self.navigationItem.leftBarButtonItem!.title = "Done"
            self.navigationItem.leftBarButtonItem!.style = UIBarButtonItemStyle.done
        }
        
    }
    
    // Create a file with actual data and share it
    
    func shareData(_ file: URL?, src:AnyObject){
        
        
        if let aFile = file {
            
            
            let activityViewController = UIActivityViewController(
                activityItems: [aFile.lastPathComponent,   aFile],
                applicationActivities: [PickerActivity()])
            
            
            activityViewController.completionWithItemsHandler = {
                (a : UIActivityType?, completed:Bool, objects:[Any]?, error:Error?) in
                
            }
            
            activityViewController.popoverPresentationController?.sourceView = src as? UIView
            
            activityViewController.modalPresentationStyle = UIModalPresentationStyle.popover
             
            self.present(activityViewController,
                animated: true,
                completion: nil)
            
        }
        
    }
    
    
    // MARK: Other functions
    
    func appendToLog(_ s : String){
        //
        //self.tview.text = self.tview.text + "\n" + s
    }
    
    
    
    
    //MARK: View management
    
    override func viewWillAppear(_ animated: Bool) {
        
        if let dash = self.dashboard{
            if dash.client != nil{
                dash.stop(self)
            }
            self.dashboard = nil // Released dashboard
        }
        // Now reload all data foir
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        let docsUrl = appDelegate?.applicationDocumentsDirectory()
        
        if let docs = docsUrl{
            
            loadLocalDirectoryData(docs as URL)
            self.tableView.reloadData()
        }
    }
    
}


