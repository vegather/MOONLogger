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

private struct Constants {
    static let ShouldIncludeTime = true
    static let TimestampFormat   = "%Y-%m-%d %H:%M:%S" /* Documentation: http://www.cplusplus.com/reference/ctime/strftime/ */
    static let FileNameWidth     = 25
    static let MethodNameWidth   = 40
}

private let logQueue = dispatch_queue_create("com.moonLogger.logQueue", DISPATCH_QUEUE_SERIAL)
private var logFile: UnsafeMutablePointer<FILE> = nil



/**
 A log statement that lets you easily see which file, function, and line number a log statement came from.
 
 <br>
 
 Usually you would call this function with just one argument, like this:
 ```
 MOONLog("Hello, World!")
 ```
 This will print out a timestamp, the file, function, and line number the call was from, as well as the message you provided
 
 <br><br>
 
 The `filePath`, `functionName`, and `lineNumber` arguments should be left as they are. They default to `#file`, `#function`, and `#line` respectively, which is how `MOONLog(...)` is able to do its magic.
 
 The `stream` and `errorStream` arguments are the locations that `MOONLog` will write to. `errorStream` will be used if `isError` is `true`, otherwise `stream` is used. `stream` defaults to `stdout` whereas `errorStream` defaults to `stderr`.

 - Parameter items: `Any...` - An optional list of items you want printed. Every item will be converted to a `String` like this: `"\(item)"`.
 - Parameter separator: `String` - An optional separator string that will be inserted between each of the `items`.
 - Parameter isError: `Bool` - If `true`, a ❌ will be prepended to the message to make errors more visible in the console. The output will be `errorStream` instead of `stream` if this is `true`. The default is `false`.
 */
func MOONLog(
    items       : Any...,
    separator   : String = " ",
    isError     : Bool   = false,
    filePath    : String = #file,
    functionName: String = #function,
    lineNumber  : Int    = #line,
    stream      : UnsafeMutablePointer<FILE> = stdout,
    errorStream : UnsafeMutablePointer<FILE> = stderr)
{
    dispatch_async(logQueue) {
        
        var printString = ""
		
        // Going with this ANSI C solution here because it's about 1.5x
        // faster than the NSDateFormatter alternative.
        if Constants.ShouldIncludeTime {
            let bufferSize = 32
            var buffer = [Int8](count: bufferSize, repeatedValue: 0)
            var timeValue = time(nil)
            let tmValue = localtime(&timeValue)
            
            strftime(&buffer, bufferSize, Constants.TimestampFormat, tmValue)
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
        if fileName.characters.count > Constants.FileNameWidth {
            fileName = fileName.substringToIndex(fileName.startIndex.advancedBy(Constants.FileNameWidth - 3)) + "..."
        }
        
        // Limit the functionName to 40 characters
        var functionNameToPrint = functionName
        if functionName.characters.count > Constants.MethodNameWidth {
            functionNameToPrint = functionName.substringToIndex(functionName.startIndex.advancedBy(Constants.MethodNameWidth - 3)) + "..."
        }
        
        // Construct the message to be printed
        var message = isError ? "❌ " : ""
        for (i, item) in items.enumerate() {
            message += "\(item)"
            if i < items.count-1 { message += separator }
        }

        printString += String(format: "l:%-5d %-\(Constants.FileNameWidth)s  %-\(Constants.MethodNameWidth)s  %@",
            lineNumber,
            COpaquePointer(fileName.cStringUsingEncoding(NSUTF8StringEncoding)!),
            COpaquePointer(functionNameToPrint.cStringUsingEncoding(NSUTF8StringEncoding)!),
            message)
        
        // Write to the specified stream (stdout by default)
        if isError { MOONLogger.writeMessage(printString, toStream: errorStream) }
        else       { MOONLogger.writeMessage(printString, toStream: stream) }
        
        if logFile != nil {
            // Write to the logFile
            MOONLogger.writeMessage(printString, toStream: logFile)
            // Save the file immediately (not very efficient). Could benefit from some kind of watchdog
            fflush(logFile)
        }
    }
}


public struct MOONLogger {
    
    /**
     Sets up the log file. If there already exists a log file, future `MOONLog(...)` calls will simply append to that file. If no file exists, a new one is created.
     
     This should be called as soon as you want to store `MOONLog(...)` calls in a log file. Typically you would call this at the beginning of `application(_: didFinishLaunchingWithOptions:)` in your `AppDelegate`.
     
     - seealso: `application(_: didFinishLaunchingWithOptions:)`
     */
    public static func startWritingToLogFile() {
        if logFile == nil { logFile = fopen(getLogFilePath(), "a+") }
    }
    
    
    /**
     After calling this, all calls to `MOONLog(...)` will not be written to the log file. If you want your `MOONLog...` calls to be written to the log file again, simply call `MOONLogger.startWritingToLogFile()`. This method writes everything written to the file thus far to be saved (by flushing the file), and then closes the file. There's no need to call this when the app is closing (in `applicationWillTerminate()`) as the file will be saved and closed automatically be the system.
     
     - seealso: `MOONLogger.startWritingToLogFile()`
     */
    public static func stopWritingToLogFile() {
        if logFile != nil {
            dispatch_async(logQueue) {
                flockfile(logFile)
                fclose(logFile)
                funlockfile(logFile)
                logFile = nil
            }
        }
    }
    
    
    /**
     Removes all the data stored in the log file on a background thread, and returns immediately.
     
     After calling this, the `NSData` returned from `MOONLogger.getLogFile(...)` will be `nil`.
     - seealso: `MOONLogger.getLogFile(...)`
     
     `MOONLogger.startWritingToLogFile()`
     */
    public static func clearLogFile() {
        // Doing it asynchronously on the logQueue to make sure all the MOONLog(...)
        // statements that were done before this call is finished before clearing it.
        // That way you won't get any leftover junk in the file.
        dispatch_async(logQueue) {
            if logFile != nil {
                // Open the file for reading & writing, and destroy any content that's in there.
                logFile = freopen(getLogFilePath(), "w+", logFile)
            } else {
                remove(getLogFilePath())
            }
        }
    }
    
    
    /**
     If you have initialized a log file (see `startWritingToLogFile()`), this will wait until all pending `MOONLog(...)` calls are written to the file, and then returns the `logFile` data in the `completionHandler` on the callbackQueue (will default to the main queue). If you have not initialized the log file, or closed it (see `startWritingToLogFile()` and `stopWritingToLogFile()`), the log file will get returned immediately in the completion handler on the callbackQueue.
     
     - seealso: `MOONLogger.startWritingToLogFile()`
     
     `MOONLogger.stopWritingToLogFile()`
     
     `MOONLogger.clearLogFile()`
     
     - Parameter callbackQueue: An optional argument where you can pass in the queue you want the `completionHandler` to be called on. If you don't provide this argument, it will default to `dispatch_get_main_queue()`.
     - Parameter completionHandler: A completion handler that returns both the `logData` as well as the `mimeType` of the log file (currently `text/plain`). The `mimeType` is useful if you plan on sending this data in an email, or something similar. If the log file was empty (either because you called `clearLogFile` or because you never called `startWritingToLogFile`), `logFile` will be nil, and `mimeType` will be an empty string.
     */
    public static func getLogFile(
        callbackQueue callbackQueue: dispatch_queue_t = dispatch_get_main_queue(),
                      completionHandler: (logFile: NSData?, mimeType: String) -> ())
    {
        dispatch_async(logQueue) {
            if logFile == nil {
                let tempLogFile = fopen(getLogFilePath(), "r")
                if tempLogFile == nil {
                    dispatch_async(callbackQueue) {
                        completionHandler(logFile: nil, mimeType: "")
                    }
                    return
                }
                let data = fetchTheFile(tempLogFile)
                fclose(tempLogFile)
                dispatch_async(callbackQueue) {
                    // If the data length is 0, return nil
                    if data.length == 0 { completionHandler(logFile: nil , mimeType: "")           }
                    else                { completionHandler(logFile: data, mimeType: "text/plain") }
                }
            } else {
                fflush(logFile)
                let data = fetchTheFile(logFile)
                dispatch_async(callbackQueue) {
                    completionHandler(logFile: data, mimeType: "text/plain")
                }
            }
        }
    }
    
    
    /// *Synchronously* gets the data that's in the logFile, and returns it as an NSData.
    private static func fetchTheFile(file: UnsafeMutablePointer<FILE>) -> NSData {
        let data = NSMutableData()
        
        flockfile(file)
        rewind(file)
        while var c = Optional(fgetc(file)) where c != EOF {
            data.appendBytes(&c, length: sizeof(Int8))
        }
        funlockfile(file)
        
        return data
    }
    
    /// Do the printing using `putc()` nested in `flockfile()` and `funlockfile()` to
    /// ensure that `MOONLog()` and regular `print()` statements doesn't get interleaved.
    private static func writeMessage(message: String, toStream outStream: UnsafeMutablePointer<FILE>) {
        flockfile(outStream)
        for char in (message + "\n").utf8 {
            putc(Int32(char), outStream)
        }
        funlockfile(outStream)
    }
    
    
    
    // -------------------------------
    // MARK: File Location
    // -------------------------------
    
    /// If on OS X, a folder with the name of CFBundleDisplayName inside the ~/Library/Logs will be returned
    /// If on iOS, the users documents directory will be returned
    /// If some error happened along the way, this will return an empty string (""). The reasoning behind this is that all the stdio calls (fopen, remove, freopen) will quietly fail (by returning some error value). MOONLogger is prepared to handle these failures.
    private static func getLogFilePath() -> String {
        #if os(OSX)
            return makeSureLogFileWithFoldersExistsInDirectory(.LibraryDirectory)  ?? ""
        #elseif os(iOS)
            return makeSureLogFileWithFoldersExistsInDirectory(.DocumentDirectory) ?? ""
        #else
            return ""
        #endif
    }
    
    /// Returns the path to the file if the folder exists, or if it was successfully created.
    /// Returns nil if the folder does not exists, and could not be created.
    private static func makeSureLogFileWithFoldersExistsInDirectory(searchPathDirectory: NSSearchPathDirectory) -> String? {
        let foundDirectories = NSSearchPathForDirectoriesInDomains(searchPathDirectory, .UserDomainMask, true )
        guard foundDirectories.count == 1 else {
            MOONLog("Weird number of document directories: \(foundDirectories)", isError: true)
            return nil
        }
        
        let logsFolder = (foundDirectories[0] as NSString).stringByAppendingPathComponent("Logs")
        
        // Get the CFBundleDisplayName if it's present, otherwise get the CFBundleName
        let infoDict = NSBundle.mainBundle().infoDictionary
        guard let appName = infoDict?["CFBundleDisplayName"] as? String ?? infoDict?["CFBundleName"] as? String else {
            MOONLog("Unable to find the display name of the app bundle dict: \(infoDict)", isError: true)
            return ""
        }
        
        // Make sure the "Logs/<AppName> Logs" folder exists
        let logFolder = (logsFolder as NSString).stringByAppendingPathComponent("\(appName) Logs")
        guard makeSureFolderExistsAtPath(logFolder) else { return nil }
        
        // Create the path to the file
        let logWithoutExtension = (logFolder as NSString).stringByAppendingPathComponent(appName)
        guard let path = (logWithoutExtension as NSString).stringByAppendingPathExtension("log") else {
            MOONLog("Could not add extension \"log\" to path \(logWithoutExtension)", isError: true)
            return nil
        }
        
        // Make sure the file exists, return nil if it couldn't be created
        if NSFileManager.defaultManager().fileExistsAtPath(path) == false {
            guard NSFileManager.defaultManager().createFileAtPath(path, contents: nil, attributes: nil) else {
                MOONLog("Unable to create the file at path: \(path)", isError: true)
                return nil
            }
        }
        
        return path
    }
    
    /// Returns true if the folder exists, or if it was successfully created.
    /// Returns false if the folder does not exists, and could not be created
    private static func makeSureFolderExistsAtPath(path: String) -> Bool {
        var isFolder: ObjCBool = false
        NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isFolder)
        if isFolder.boolValue == false {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(
                    path,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch let error as NSError {
                MOONLog("Failed to create the folder at \(path) with error: \(error)", isError: true)
                return false
            }
        }
        
        return true
    }
}

