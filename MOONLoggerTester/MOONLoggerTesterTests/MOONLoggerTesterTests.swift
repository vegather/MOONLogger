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
        // Using the stream argument because I don't want this to show up in the console
        MOONLog(message, stream: testFile)
        
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
        // Using the stream argument because I don't want this to show up in the console
        MOONLog(message, stream: testFile)
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
        let message = "Hello, World"
        
        MOONLogger.startWritingToLogFile()
        // Using the stream argument because I don't want this to show up in the console
        MOONLog(message, stream: testFile)
        MOONLogger.clearLogFile()
        
        let getLogFileExpectation = expectationWithDescription("Got the log file")
        MOONLogger.getLogFile() { logFile, _ in
            guard let logFile = logFile else {
                XCTFail("The log file was nil")
                return
            }
            
            guard let decodedMessage = String(data: logFile, encoding: NSUTF8StringEncoding) else {
                XCTFail("Could not decode the log file")
                return
            }
            
            XCTAssertEqual(decodedMessage, "")
            getLogFileExpectation.fulfill()
        }
        waitForExpectationsWithTimeout(5.0, handler: nil)
        
        // Assuming that this cleanup will work
        MOONLogger.stopWritingToLogFile()
    }
    
    func testClearLogFileWhileClosed() {
        let message = "Hello, World"
        
        MOONLogger.startWritingToLogFile()
        // Using the stream argument because I don't want this to show up in the console
        MOONLog(message, stream: testFile)
        MOONLogger.stopWritingToLogFile()
        MOONLogger.clearLogFile()
        
        let getLogFileExpectation = expectationWithDescription("Got the log file")
        MOONLogger.getLogFile() { logFile, _ in
            XCTAssertNil(logFile, "Expected the log file to not exist. Has size: \(logFile?.length)")
            getLogFileExpectation.fulfill()
        }
        waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testWritingUnicodeToLogFile() {
        let message = "👌👌🏻👌🏼👌🏽👌🏾👌🏿😀🤖🇨🇦"
        
        MOONLogger.startWritingToLogFile()
        // Using the stream argument because I don't want this to show up in the console
        MOONLog(message, stream: testFile)
        
        let getLogFileExpectation = expectationWithDescription("Got the log file")
        MOONLogger.getLogFile() { logFile, _ in
            guard let logFile = logFile else {
                XCTFail("The log file was nil")
                return
            }
            
            guard let decodedMessage = String(data: logFile, encoding: NSUTF8StringEncoding) else {
                XCTFail("Could not decode the log file")
                return
            }
            
            XCTAssert(decodedMessage.hasSuffix(message + "\n"), "\(decodedMessage) did not have the suffix \(message)")
            getLogFileExpectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(5.0, handler: nil)
        
        MOONLogger.stopWritingToLogFile()
        MOONLogger.clearLogFile()
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
