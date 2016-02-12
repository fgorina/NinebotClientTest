//
//  ViewController.swift
//  NinebotClientTest
//
//  Created by Francisco Gorina Vanrell on 2/2/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    enum stateValues {
        case Waiting
        case MiM
        case Client
        case Server
    
    }
    

    
    var server : BLESimulatedServer?
    var client : BLESimulatedClient?
    
    var state : stateValues = .Waiting
    
    
    var buffer = [UInt8]()
    
    var datos = BLENinebot()
    
    var firstField = 185      // Primer camp a llegir
    var nFields = 10         // Numero de camps a llegir
    var timerStep = 0.01   // Segons per repetir el enviar
    var contadorOp = 0    // Indica quantes solicituts s'han enviar
    
    var listaOp :[(UInt8, UInt8)] = [(34,9), (50,2), (58,5), (71,10), (97,4), (181,10)]
    
    var headersOk = false
    
    var sendTimer : NSTimer?    // Timer per enviar les dades periodicament
    
    @IBOutlet weak var timerField   : UITextField!
    @IBOutlet weak var valuesField   : UITextField!
    @IBOutlet weak var nValuesField   : UITextField!
    @IBOutlet weak var tview   : UITextView!
    
    var dashboard : BLENinebotDashboard?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func MiM(){
        getScreenData()
        
        self.client = BLESimulatedClient()
        if let cli0 = self.client {
            cli0.startScanning()
            cli0.cntrl = self
        }
        
        self.server = BLESimulatedServer()
        if let srv0 = self.server {
            srv0.cntrl = self
        }
        
    }
    
    
    @IBAction func Server(){
        getScreenData()
        
        if state == .Server{
            
            if let srv = self.server{
                srv.stopTransmiting()
            }
            
            server = nil
            state = .Waiting
        }
        else if state == .Waiting {
            self.server = BLESimulatedServer()
        }
    }
    
    @IBAction func Client(){
        getScreenData()
        
        if state == .Client {
            if let cli = self.client {
                cli.stopScanning()
            }
            
            client = nil
            state = .Waiting
        }
        else if state == .Waiting {
            self.client = BLESimulatedClient()
            if let cli = self.client {
                cli.cntrl = self
                cli.startScanning()
            }
        }
    }
    
    
    func startClient (){
        if state == .Waiting {
            self.client = BLESimulatedClient()
            if let cli = self.client {
                cli.cntrl = self
                cli.startScanning()
            }
        }
    }
    
    func stopClient(){
        
        if state == .Client {
            if let cli = self.client {
                cli.stopScanning()
            }
            
            client = nil
            state = .Waiting
        }

    }
    // MARK : Screen recovery functions
    
    func getScreenData(){
        
        if let v  = Double(self.timerField.text!){
            self.timerStep = v
        }

        if let i  = Int(self.valuesField.text!){
            self.firstField = i
        }

        
        if let i  = Int(self.nValuesField.text!){
            self.nFields = i
        }

        
    }
    
    // MARK : Navigatiom
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "dashboardSegue" {
             if let dash = segue.destinationViewController as? BLENinebotDashboard{
                dash.delegate = self
                self.dashboard = dash
                self.startClient() // Tan sols en algun cas potser depenent del sender?

            }
        }
    }
    
    // MARK: Feedback 
    
    func serverStarted(){
        
    }
    
    
    func serverStopped(){
        
    }
    
    func clientStarted(){
        
        self.datos.clearAll()
        self.contadorOp = 0
        self.headersOk = false
        self.state = .Client
        
        self.sendTimer = NSTimer.scheduledTimerWithTimeInterval(self.timerStep, target: self, selector: "sendData:", userInfo: nil, repeats: true)
    }
    
    func clientStopped(){
        
        if let tim = self.sendTimer{
            tim.invalidate()
            self.sendTimer = nil
        }

        self.client = nil
        self.state = .Waiting
        let aFile = self.datos.createTextFile()


        self.shareData(aFile)
        
        
     }
    
    // Create a file with actual data and share it
    
    func shareData(file: NSURL?){
        
        
        if let aFile = file {
            
            
            let activityViewController = UIActivityViewController(
                activityItems: [aFile.lastPathComponent!,   aFile],
                applicationActivities: [PickerActivity()])
            
            
            activityViewController.completionWithItemsHandler = {(a : String?, completed:Bool, objects:[AnyObject]?, error:NSError?) in
                
            }
            
            self.presentViewController(activityViewController,
                animated: true,
                completion: nil)
            
        }
        
    }
    
    // MARK: Client operations
    
    func sendData(timer:NSTimer){
        
        if self.datos.checkHeaders() {  // Get normal data
            
            if !self.headersOk {
                
                if let dash = self.dashboard {
                    
                    let sn = datos.serialNo()
                    let v1 = datos.version()
                    
                    let title = String(format:"%@ (%d.%d.%d)", sn, v1.0, v1.1, v1.2)
                    
                    dash.updateTitle(title)
                }
                
            }
            
            let (op, l) = listaOp[contadorOp++]
            
            if contadorOp >= listaOp.count{
                contadorOp = 0
            }
            
            let message = BLENinebotMessage(com: op, dat:[ l * 2] )
            
            if let cli = self.client{
                if let dat = message?.toNSData(){
                    
                    cli.writeValue(dat)
                }
            }
            else{
                timer.invalidate()
                self.sendTimer = nil
                self.appendToLog("Error : Intentant enviar missatge amb client = nil")
            }
            
            
            
        } else {    // Get One time data
            
            let message = BLENinebotMessage(com: UInt8(16), dat: [UInt8(22)])
            if let cli = self.client{
                 if let dat = message?.toNSData(){
                    
                    cli.writeValue(dat)
                }
            }
            else{
                timer.invalidate()
                self.sendTimer = nil
                self.appendToLog("Error : Intentant enviar missatge amb client = nil")
            }
        }
    }
    
    // MARK: Other functions
    
    func appendToLog(s : String){
        //
        //self.tview.text = self.tview.text + "\n" + s
    }
    
    func forwardWrite(data : NSData){
        
        if self.state == .MiM{
            self.client!.writeValue(data)
        }
        
        let msg = BLENinebotMessage(data: data)
        
        if let m = msg {
            self.appendToLog(String(format: "<<< %d %d",m.command, m.data[0]))
        }
        
    }
    
    func forwardValue(data : NSData){
        
        if self.state == .MiM {
            self.server!.updateValue(data)
        }
        
        self.appendToBuffer(data)
        self.procesaBuffer()
        
    }
    
    //MARK: Connection management
    
    func appendToBuffer(data : NSData){
        
        
        let count = data.length
        var buf = [UInt8](count: count, repeatedValue: 0)
        data.getBytes(&buf, length:count * sizeof(UInt8))
        
        buffer.appendContentsOf(buf)
        
        
    }
    
    func procesaBuffer()
    {
        // Wait till header
        
        repeat {
            
            while buffer.count > 0 && buffer[0] != 0x55 {
                buffer.removeFirst()
            }
            
            // OK, ara hem de veure si el caracter següent es un aa
            
            if buffer.count < 2{    // Wait for more data
                return
            }
            
            if buffer[1] != 0xaa {  // Fals header. continue cleaning
                buffer.removeFirst()
                procesaBuffer()
                return
            }
            
            if buffer.count < 8 {   // Too small. Wait
                return
            }
            
            // Extract len and check size
            
            let l = Int(buffer[2])
            
            if l + 4 > 250 {
                buffer.removeFirst(3)
                return
            }
        
            if buffer.count < (6 + l){
                return
            }
            
            // OK ara ja podem extreure el block. Te len + 6 bytes
            
            let block = Array(buffer[0..<(l+6)])
            
            
            let msg = BLENinebotMessage(buffer: block)
            
            if let m = msg {
                
                let d = m.interpret()
                
                var updated = false
                
                for (k, v) in d {
                    let w = datos.data[k].value
                    if w != v{
                        
                        let name = BLENinebot.labels[k]
                        self.appendToLog(String(format:"%@[%d] - %d", name, k, v))
                        updated = true
                    }
        
                    self.datos.addValue(k, value: v)
                }
                
                if updated{
                    if let dash = self.dashboard {
                        dash.update()
                    }
        
                }
        
               // self.appendToLog(String(format:">>> %@", m.interpret()))
            }
            
            
            buffer.removeFirst(l+6)
            
        } while buffer.count > 6
        
        
    }
    
    func toScreen(){
        self.appendToLog("Situacio actual de les variables ")
        self.appendToLog("-------------------------------------------------")
        for var k = 0; k < 256; k++ {
            let v = datos.data[k].value
            self.appendToLog(String(format:"%@[%d] : %d", BLENinebot.labels[k],  k, v))
        }
    }
    
    //MARK: View management
    
    override func viewWillAppear(animated: Bool) {
        if self.state == .Client{
            self.clientStopped()
            
        }
        else{
            NSLog("Connexio misteriosa")
        }
    }
    
}

