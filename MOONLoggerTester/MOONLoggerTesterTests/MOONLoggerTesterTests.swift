//
//  MOONLoggerTesterTests.swift
//  MOONLoggerTesterTests
//
//  Created by Vegard Solheim Theriault on 26/01/16.
//  Copyright © 2016 MOON Wearables. All rights reserved.
//

import XCTest
@testable import MOONLoggerTester

class MOONLoggerTesterTests: XCTestCase {
    
    // -------------------------------
    // MARK: Setup
    // -------------------------------
    
    var testFile: UnsafeMutablePointer<FILE>!
    
    override func setUp() {
        super.setUp()
        let path = NSBundle(forClass: MOONLoggerTesterTests.classForCoder()).resourcePath!
        testFile = fopen(path + "/testFile.txt", "w+")
    }
    
    override func tearDown() {
        super.tearDown()
        fclose(testFile)
        testFile = nil
    }
    
    
    
    // -------------------------------
    // MARK: Testing
    // -------------------------------
    
    func testBasicWriting() {
        let messageToPrint = "Hello World"
        MOONLog(messageToPrint, stream: testFile)
        
        NSThread.sleepForTimeInterval(3.0)
        
        if let text = whatsInTheTestFile() {
            XCTAssert(text.hasSuffix(messageToPrint + "\n"), "text: \(text)")
        } else {
            XCTFail("Could not fetch text from the testFile")
        }
    }
    
    
    
    
    
    // -------------------------------
    // MARK: Private Helpers
    // -------------------------------
    
    private func whatsInTheTestFile() -> String? {
        flockfile(testFile)
        rewind(testFile)
        
        let data = NSMutableData()
        var c = fgetc(testFile)
        while c != EOF {
            data.appendBytes(&c, length: sizeof(Int8))
            c = fgetc(testFile)
        }
        funlockfile(testFile)
        
        return String(data: data, encoding: NSUTF8StringEncoding)
    }
}
