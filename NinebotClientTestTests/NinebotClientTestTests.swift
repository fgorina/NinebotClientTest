//
//  NinebotClientTestTests.swift
//  NinebotClientTestTests
//
//  Created by Francisco Gorina Vanrell on 2/2/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

import XCTest
@testable import NinebotClientTest

class NinebotClientTestTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        
        let nb = BLENinebot()
        
        
        
        let (data1, len1 ) = nb.sendData(12, len: 1, p1: 1, p2: 102, bArr: [6])
        let checkData1 : [UInt8] = [85, 0xAA, 3, 12, 1, 102, 6, 131, 255]
        
        for i in 0..<len1 {
            if data1[i] != checkData1[i] {
                XCTAssert(false, "Error en buffer generat al primer test ")
            }
        }
        
        let (data2, len2 ) = nb.sendData(12, len: 3, p1: 1, p2: 102, bArr: [6, 7, 8])
        let checkData2 : [UInt8] = [85, 0xAA, 5, 12, 1, 102, 6, 7, 8, 114, 255]
        
        for i in 0..<len2 {
            if data2[i] != checkData2[i] {
                XCTAssert(false, "Error en buffer generat al segon test ")
            }
        }
        
        let (data3, len3 ) = nb.sendData(9, len: 1, p1: 1, p2: 0x17, bArr: [0x08])
        let checkData3 : [UInt8] = [0x55, 0xAA, 0x03, 0x09, 0x01, 0x17, 0x08, 0xd3, 0xff]
        
        for i in 0..<len3 {
            if data3[i] != checkData3[i] {
                XCTAssert(false, "Error en buffer generat al tercer test ")
            }
        }

        
        let message = BLENinebotMessage(com: 0x17, dat: [0x08])
        let moreData3 = message?.toArray()
        
        if let msg = moreData3 {
 
        for i in 0..<len3 {
            if msg[i] != checkData3[i] {
                XCTAssert(false, "Error en buffer generat per BLEMessage ")
            }
        }
        }
        else{
            XCTAssert(false, "Error al generar buffer per BLEMessage ")
        }
        
        
        XCTAssert(true)
        
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
