//
//  BLENinebotMessage.swift
//  NinebotClientTest
//
//  Created by Francisco Gorina Vanrell on 4/2/16.
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
// Buffer structure
//
//  +---+---+---+---+---+---+---+---+---+
//  |x55|xAA| l |x09|x01| c |...|ck0|ck1|
//  +---+---+---+---+---+---+---+---+---+
//
//  ... Are a UInt8 array of l-2 elements
//  ck0, ck1 are computed from the elements from l to the last of ...
//  x55 and xAA are fixed and are Beggining of buffer
//  l is the size of ... + 2 
//  x09 and x01 seem fixed for Ninebot One but it is not clear
//  c is a command or variable. For the same value the data is similar


import UIKit

class BLENinebotMessage: NSObject {
    
    let CUSTOMER_ACTION_MASK : UInt16 = 0xFFFF

    
    // h0, h1 representen els headers 
    
    var h0 : UInt8 = 0x55
    var h1 : UInt8 = 0xaa
    
    var len : UInt8 = 2         // length of data + 2
    
    var fixed1 : UInt8 = 0x09   // Seems always constant for NB One E+
    var fixed2 : UInt8 = 0x01   // Seems always constant for NB One E+
    
    var command : UInt8 = 0x00  // Seems to be a command or variable index
    
    var data : [UInt8] = []     // Data
    
    var ck0 : UInt8 = 0x00      // Check0
    var ck1 : UInt8 = 0x00      // Check1
    
    
    
    override init() {
        
        super.init()
    }
    
    init?(com : UInt8, dat : [UInt8]){
        super.init()
        
        if dat.count > 253 {    // Max buffer size must be 253
            return nil
        }
        
        self.command = com
        self.data = dat
        self.len = UInt8(dat.count + 2)
        
        // OK build a buffer, compute checks and store

        var buff = [UInt8](count: 6, repeatedValue: 0)
        buff[0] = h0
        buff[1] = h1
        buff[2] = len
        buff[3] = fixed1
        buff[4] = fixed2
        buff[5] = command
        
        buff.appendContentsOf(dat)
        
        let (check0, check1) = self.check(buff, len: buff.count-2)
        
        self.ck0 = check0
        self.ck1 = check1
        
        
    }
    
    init?(buffer : [UInt8]){
        
        super.init()
        
        if !self.parseBuffer(buffer) {
            return nil
        }
        
    }
    
    init?(data : NSData){
        
        super.init()
        let count = data.length
        var buffer = [UInt8](count: count, repeatedValue: 0)
        data.getBytes(&buffer, length:count * sizeof(UInt8))
        if !self.parseBuffer(buffer) {
            return nil
        }

    }
    
    // Inicialitza amb un Hex String
    
    init?(string : String){
        
        super.init()
        
        let chars = string.characters
        let n = chars.count
        
        let ni = n / 2
        
        var buffer = [UInt8](count: ni, repeatedValue: 0)
        var index = string.startIndex
        var i2 = string.startIndex
        
        
        for (var i = 0; i < ni; i++){
            index = i2
            i2 = index.advancedBy(2)
            
            let s = string.substringWithRange(index..<i2)
            
            let us = UInt8(s, radix:16)
            if let u = us {
                buffer[i] = u
            }
            
            
        }
        
        if !self.parseBuffer(buffer) {
            return nil
        }
        
    }

    
    // parseBuffer omple les dades a partir del buffer. Fa check dels ck i header.
    // Retorna true si tot es correcte, false si es erroni
    
    func parseBuffer(buffer : [UInt8]) -> Bool{
        
        if buffer.count < 8 {   //  Minimum buffer sze
            return false
        }
        
        if buffer[0] != 0x55{
            return false
        }

        if buffer[1] != 0xaa{
            return false
        }
        
        self.len = buffer[2]
        
        if buffer[2] > 246{
            
        }
        
        // Check total length of buffer. May be bigger but not smaller than suggested by len
        
        if buffer.count < Int(self.len + 6) { // There are fixed 6 bytes not taken into account in len
            return false
        }
        
        (self.ck0, self.ck1) = check(buffer, len: Int(self.len) + 2)
        
        if self.ck0 != buffer[Int(self.len)+4] || self.ck1 != buffer[Int(self.len)+5]{
            return false
        }
        
        // OK all seems OK, move data from buffer to fields
        
        self.fixed1 = buffer[3]
        self.fixed2 = buffer[4]
        self.command = buffer[5]
        
        if self.len > 2{
            self.data = Array(buffer[6..<(6+Int(self.len)-2)])
        }
        
        return true
    }
    
    
    // Builds a UInt8 array with the data to be sent
    
    func toArray() -> [UInt8]{
        
        var buff = [UInt8](count: 6, repeatedValue: 0)
        
        buff[0] = h0
        buff[1] = h1
        buff[2] = len
        buff[3] = fixed1
        buff[4] = fixed2
        buff[5] = command
        
        buff.appendContentsOf(data)
        
        buff.append(ck0)
        buff.append(ck1)
        
        return buff
    }
    
    func toNSData() -> NSData?{
        
        let buff = toArray();
        let data = NSData(bytes: buff, length: buff.count)
        
        return data
     }
    
    
    // Computes checksum from byte [2] for len bytes.
    
    func check(bArr : [UInt8], len : Int) -> (UInt8, UInt8) {			//Comença a i2 = 2 per c bytes
        var i : UInt16 = 0;
        
        for (var i2 = 2; i2 < len + 2; i2++) {
            i =  (i + UInt16(bArr[i2]))
        }
        let v : UInt16 =   (i ^ 0xFFFF) & self.CUSTOMER_ACTION_MASK
        
        return( UInt8(v & UInt16(255)),  UInt8(v>>8))
        
    }
    
    func toString() -> String{
        
        var s = String(format: "BLEMessage : c = %02x p = ", self.command)
        
        for b in self.data{
            s.appendContentsOf(String(format:" %02x", b))
        }
        
        return s
        
    }
    
    // -> Interpreta el missatge i retorna un Diccionari amb el numero de variable i el valor
    
    func interpret() -> [Int :Int]{
        
        var dict = [Int : Int]()
        
        if fixed1 == 9 && fixed2 == 1 {
            
            
            let l = Int(self.len-2)
            var k = Int(self.command)
            
            for var i = 0; i < l; i=i+2{
                
                let value = Int(data[i+1]) * 256 + Int(data[i])
                
                dict[k] = value
                k++
                
            }
        }
        
        return dict
        
    }
    

}
