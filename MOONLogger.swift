//
//  MOONLogger.swift
//  MOON
//
//  Created by Vegard Solheim Theriault on 01/04/15.
//  Copyright (c) 2015 MOON Wearables. All rights reserved.
//

//		.___  ___.   ______     ______   .__   __.
//		|   \/   |  /  __  \   /  __  \  |  \ |  |
//		|  \  /  | |  |  |  | |  |  |  | |   \|  |
//		|  |\/|  | |  |  |  | |  |  |  | |  . `  |
//		|  |  |  | |  `--'  | |  `--'  | |  |\   |
//		|__|  |__|  \______/   \______/  |__| \__|
//		 ___  _____   _____ _    ___  ___ ___ ___
//		|   \| __\ \ / / __| |  / _ \| _ \ __| _ \
//		| |) | _| \ V /| _|| |_| (_) |  _/ _||   /
//		|___/|___| \_/ |___|____\___/|_| |___|_|_\


import Foundation

private let LOG_FILE_NAME = "MOONLog.txt"
private let SHOULD_SAVE_LOG_TO_FILE = true
private let SHOULD_INCLUDE_TIME     = true
private let logQueue = dispatch_queue_create("com.moonLogger.logQueue", DISPATCH_QUEUE_SERIAL)

// Enables a call like MOONLog() to simply print a new line
func MOONLog(filePath: String = __FILE__, functionName: String = __FUNCTION__, lineNumber: Int = __LINE__) {
    MOONLog("", filePath: filePath, functionName: functionName, lineNumber: lineNumber)
}

func MOONLog(message: String, filePath: String = __FILE__, functionName: String = __FUNCTION__, lineNumber: Int = __LINE__) {
    dispatch_async(logQueue) {
        var printString = ""
		
		// This will happen no matter how this function is exited
		defer { print(printString) }
		
        if SHOULD_INCLUDE_TIME {
            let date = NSDate()
            
            var milliseconds = date.timeIntervalSince1970 as Double
            milliseconds -= floor(milliseconds)
            let tensOfASecond = Int(milliseconds * 10000)
            
            // Adding extra "0"s to the milliseconds if necessary
            var tensOfASecondString = "\(tensOfASecond)"
            
            while tensOfASecondString.characters.count < 3 {
                tensOfASecondString = "0" + tensOfASecondString
            }
			
			// Makes sure there are no more than 3 millisecond digits
			tensOfASecondString = tensOfASecondString.substringToIndex(tensOfASecondString.startIndex.advancedBy(3))
			
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
            let dateString = dateFormatter.stringFromDate(date)
            
            printString += "\(dateString).\(tensOfASecondString)   "
        }
		
		// If this doesn't work, the defer statement will make sure printString gets printed anyway
		var fileName = (filePath as NSString).lastPathComponent
        var functionNameToPrint = functionName
        
        if fileName.characters.count > 25 {
            fileName = ((fileName as NSString).substringToIndex(22) as String) + "..."
        }
        
        if functionName.characters.count > 45 {
            functionNameToPrint = ((functionName as NSString).substringToIndex(42) as String) + "..."
        }
        
        printString += String(format: "l:%-5d %-25s  %-45s  %@",
            lineNumber,
            COpaquePointer(fileName.cStringUsingEncoding(NSUTF8StringEncoding)!),
            COpaquePointer(functionNameToPrint.cStringUsingEncoding(NSUTF8StringEncoding)!),
            message)
        
        if SHOULD_SAVE_LOG_TO_FILE {
            MOONLogger.appendToLogFile(printString)
        }
    }
}


struct MOONLogger {
    
    private static let privateSharedLogger = MOONLogger()
    private let file: NSFileHandle?
    
    private init() {
        file = NSFileHandle(forUpdatingAtPath: MOONLogger.getFilePath())
    }
    
    static func forceSave() {
        dispatch_async(logQueue) {
            privateSharedLogger.file?.synchronizeFile()
            privateSharedLogger.file?.closeFile()
        }
    }
    
    static func clearLog() {
        dispatch_async(logQueue) {
            let path = getFilePath()
            if NSFileManager.defaultManager().fileExistsAtPath(path) {
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(path)
                } catch let error as NSError {
                    print("Failed to remove the file \"\(path)\", with errror: \(error.localizedDescription)")
                }
            }
        }
    }
    
    static func getLogFile(completionHandler: (logFile: NSData?, mimeType: String?) -> ()) {
        dispatch_async(logQueue) {
            let data = NSData(contentsOfFile: getFilePath())
            dispatch_async(dispatch_get_main_queue()) {
                completionHandler(logFile: data, mimeType: "text/txt")
            }
        }
    }
    
    private static func appendToLogFile(text: String) {
        guard let textData = (text + "\n").dataUsingEncoding(NSUTF8StringEncoding) else { return }
        
        // Will most likely always be called from the MOONLog global function, which is already wrapped
        // in a dispatch_async call, but better safe than sorry.
        dispatch_async(logQueue) {
            privateSharedLogger.file?.writeData(textData)
        }
    }
    
    private static func getFilePath() -> String {
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(
            NSSearchPathDirectory.DocumentDirectory,
            NSSearchPathDomainMask.UserDomainMask,
            true)[0]
        
        return (documentsDirectory as NSString).stringByAppendingPathComponent(LOG_FILE_NAME)
    }
}

