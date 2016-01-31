# MOON Logger

## Description

MOON Logger is a replacement for the standard print statement in Swift for both iOS and OS X, to give more information about where a log statement came from. It will print out the date and time, file, function, line number, and the actual message, neatly organized into columns. It also has an option to save the log file to a .txt file, and to retrieve it later.

It is thread-safe as everything runs on a single serial queue. An unfortunate side-effect of this is that if your app crashes, the last log statements before the crash won't have had time to be printed to the console yet. A workaround for this is to hit the ![Debug Run Button](http://imgur.com/t5NmEEQ.png)-button in the debugger a few times until you see the final log messages.



## Instructions

### Basic Usage

MOON Logger primarily exposes one global function: `func MOONLog(items: Any...)`. This function can take any number of argument (including none), and will print them one after the other separated by whatever the `separator` argument is (the default is `" "`). This means that you can either call it with no arguments (like this `MOONLog()`) if you simply need to make sure one of your methods got called. Or you can pass in any objects or values you'd like to print out (like this `MOONLog("Hello, World")`), which will print out the location as well as the message. All the arguments you pass in will be converted to a `String` using `"\(...)"`. So for example `MOONLog(4, 2)` is equivalent to `MOONLog("\(4)" + " " + "\(2)")`, and the resulting message printed out will be `4 2`.

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
    MOONLog(192, 168, 0, 1, separator: ".")
    MOONLog("Users", "Vegard", "Documents", "sometext.txt", separator: "/")
}
```

```
2016-01-28 14:48:22.077    l:17    ViewController.swift       viewDidLoad()              
2016-01-28 14:48:22.086    l:18    ViewController.swift       viewDidLoad()              Hello, World
2016-01-28 14:48:22.087    l:19    ViewController.swift       viewDidLoad()              Hello World
2016-01-28 14:48:22.087    l:20    ViewController.swift       viewDidLoad()              1 2 3 4 5 6 7 8 9
2016-01-28 14:48:22.087    l:21    ViewController.swift       viewDidLoad()              My number is: 2
2016-01-28 14:48:22.087    l:22    ViewController.swift       viewDidLoad()              I have 5 apples
2016-01-28 14:48:22.088    l:23    ViewController.swift       viewDidLoad()              192.168.0.1
2016-01-28 14:48:22.088    l:24    ViewController.swift       viewDidLoad()              Users/Vegard/Documents/sometext.txt
```
Don't worry if your file name or method name is too long. It will simply be truncated to fit neatly within the columns like this `thisIsAVeryLongMethodNameThatW...`. If you for some reason want to change the default width (like if you have a huge or tiny monitor), this can be done by changing the `FileNameWidth` and `MethodNameWidth` found in the `Constants` struct at the top of `MOONLogger.swift`. They are 25 and 40 respectively by default.

The `Constants` struct also has two other constants (`LogFileName` and `ShouldIncludeTime`) which you can change to your liking. Setting `ShouldIncludeTime` to false will give you a performance increase of about 25%, but you will of course not be able to tell when the log happened. This is true both for the standard output to console, as well as for writing to the log file.

</br>

### Reading & Writing the Log to a File

To handle the log file, MOON Logger exposes a struct called `MOONLogger` which has four static functions:
- `static func initializeLogFile()`
- `static func forceSaveAndCloseLogFile()`
- `static func clearLogFile()`
- `static func getLogFile(completionHandler: (logFile: NSData?, mimeType: String) -> ())`

</br>
##### `MOONLogger.initializeLogFile()`
Call this function whenever you want your future `MOONLog(...)` calls to be saved to a file. If you want all calls to be saved to a file, you can call `initializeLogFile()` as soon as your application finishes launching, like this:
```
func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    MOONLogger.initializeLogFile()
    return true
}
```
If a file already exists, future calls to `MOONLog(...)` will simply append to that file. If the file is already open, calling this function does nothing.

</br>
##### `MOONLogger.forceSaveAndCloseLogFile()`
This function is used when you don't want any future `MOONLog(...)` calls to be written to a file. There's no need to call this when the app is closing (in `applicationWillTerminate()`) as the file will be saved and closed automatically be the system. If the file is already closed (either by already having called this, or by not yet having called `initializeLogFile()`), calling this function does nothing.

</br>
##### `MOONLogger.clearLogFile()`
This function will delete everything written to the log file thus far. This is useful after the log file has somehow been collected, and you don't need it anymore. It doesn't matter if the file is open or closed while calling this. After the call, everything will be the same, except the file will be cleared.

</br>
##### `MOONLogger.getLogFile(...)`
The final function is used to retrieve the log file. It takes a `completionHandler` that will contain both the `logFile` as an `NSData?`, and the `mimeType` of the data (currently this will be `text/txt`) as a `String`. If you have just made a lot of calls to `MOONLog(...)`, it might take a while before the `completionHandler` is called as it waits for all the logs to be written to the log file. Whenever it does get called, it will be called on the main thread. The `logFile` argument of the `completionHandler` is an optional and will be `nil` if there was some problem retrieving the file (like if the file has not yet been created). You should use optional binding (`if let ...`) to get the actual data. A typical use case might, look like this:
```
MOONLogger.getLogFile() { logFile, mimeType in
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
