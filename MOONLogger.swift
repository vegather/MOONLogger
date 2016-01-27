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
private let SHOULD_INCLUDE_TIME = true
private let logQueue = dispatch_queue_create("com.moonLogger.logQueue", DISPATCH_QUEUE_SERIAL)
private var logFile: UnsafeMutablePointer<FILE> = nil
private var shouldSaveToLogFile = false


/**
 A log statement that lets you easily see which file, function, and line number a log statement came from.
 
 - Parameter items: An optional list of items you want printed. Every item will be converted to a `String` like this: `"\(item)"`.
 - Parameter separator: An optional separator string that will be inserted between each of the `items`.
 - Parameter stream: The stream to write the `items` to. Primarily used for testing. Defaults to stdout, which is the same place the normal `print(...)` call prints to.

 The `filePath`, `functionName`, and `lineNumber` arguments should be left as they are. They default to `__FILE__`, `__FUNCTION__`, and `__LINE__` respectively, which is how `MOONLog(...)` is able to do its magic.
 */
func MOONLog(
    items       : Any...,
    separator   : String = " ",
    filePath    : String = __FILE__,
    functionName: String = __FUNCTION__,
    lineNumber  : Int    = __LINE__,
    stream      : UnsafeMutablePointer<FILE> = stdout)
{
    dispatch_async(logQueue) {
        
        var printString = ""
		
        // Going with this ANSI C solution here because it's about 1.5x
        // faster than the NSDateFormatter alternative.
        if SHOULD_INCLUDE_TIME {
            let bufferSize = 32
            var buffer = [Int8](count: bufferSize, repeatedValue: 0)
            var timeValue = time(nil)
            let tmValue = localtime(&timeValue)
            
            strftime(&buffer, bufferSize, "%Y-%m-%d %H.%M.%S", tmValue)
            if let dateFormat = String(CString: buffer, encoding: NSUTF8StringEncoding) {
                var timeForMilliseconds = timeval()
                gettimeofday(&timeForMilliseconds, nil)
                let timeSince1970 = NSDate().timeIntervalSince1970
                let seconds = floor(timeSince1970)
                let thousands = UInt(floor((timeSince1970 - seconds) * 1000.0))
                let milliseconds = String(format: "%03u", arguments: [thousands])
                printString = dateFormat + "." + milliseconds + "    "
            }
        }
		
        // Limit the fileName to 25 characters
        var fileName = (filePath as NSString).lastPathComponent
        if fileName.characters.count > 25 {
            fileName = fileName.substringToIndex(fileName.startIndex.advancedBy(22)) + "..."
        }
        
        // Limit the functionName to 40 characters
        var functionNameToPrint = functionName
        if functionName.characters.count > 40 {
            functionNameToPrint = functionName.substringToIndex(functionName.startIndex.advancedBy(37)) + "..."
        }
        
        // Construct the message to be printed
        var message = ""
        for (i, item) in items.enumerate() {
            message += "\(item)"
            if i < items.count-1 { message += separator }
        }

        printString += String(format: "l:%-5d %-25s  %-40s  %@",
            lineNumber,
            COpaquePointer(fileName.cStringUsingEncoding(NSUTF8StringEncoding)!),
            COpaquePointer(functionNameToPrint.cStringUsingEncoding(NSUTF8StringEncoding)!),
            message)
        
        // Write to the specified stream (stdout by default)
        MOONLogger.writeMessage(printString, toStream: stream)
        
        if shouldSaveToLogFile {
            // Write to the logFile
            MOONLogger.writeMessage(printString, toStream: logFile)
        }
    }
}


public struct MOONLogger {
    
    /**
     Sets up the log file.
     */
    public static func initializeLogFile() {
        shouldSaveToLogFile = true
        if logFile == nil { logFile = fopen(getFilePath(), "a+") }
    }
    
    
    /**
     Force writes everything written to the file thus far to be saved (by flushing the file), and then closing it. A good use case for this is in `applicationDidEnterBackground`, or `applicationWillTerminate` of your `AppDelegate`. Currently there's no way to recreate the log file other than relaunching the app (so that this file gets reloaded).
     */
    public static func forceSaveAndClose() {
        // Not doing this on the logQueue so that we can save and close ASAP, because the app might shut down at any moment.
        shouldSaveToLogFile = false
        if logFile != nil {
            fflush(logFile)
            fclose(logFile)
            logFile = nil
        }
    }
    
    
    /**
     This will wait until every pending write to the file is completed before clearing the file.
     */
    public static func clearLog() {
        // Doing it asynchronously on the logQueue to make sure all the MOONLog(...)
        // statements that were done before this call is finished before clearing it.
        // That way you won't get any leftover junk in the file.
        if logFile != nil {
            dispatch_async(logQueue) {
                // Open the file for reading & writing, and destroy any content that's in there.
                logFile = freopen(getFilePath(), "w+", logFile)
            }
        }
    }
    
    
    /**
     Waits until all pending `MOONLog(...)` calls are written to the file, and then returns the `logFile` data in a `completionHandler` on the main queue.
     
     - Parameter completionHandler: A completion handler that returns both the `logData` as well as the `mimeType` of the log file (currently `text/txt`). If there was some problem fetching the `logFile`, it will be nil.
     */
    public static func getLogFile(completionHandler: (logFile: NSData?, mimeType: String) -> ()) {
        guard logFile == nil else {
            completionHandler(logFile: nil, mimeType: "")
            return
        }
        
        dispatch_async(logQueue) {
            rewind(logFile)
            
            let data = NSMutableData()
            var c = fgetc(logFile)
            while c != EOF {
                data.appendBytes(&c, length: sizeof(Int8))
                c = fgetc(logFile)
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                completionHandler(logFile: data, mimeType: "text/txt")
            }
        }
    }
    
    
    // Do the printing using putc() nested in flockfile() and funlockfile() to
    // ensure that MOONLog() and regular print() statements doesn't get interleaved.
    private static func writeMessage(message: String, toStream outStream: UnsafeMutablePointer<FILE>) {
            var stdoutGenerator =  message.unicodeScalars.generate()
            flockfile(outStream)
            while let char = stdoutGenerator.next() {
                putc(Int32(char.value), outStream)
            }
            putc(10, outStream) // NewLine
            funlockfile(outStream)
    }
    
    // Returns the path to a file named by the constant LOG_FILE_NAME in the users documents directory.
    private static func getFilePath() -> String {
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(
            NSSearchPathDirectory.DocumentDirectory,
            NSSearchPathDomainMask.UserDomainMask,
            true)[0]
        
        return (documentsDirectory as NSString).stringByAppendingPathComponent(LOG_FILE_NAME)
    }
}

