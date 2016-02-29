//
//  BLENinebot.swift
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
//
// BLENinebot represents the state of the wheel
//
//  It really is aan array simulating original description
//
//  It is an Int array
//
//  Also provides a log of information as a log array that may be saved.
//
//  Methods are provided to interpret labels and get most information in correct units
//
//  Usually there is just one object just for the current wheel
//
//

import UIKit

class  BLENinebot : NSObject{
    
    struct LogEntry {
        var time : NSDate
        var variable : Int
        var value : Int
    }
    
    struct DoubleLogEntry {
        var time : NSDate
        var variable : Int
        var value : Double
    }
    
    struct NinebotVariable {
        var codi : Int = -1
        var timeStamp : NSDate = NSDate()
        var value : Int = -1
        var log : [LogEntry] = [LogEntry]()
        
    }
    
    static let kAltitude = 0        // Obte les dades de CMAltimeterManager. 0 es l'inici i serveix per variacions unicament
    static let kPower = 1           // Calculada com V * I
    static let kSerialNo = 16       // 16-22
    static let kPinCode = 23        // 23-25
    static let kVersion = 26
    static let kError = 27
    static let kWarn = 28
    static let kWorkMode = 31
    static let kBattery = 34
    static let kRemainingDistance = 37
    static let kCurrentSpeed = 38
    static let kTotalMileage0 = 41
    static let kTotalMileage1 = 42
    static let kTotalRuntime0 = 50
    static let kTotalRuntime1 = 51
    static let kSingleRuntime = 58
    static let kTemperature = 62
    static let kVoltage = 71
    static let kElectricVoltage12v = 74
    static let kCurrent = 80
    static let kPitchAngle = 97
    static let kRollAngle = 98
    static let kPitchAngleVelocity = 99
    static let kRollAngleVelocity = 100
    
    static let kvCodeError = 176
    static let kvCodeWarning = 177
    static let kvFlags = 178
    static let kvWorkMode = 179
    static let kvPowerRemaining = 180
    static let kvSpeed = 181
    static let kvAverageSpeed = 182
    static let kvTotalDistance0 = 183
    static let kvTotalDistance1 = 184
    static let kvSingleMileage = 185
    static let kvTemperature = 187
    static let kvDriveVoltage = 188
    static let kvRollAngle = 189
    static let kvPitchAngle = 190
    static let kvMaxSpeed = 191
    static let kvRideMode = 210
    
    static var  labels = Array<String>(count:256, repeatedValue:"?")
    
    static var displayableVariables : [Int] = [BLENinebot.kCurrentSpeed, BLENinebot.kTemperature,
        BLENinebot.kVoltage, BLENinebot.kCurrent, BLENinebot.kBattery, BLENinebot.kPitchAngle, BLENinebot.kRollAngle,
        BLENinebot.kvSingleMileage, BLENinebot.kAltitude, BLENinebot.kPower]
    
    var data = [NinebotVariable](count:256, repeatedValue:NinebotVariable())
    var signed = [Bool](count: 256, repeatedValue: false)
    
    var headersOk = false
    var firstDate : NSDate?
    
    
    
    
    override init(){
        
        if BLENinebot.labels[37] == "?"{
            BLENinebot.initNames()
        }
        super.init()
        
        for i in 0..<256 {
            data[i].codi = i
        }
        
        signed[BLENinebot.kPitchAngle] = true
        signed[BLENinebot.kRollAngle] = true
        signed[BLENinebot.kPitchAngleVelocity] = true
        signed[BLENinebot.kRollAngleVelocity] = true
        signed[BLENinebot.kCurrent] = true
        signed[BLENinebot.kvRollAngle] = true
        signed[BLENinebot.kvPitchAngle] = true
        
        
    }
    
    static func initNames(){
        BLENinebot.labels[0]  = "Alt Var(m)"
        BLENinebot.labels[1]  = "Power(W)"
        BLENinebot.labels[16]  = "SN0"
        BLENinebot.labels[17]  = "SN1"
        BLENinebot.labels[18]  = "SN2"
        BLENinebot.labels[19]  = "SN3"
        BLENinebot.labels[20]  = "SN4"
        BLENinebot.labels[21]  = "SN5"
        BLENinebot.labels[22]  = "SN6"
        BLENinebot.labels[23]  = "BTPin0"
        BLENinebot.labels[24]  = "BTPin1"
        BLENinebot.labels[25]  = "BTPin2"
        BLENinebot.labels[26]  = "Version"
        BLENinebot.labels[34]  = "Batt (%)"
        BLENinebot.labels[37]  = "Remaining Mileage"
        BLENinebot.labels[38]  = "Speed (Km/h)"
        BLENinebot.labels[41]  = "Total Mileage 0"
        BLENinebot.labels[42]  = "Total Mileage 1"
        BLENinebot.labels[50]  = "Total Runtime 0"
        BLENinebot.labels[51]  = "Total Runtime 1"
        BLENinebot.labels[58]  = "Single Runtime"
        BLENinebot.labels[62]  = "T (ºC)"
        BLENinebot.labels[71]  = "Voltage (V)"
        BLENinebot.labels[80]  = "Current (A)"
        BLENinebot.labels[97]  = "Pitch (º)"
        BLENinebot.labels[98]  = "Roll (º)"
        BLENinebot.labels[99]  = "Pitch Angle Angular Velocity"
        BLENinebot.labels[100]  = "Roll Angle Angular Velocity"
        BLENinebot.labels[105]  = "Active Data Encoded"
        BLENinebot.labels[115]  = "Tilt Back Speed?"
        BLENinebot.labels[116]  = "Speed Limit"
        
        BLENinebot.labels[176] = "Code Error"
        BLENinebot.labels[177] = "Code Warning"
        BLENinebot.labels[178] = "Flags"             // Lock, Limit Speed, Beep, Activation
        BLENinebot.labels[179] = "Work Mode"
        BLENinebot.labels[180] = "Power Remaining"
        BLENinebot.labels[181] = "Speed"
        BLENinebot.labels[182] = "Average Speed"
        BLENinebot.labels[183] = "Total Distance0"
        BLENinebot.labels[184] = "Total Distance1"
        BLENinebot.labels[185] = "Dist (Km)"
        BLENinebot.labels[186] = "Single Mileage?"
        BLENinebot.labels[187] = "Body Temp"
        BLENinebot.labels[188] = "Drive Voltage"
        BLENinebot.labels[189] = "Roll Angle"
        BLENinebot.labels[191] = "Max Speed"
        BLENinebot.labels[210] = "Ride Mode"
        BLENinebot.labels[211] = "One Fun Bool"
        
    }
    
    func clearAll(){
        
        for i in 0..<256{
            data[i].value = -1
            data[i].timeStamp = NSDate()
            if data[i].log.count > 0{
                data[i].log.removeAll()
            }
        }
        
        headersOk = false
        
        firstDate = nil
    }
    
    func checkHeaders() -> Bool{
        
        if headersOk {
            return true
        }
        
        var filled = true
        
        for i in 16..<27 {
            if data[i].value == -1{
                filled = false
            }
        }
        
        headersOk = filled
        
        return filled
    }
    
    func addValue(variable : Int, value : Int){
        
        let t = NSDate()
        
        self.addValueWithDate(t, variable: variable, value: value)
        
    }
    
    func addValueWithTimeInterval(time: NSTimeInterval, variable : Int, value : Int){
        
        let t = NSDate(timeIntervalSince1970: time)
        
        self.addValueWithDate(t, variable: variable, value: value)
    }
    
    func addValueWithDate(dat: NSDate, variable : Int, value : Int){
        
        if variable >= 0 && variable < 256 {
            
            if firstDate == nil {
                firstDate = NSDate()
            }
            
            if dat.compare(firstDate!) == NSComparisonResult.OrderedAscending{
                firstDate = dat
            }
            
            var sv = value
            if signed[variable]{
                if value >= 32768 {
                    sv = value - 65536
                }
            }

            let v = LogEntry(time:dat, variable: variable, value: sv)

            if data[variable].value != sv || data[variable].log.count == 1 {

                data[variable].log.append(v)
                
            }else if data[variable].log.count >= 2{
                
                let c = data[variable].log.count
                let e = data[variable].log[c-2]
                
                if e.value != sv{   // Append new point
                    data[variable].log.append(v)
                }
                else {  // Update time of new point
                    data[variable].log[c-1] = v
                    
                }
                
            }
            
            // Now update values of variables
            
            data[variable].value = sv
            data[variable].timeStamp = dat
        }
    }
    
    
    // MARK : Converting to and from files
    
    func createTextFile() -> NSURL?{
        
        // Format first date into a filepath
        
        let ldateFormatter = NSDateFormatter()
        let enUSPOSIXLocale = NSLocale(localeIdentifier: "en_US_POSIX")
        
        ldateFormatter.locale = enUSPOSIXLocale
        ldateFormatter.dateFormat = "'9B_'yyyyMMdd'_'HHmmss'.txt'"
        let newName = ldateFormatter.stringFromDate(NSDate())
        
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
            
            if firstDate == nil {
                firstDate = NSDate()
            }
            
            
            let title = String(format: "Time\tVar\tValor\n")
            hdl.writeData(title.dataUsingEncoding(NSUTF8StringEncoding)!)
            
            for v in self.data {
                
                if v.value != -1 && v.log.count > 0{
                    
                    let varName = String(format: "%d\t%@\n",v.codi, BLENinebot.labels[v.codi])
                    
                    NSLog("Gravant log per %@", varName)
                    
                    if let vn = varName.dataUsingEncoding(NSUTF8StringEncoding){
                        hdl.writeData(vn)
                    }
                    
                    for item in v.log {
                        
                        let t = item.time.timeIntervalSince1970
                        
                        let s = String(format: "%20.3f\t%d\t%d\n", t, item.variable, item.value)
                        if let vn = s.dataUsingEncoding(NSUTF8StringEncoding){
                            hdl.writeData(vn)
                        }
                    }
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
    
    func loadTextFile(url:NSURL){
        
        self.clearAll()
        
        do{
            
            let data = try String(contentsOfURL: url, encoding: NSUTF8StringEncoding)
            let lines = data.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
            
            for line in lines {
                let fields = line.componentsSeparatedByString("\t")
                
                if fields.count == 3{   // Good Data
                    
                    let time = Double(fields[0].stringByReplacingOccurrencesOfString(" ", withString: ""))
                    let variable = Int(fields[1])
                    let value = Int(fields[2])
                    
                    if let t = time, i = variable, v = value {
                        self.addValueWithTimeInterval(t, variable: i, value: v)
                    }
                }
                
            }
            
        }catch {
            
        }
        
    }
    
    // MARK: Query Functions
    
    func serialNo() -> String{
        
        var no = ""
        
        for (var i = 16; i < 23; i++){
            let v = self.data[i].value
            
            
            let v1 = v % 256
            let v2 = v / 256
            
            let ch1 = Character(UnicodeScalar(v1))
            let ch2 = Character(UnicodeScalar( v2))
            
            no.append(ch1)
            no.append(ch2)
        }
        
        return no
    }
    
    func version() -> (Int, Int, Int){
        
        let clean = self.data[BLENinebot.kVersion].value & 4095
        
        let v0 = clean / 256
        let v1 = (clean - (v0 * 256) ) / 16
        let v2 = clean % 16
        
        return (v0, v1, v2)
        
    }
    
    // Return total mileage in Km
    
    func totalMileage() -> Double {
        
        let d : Double = Double (data[BLENinebot.kTotalMileage1].value * 65536 + data[BLENinebot.kTotalMileage0].value) / 1000.0
        
        return d
        
    }
    
    // Total runtime in seconds
    
    func totalRuntime() -> NSTimeInterval {
        
        let t : NSTimeInterval = NSTimeInterval(data[BLENinebot.kTotalRuntime1].value * 65536 + data[BLENinebot.kTotalRuntime0].value)
        
        return t
    }
    
    func singleRuntime() -> NSTimeInterval {
        
        let t : NSTimeInterval = NSTimeInterval(data[BLENinebot.kSingleRuntime].value)
        
        return t
    }
    
    func singleRuntimeHMS() -> (Int, Int, Int) {
        
        let total  = data[BLENinebot.kSingleRuntime].value
        
        let hours =  total / 3600
        let minutes = (total - (hours * 3600)) / 60
        let seconds = total - (hours * 3600) - (minutes * 60)
        
        return (hours, minutes, seconds)
        
    }
    
    
    func totalRuntimeHMS() -> (Int, Int, Int) {
        
        let total = data[BLENinebot.kTotalRuntime1].value * 65536 + data[BLENinebot.kTotalRuntime0].value
        
        let hours = total / 3600
        let minutes = (total - (hours * 3600)) / 60
        let seconds = total - (hours * 3600) - (minutes * 60)
        
        return (hours, minutes, seconds)
        
    }
    
    // Body Temperature in ºC
    
    func temperature() -> Double {
        let t : Double = Double(data[BLENinebot.kTemperature].value) / 10.0
        
        return t
    }
    
    func temperature(i : Int) -> Double {
        let t : Double = Double(data[BLENinebot.kTemperature].log[i].value) / 10.0
        
        return t
    }
    
    func temperature(time t: NSTimeInterval) -> Double{
        
        let entry = self.value(BLENinebot.kTemperature, forTime: t)
        
        if let e = entry{
            return Double(e.value) / 10.0
        }
        else{
            return 0.0
        }
    }
    
    
    
    
    // Voltage
    
    func voltage() -> Double {
        let t : Double = Double(data[BLENinebot.kVoltage].value) / 100.0
        return t
    }
    func voltage(i : Int) -> Double {
        
        let t : Double = Double(data[BLENinebot.kVoltage].log[i].value) / 100.0
        return t
    }
    
    func voltage(time t: NSTimeInterval) -> Double{
        
        let entry = self.value(BLENinebot.kVoltage, forTime: t)
        
        if let e = entry{
            return Double(e.value) / 100.0
        }
        else{
            return 0.0
        }
    }
    
    // Current
    func current() -> Double {
        let v = data[BLENinebot.kCurrent].value
        let t = Double(v) / 100.0
        return t
    }
    
    func current(i : Int) -> Double {
        let v = data[BLENinebot.kCurrent].log[i].value
        let t = Double(v) / 100.0
        return t
    }
    
    
    func current(time t: NSTimeInterval) -> Double{
        
        let entry = self.value(BLENinebot.kCurrent, forTime: t)
        
        if let e = entry{
            let v = e.value
            
            return Double(v) / 100.0
        }
        else{
            return 0.0
        }
    }
    
    
    
    
    func power() -> Double{ // Units are Watts
        return voltage() * current()
    }
    
    func power(i : Int) -> Double {
        
        let c =  data[BLENinebot.kCurrent].log[i]
        
        // Ok now we need the value
        
        let voltage = self.value(BLENinebot.kVoltage, forTime: c.time.timeIntervalSinceDate(self.firstDate!))
        
        if let v = voltage {
            
            return Double(v.value) * Double(c.value) / 10000.0
        }else {
            return 0.0
        }
        
    }
    
    func power(time  t : NSTimeInterval) -> Double{
        
        
        return self.current(time: t) * self.voltage(time: t)
        
    }
    
    // pitch Angle
    
    func pitch() -> Double {
        let v = data[BLENinebot.kPitchAngle].value
        let t = Double(v) / 100.0
        return t
    }
    
    func pitch(i : Int) -> Double {
        let v = data[BLENinebot.kPitchAngle].log[i].value
        let t = Double(v) / 100.0
        return t
    }
    
    func pitch(time t: NSTimeInterval) -> Double{
        
        let entry = self.value(BLENinebot.kPitchAngle, forTime: t)
        
        if let e = entry{
            let v = e.value
            return Double(v) / 100.0
        }
        else{
            return 0.0
        }
    }
    
    
    
    
    // roll Angle
    
    func roll() -> Double {
        let v = data[BLENinebot.kRollAngle].value
        let t = Double(v) / 100.0
        return t
    }
    
    func roll(i : Int) -> Double {
        let v = data[BLENinebot.kRollAngle].log[i].value
        let t = Double(v) / 100.0
        return t
    }
    
    func roll(time t: NSTimeInterval) -> Double{
        
        let entry = self.value(BLENinebot.kRollAngle, forTime: t)
        
        if let e = entry{
            let v = e.value
            return Double(v) / 100.0
        }
        else{
            return 0.0
        }
    }
    
    
    // pitch angle speed
    
    
    
    // roll angle speed
    
    
    
    // Remaining km
    
    func remainingMileage() -> Double{
        
        let v = data[BLENinebot.kRemainingDistance].value
        
        let t = Double(v) / 100.0
        
        return t
        
        
    }
    
    
    // Battery Level
    
    func batteryLevel() -> Double{
        
        let v = data[BLENinebot.kBattery].value
        return Double(v)
        
    }
    
    func batteryLevel(i : Int) -> Double {
        let s : Double = Double(data[BLENinebot.kBattery].log[i].value)
        
        return s
    }
    
    func batteryLevel(time t: NSTimeInterval) -> Double{
        
        let entry = self.value(BLENinebot.kBattery, forTime: t)
        
        if let e = entry{
            return Double(e.value)
        }
        else{
            return 0.0
        }
    }
    
    // Speed
    
    func speed() -> Double {
        let s : Double = Double(data[BLENinebot.kCurrentSpeed].value) / 1000.0
        
        return s
    }
    
    func speed(i : Int) -> Double {
        
        if i < 2  {
            return Double(data[BLENinebot.kCurrentSpeed].log[i].value) / 1000.0
        }else{
            let v0 = Double(data[BLENinebot.kCurrentSpeed].log[i - 2].value) / 1000.0
            let v1 = Double(data[BLENinebot.kCurrentSpeed].log[i - 1].value) / 1000.0
            let v2 = Double(data[BLENinebot.kCurrentSpeed].log[i].value) / 1000.0
            
            return (v0 + 2 * v1 + v2 )/4.0
        }
        
    }
    
    
    func speed(time t: NSTimeInterval) -> Double{
        
        let entry = self.value(BLENinebot.kCurrentSpeed, forTime: t)
        
        if let e = entry{
            return Double(e.value) / 1000.0
        }
        else{
            return 0.0
        }
    }
    
    
    
    // Speed limit
    
    
    // Single runtime
    
    
    // Single distance. Sembla pitjor que la total. En fi
    
    func singleMileage() -> Double{
        
        let s : Double = Double(data[BLENinebot.kvSingleMileage].value) / 100.0
        
        return s
    }
    
    func singleMileage(i : Int) -> Double{
        
        let s : Double = Double(data[BLENinebot.kvSingleMileage].log[i].value) / 100.0
        
        return s
    }
    
    func singleMileage(time t: NSTimeInterval) -> Double{
        
        let entry = self.value(BLENinebot.kvSingleMileage, forTime: t)
        
        if let e = entry{
            return Double(e.value) / 100.0
        }
        else{
            return 0.0
        }
    }
    
    
    
    func altitude() -> Double{
        
        let s : Double = Double(data[BLENinebot.kAltitude].value) / 10.0
        
        return s
    }
    
    func altitude(i : Int) -> Double{
        
        if i < data[BLENinebot.kAltitude].log.count{
            
            return Double(data[BLENinebot.kAltitude].log[i].value) / 10.0
        }
        else{
            return 0.0
        }
        
    }
    
    func altitude(time t: NSTimeInterval) -> Double{
        
        let entry = self.value(BLENinebot.kAltitude, forTime: t)
        
        if let e = entry{
            return Double(e.value) / 10.0
        }
        else{
            return 0.0
        }
    }
    
    // t is time from firstDate
    
    func value(variable : Int,  forTime t:NSTimeInterval) -> DoubleLogEntry?{
        
        let v = variable
        let x = t
        
        
        if self.data[v].log.count <= 0{       // No Data
            return nil
        }
        
        var p0 = 0
        var p1 = self.data[v].log.count - 1
        let xd = Double(x)
        
        while p1 - p0 > 1{
            
            let p = (p1 + p0 ) / 2
            
            let xValue = self.data[v].log[p].time.timeIntervalSinceDate(self.firstDate!)
            
            if xd < xValue {
                p1 = p
            }
            else if xd > xValue {
                p0 = p
            }
            else{
                p0 = p
                p1 = p
            }
        }
        
        // If p0 == p1 just return value
        
        if p0 == p1 {
            let e = self.data[v].log[p0]
            return DoubleLogEntry(time: e.time, variable: e.variable, value: Double(e.value))
            
        }
        else {      // Intentem interpolar
            
            let v0 = self.data[v].log[p0]
            let v1 = self.data[v].log[p1]
            
            if v0.time.compare( v1.time) == NSComparisonResult.OrderedSame{   // One more check not to have div/0
                return DoubleLogEntry(time: v0.time, variable: v0.variable, value: Double(v0.value))
            }
            
            let deltax = v1.time.timeIntervalSinceDate(v0.time)
            
            let deltay = Double(v1.value) - Double(v0.value)
            
            let v = (x - v0.time.timeIntervalSinceDate(self.firstDate!)) / deltax * deltay + Double(v0.value)
            
            return DoubleLogEntry(time: NSDate(timeInterval: x, sinceDate: self.firstDate!), variable: variable, value: v)
        }
    }
    
    func getLogValue(variable : Int, time : NSTimeInterval) -> Double{
        switch(variable){
            
        case 0:
            return self.speed(time: time)
            
        case 1:
            return self.temperature(time: time)
            
        case 2:
            return self.voltage(time: time)
            
        case 3:
            return self.current(time: time)
            
        case 4:
            return self.batteryLevel(time: time)
            
        case 5:
            return self.pitch(time: time)
            
        case 6:
            return self.roll(time: time)
            
        case 7:
            return self.singleMileage(time: time)
            
        case 8:
            return self.altitude(time: time)
            
        case 9:
            return self.power(time: time)
            
        default:
            return 0.0
            
        }
    }
    
    func getLogValue(variable : Int, index : Int) -> Double{
        
        switch(variable){
            
        case 0:
            return self.speed(index)
            
        case 1:
            return self.temperature(index)
            
        case 2:
            return self.voltage(index)
            
        case 3:
            return self.current(index)
            
        case 4:
            return self.batteryLevel(index)
            
        case 5:
            return self.pitch(index)
            
        case 6:
            return self.roll(index)
            
        case 7:
            return self.singleMileage(index)
            
        case 8:
            return self.altitude(index)
            
        case 9:
            return self.power(index)
            
        default:
            return 0.0
            
        }
    }
    
    
    // Ride mode
    
    // One Fun Bool ?
    
    
    
}