# MOON Logger

## Description

A replacement for the standard print statement in Swift for both iOS and OS X, to give more information about where a log statement came from. It will print out the date and time, file, function, line number, and the actual message, neatly organized into columns. It also has an option to save the log file to a .txt file, and retrieve it later.

`MOONLog(...)` is thread-safe as everything runs on a single serial queue. An unfortunate side-effect of this, is that if your app crashes, the last log statements before the crash won't have had time to be printed to the console yet. A workaround for this is to hit the ![Debug Run Button](http://imgur.com/t5NmEEQ.png)-button a few times until you see the final log messages.



## Instructions

### Basic Usage

MOON Logger primarily exposes one global function: `func MOONLog(items: Any...)`. This function can take any number of argument (including none), and will print them one after the other separated by whatever the `separator` argument is (the default is `" "`). This means that you can either call it with no arguments (like this `MOONLog()`) if you simply need to make sure one of your methods got called. Or you can pass in a message you want to, (like this `MOONLog("Logging from viewDidLoad")`), which will print out the location as well as the message.

The example below shows some different ways you can call `MOONLog(...)`, and what the resulting output in the console would be.

```
override func viewDidLoad() {
    super.viewDidLoad()

    MOONLog()
    MOONLog("Hello, World")
    MOONLog("Hello", "World")
    MOONLog(1, 2, 3, 4, 5, 6, 7, 8, 9)
    MOONLog("My number is:", 2)
    MOONLog("I have \(5) apples")
    MOONLog("Users", "Vegard", "Documents", "sometext.txt", separator: "/")
}
```

```
2016-01-28 02.06.56.664    l:17    ViewController.swift       viewDidLoad()                             
2016-01-28 02.06.56.674    l:18    ViewController.swift       viewDidLoad()           Hello, World
2016-01-28 02.06.56.674    l:19    ViewController.swift       viewDidLoad()           Hello World
2016-01-28 02.06.56.675    l:20    ViewController.swift       viewDidLoad()           1 2 3 4 5 6 7 8 9
2016-01-28 02.06.56.675    l:21    ViewController.swift       viewDidLoad()           My number is: 2
2016-01-28 02.06.56.675    l:22    ViewController.swift       viewDidLoad()           I have 5 apples
2016-01-28 02.06.56.676    l:23    ViewController.swift       viewDidLoad()           Users/Vegard/Documents/sometext.txt
```
</br>

### Reading & Writing the Log to a File

To handle the log file, MOON Logger exposes a struct called `MOONLogger` which has four static functions:
- `static func initializeLogFile()`
- `static func forceSaveAndClose()`
- `static func clearLog()`
- `static func getLogFile(completionHandler: (logFile: NSData?, mimeType: String) -> ())`

###### `MOONLogger.initializeLogFile()`
Call this function whenever you want your future `MOONLog(...)` calls to be saved to a file. If you want all calls to be saved to a file, you can call `initializeLogFile()` as soon as your application finishes launching, like this:
```
func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    MOONLogger.initializeLogFile()
    return true
}
```
If a file already exists, future calls to `MOONLog(...)` will simply append to that file. If the file is already open, calling this function does nothing.

###### `MOONLogger.forceSaveAndClose()`
This function is used when you don't want any future `MOONLog(...)` calls to be written to a file, or your app is about to quit and you want to make sure everything is saved properly. A typical place for this would be just before the application gets terminated in `applicationWillTerminate(...)`, like this:
```
func applicationWillTerminate(application: UIApplication) {
	MOONLogger.forceSaveAndClose()
}
```
If the file is already closed (either by already having calling this, or by not yet having called `initializeLogFile()`), calling this function does nothing.

###### `MOONLogger.clearLog()`
This function will delete everything written to the log file thus far. This is useful after the log file has somehow been collected, and you don't need it anymore. It doesn't matter if the file is open or closed while calling this. After the call, everything will be the same, except the file will be cleared.

###### `MOONLogger.getLogFile(...)`
The final function is used to retrieve the log file. It takes a `completionHandler` that will contain both the `logFile` as an `NSData?`, and the `mimeType` of the data (currently this will be text/txt) as a `String`. If you have just made a lot of calls to `MOONLog(...)`, it might take a while before the `completionHandler` is called as it waits for all the logs to be written to the log file. Whenever it does get called, it will be called on the main thread. The `logFile` argument of the `completionHandler` is an optional and will be `nil` if there was some problem retrieving the file (like if the file has not yet been created). You should use optional binding (`if let ...`) to get the actual data. A typical use case might, look like this:
```
MOONLogger.getLogFile() { logFile: NSData?, mimeType: String in
	if let logFile = logFile {
		<# Your Code #>
	}
}
```

<br />

Below is a screenshot with example output of MOON Logger. The first two are from a simple `MOONLog()` call (without any arguments), and the rest are from a call with a `String` as an argument: `MOONLog("...")`.

![Image](http://imgur.com/qluneiY.png)


## Todo

- Add support for different levels of logging (like `Information`, `Debug`, `Error`, `Warning`, etc...)


## Contact

- [@vegather on Twitter](http://www.twitter.com/vegather)
- [vegather@icloud.com](mailto:vegather@icloud.com)
