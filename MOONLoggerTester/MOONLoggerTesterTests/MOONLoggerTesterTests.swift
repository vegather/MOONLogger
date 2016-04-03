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
        guard let path = NSBundle(forClass: MOONLoggerTesterTests.classForCoder()).resourcePath else { return }
        testFile = fopen(path + "/testFile.txt", "w+")
    }
    
    override func tearDown() {
        super.tearDown()
        fclose(testFile)
        testFile = nil
    }
    
    
    
    // -------------------------------
    // MARK: Testing MOONLog
    // -------------------------------
    
    func testBasic() {
        let messageToPrint = "Hello World"
        MOONLog(messageToPrint, stream: testFile)
        
        NSThread.sleepForTimeInterval(3.0)
        
        if let text = whatsInTheTestFile() {
            XCTAssert(text.hasSuffix(messageToPrint + "\n"), "\(text) did not have the suffix \(messageToPrint)")
        } else {
            XCTFail("Could not fetch text from the testFile")
        }
    }
    
    func testAdvanced() {
        let messageToPrint = "´eé"
        MOONLog(messageToPrint, stream: testFile)
        
        NSThread.sleepForTimeInterval(3.0)
        
        if let text = whatsInTheTestFile() {
            XCTAssert(text.hasSuffix(messageToPrint + "\n"), "\(text) did not have the suffix \(messageToPrint)")
        } else {
            XCTFail("Could not fetch text from the testFile")
        }
    }
    
    func testEmoji() {
        let messageToPrint = "👌👌🏻👌🏼👌🏽👌🏾👌🏿😀🤖🇨🇦"
        MOONLog(messageToPrint, stream: testFile)
        
        NSThread.sleepForTimeInterval(3.0)
        
        if let text = whatsInTheTestFile() {
            XCTAssert(text.hasSuffix(messageToPrint + "\n"), "\(text) did not have the suffix \(messageToPrint)")
        } else {
            XCTFail("Could not fetch text from the testFile")
        }
    }
    
    func testSignLanguage() {
        let jamoTest = "가"
        MOONLog(jamoTest, stream: testFile)
        
        NSThread.sleepForTimeInterval(3.0)
        
        if let text = whatsInTheTestFile() {
            XCTAssert(text.hasSuffix(jamoTest + "\n"), "\(text) did not have the suffix \(jamoTest)")
        } else {
            XCTFail("Could not fetch text from the testFile")
        }
    }
    
    
    
    // -------------------------------
    // MARK: Test Log File
    // -------------------------------
    
    func testGetLogFileWhileOpen() {
        let message = "Hello, World"
        
        MOONLogger.startWritingToLogFile()
        MOONLog(message)
        
        let getLogFileExpectation = expectationWithDescription("Got the log file")
        MOONLogger.getLogFile() { logFile, _ in
            guard let logFile = logFile,
                decodedMessage = String(data: logFile, encoding: NSUTF8StringEncoding) else
            {
                XCTFail("Could not decode the log file")
                return
            }
            
            XCTAssert(decodedMessage.hasSuffix(message + "\n"), "\(decodedMessage) did not have the suffix \(message)")
            getLogFileExpectation.fulfill()
        }
        waitForExpectationsWithTimeout(5.0, handler: nil)
        
        // Assuming that this cleanup will work
        MOONLogger.stopWritingToLogFile()
        MOONLogger.clearLogFile()
    }
    
    func testGetLogFileWhileClosed() {
        let message = "Hello, World"
        
        MOONLogger.startWritingToLogFile()
        MOONLog(message)
        MOONLogger.stopWritingToLogFile()
        
        let getLogFileExpectation = expectationWithDescription("Got the log file")
        MOONLogger.getLogFile() { logFile, _ in
            guard let logFile = logFile,
                      decodedMessage = String(data: logFile, encoding: NSUTF8StringEncoding) else
            {
                XCTFail("Could not decode the log file")
                return
            }
            
            XCTAssert(decodedMessage.hasSuffix(message + "\n"), "\(decodedMessage) did not have the suffix \(message)")
            getLogFileExpectation.fulfill()
        }
        waitForExpectationsWithTimeout(5.0, handler: nil)
        
        // Assuming that this cleanup will work
        MOONLogger.clearLogFile()
    }
    
    func testClearLogFileWhileOpen() {
        
    }
    
    func testClearLogFileWhileClosed() {
        
    }
    
    func testWritingUnicodeToLogFile() {
        
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
