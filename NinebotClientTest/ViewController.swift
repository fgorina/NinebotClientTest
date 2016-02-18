//
//  ViewController.swift
//  NinebotClientTest
//
//  Created by Francisco Gorina Vanrell on 2/2/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

import UIKit

class ViewController: UIViewController , UITableViewDataSource, UITableViewDelegate{
    
    enum stateValues {
        case Waiting
        case MiM
        case Client
        case Server
    
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
    
    // MARK: UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.files.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("fileCellIdentifier", forIndexPath: indexPath)
        
        let url = files[indexPath.row]
        
        let name = NSFileManager.defaultManager().displayNameAtPath(url.path!)
        var rsrc : AnyObject? = nil
        
        do{
            try url.getResourceValue(&rsrc, forKey: NSURLCreationDateKey)
        }
        catch{
            NSLog("Error reading creation date of file %", url)
        }
        
        let date = rsrc as? NSDate
        
        cell.textLabel!.text = name
        
        if let dat = date {
        
            let fmt = NSDateFormatter()
            fmt.dateStyle = NSDateFormatterStyle.ShortStyle
            fmt.timeStyle = NSDateFormatterStyle.ShortStyle
        
            let s = fmt.stringFromDate(dat)
            
            cell.detailTextLabel!.text = s
        }
        
        
         return cell
    }
    
  
    // MARK: UITableViewDelegate
    
    
    // Override to support editing the table view.
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
    if editingStyle == .Delete {
        let url = self.files[indexPath.row]
        
        let mgr = NSFileManager.defaultManager()
        do {
            try mgr.removeItemAtURL(url)
            self.files.removeAtIndex(indexPath.row)
            //tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        }catch{
            NSLog("Error removing %@", url)
        }
    // Delete the row from the data source
    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
    } else if editingStyle == .Insert {
    // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
    }
    

    
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        
        self.currentFile = self.files[indexPath.row]
        self.shareData(self.currentFile, src: tableView)
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        self.currentFile = self.files[indexPath.row]
        
        if let file = self.currentFile{
            self.ninebot.loadTextFile(file)
        }
        
        
        self.performSegueWithIdentifier("openFileSegue", sender: self)
    }
    
 
    // MARK : Navigatiom
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "dashboardSegue" {
             if let dash = segue.destinationViewController as? BLENinebotDashboard{
                dash.delegate = self
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
            
            activityViewController.modalPresentationStyle = UIModalPresentationStyle.FormSheet
            
        
            
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

