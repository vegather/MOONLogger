# MOON Logger

## Description

MOON Logger is a replacement for the standard print statement in Swift for both iOS and OS X, to give more information about where a log statement came from. It will print out the date and time, file, function, line number, and the actual message, neatly organized into columns. This is useful when you want to retrace the steps your application took to get to a specific state. MOON Logger also has an option to save the log file to a .txt file, and to retrieve it later.

It is thread-safe as everything is dispatched to a single serial queue. An unfortunate side-effect of this is that if your app crashes, the last log statements before the crash won't have had time to be printed to the console yet. A workaround for this is to hit the ![Debug Run Button](http://imgur.com/t5NmEEQ.png)-button in the debugger a few times until you see the final log messages.



## Instructions

### Basic Usage

MOON Logger primarily exposes one global function: `func MOONLog(...)`. This function takes a bunch of arguments, but typical usage of `MOONLog` will only use 0 to 3 of them, all of which are demonstrated in the example below.

- `items: Any...`: This makes `MOONLog` work just like the standard `print` function does. You can pass in 0 or more values to the argument, and they will all be appended after each other, separated by whatever the value of the `separator` argument is. See examples of this in the code snipped below. All the values passed in to this argument will be converted to a `String` using `"\(...)"`. So for example `MOONLog(4, 2)` is equivalent to `MOONLog("\(4)" + " " + "\(2)")`, and the resulting message printed out will be `4 2`.
- `separator: String`: An optional argument that sets what should separate the values passed into the `items` argument. The default is `" "`.
- `isError: Bool`: An optional argument that is used to say that this log statement represents an error. For example if you reached some unexpected state, you can use this argument to make this more prominent and easier to find in the console. Setting this to `true` will prefix your message (the value passed into `items`) with a ❌, and the output will be `stderr` instead of the standard `stdout`. You will still see this output in the console. The default value of `isError` is `false`.

`MOONLog` takes a few more optional arguments like `filePath`, `functionName`, and `lineNumber` (which is where `MOONLog` gets most of its usefulness from), as well as `stream`, and `errorStream` (which are used specify to which stream the output should go to), but these are mainly used for testing purposes.

The example below shows some different ways you can call `MOONLog(...)` with different arguments, and what the resulting output in the console would be.

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
    MOONLog("Failed to process JSON", isError: true)
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
2016-01-28 14:48:22.088    l:25    ViewController.swift       viewDidLoad()              ❌ Failed to process JSON
```
Don't worry if your file name or method name is too long. It will simply be truncated to fit neatly within the columns like this `thisIsAVeryLongMethodNameThatW...`. If you for some reason want to change the default width (like if you have a huge or tiny monitor), this can be done by changing the `FileNameWidth` and `MethodNameWidth` found in the `Constants` struct at the top of `MOONLogger.swift`. They are 25 and 40 respectively by default.

The `Constants` struct has two more constant called `ShouldIncludeTime`, and `TimestampFormat`. These are used to set whether the timestamp should be included as a prefix to the output, and what format the timestamp should be in. The string formatter for the timestamp is a bit different from the standard unicode format used by `NSDateFormatter`, and you can find documentation for that in the <a href="#links">Links</a> below. Setting `ShouldIncludeTime` to `false` will give you a performance increase of about 25%, but you will of course not be able to tell when the log happened. This is true both for the standard output to console (`stdout` and `stderr`), as well as for writing to the log file. The default for `ShouldIncludeTime` is `true`, and `TimestampFormat` has a default of `%Y-%m-%d %H:%M:%S` (see the result of this in the example above).

</br>

### Reading & Writing the Log to a File

`MOONLogger` is capable of writing to a log file as well as to the console. This file will be stored in `~/Library/Logs/<Application Name> Logs/<Application Name>.log` on OS X, and in `~/Documents/Logs/<Application Name> Logs/<Application Name>.log` on iOS.

To manage the log file, MOON Logger exposes a struct called `MOONLogger` which has four static functions:
- `static func startWritingToLogFile()`
- `static func stopWritingToLogFile()`
- `static func clearLogFile()`
- `static func getLogFile(completionHandler: (logFile: NSData?, mimeType: String) -> ())`

</br>
##### `MOONLogger.startWritingToLogFile()`
Call this function whenever you want your future `MOONLog(...)` calls to be saved to a file. If you want all calls to be saved to a file, you can call `startWritingToLogFile()` as soon as your application finishes launching, like this:
```
func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    MOONLogger.startWritingToLogFile()
    return true
}
```
If a file already exists, future calls to `MOONLog(...)` will simply append to that file. If the file is already open, calling this function does nothing.

</br>
##### `MOONLogger.stopWritingToLogFile()`
This function is used when you don't want any future `MOONLog(...)` calls to be written to a file. There's no need to call this when the app is closing (in `applicationWillTerminate()`) as the file will be saved and closed automatically by the system. If the file is already closed (either by already having called this, or by not yet having called `startWritingToLogFile()`), calling this function does nothing.

</br>
##### `MOONLogger.clearLogFile()`
This function will delete everything written to the log file thus far. This is useful after the log file has somehow been collected and you don't need it anymore, or if you want a fresh log file every time you start the application. It doesn't matter if the file is open or closed while calling this. After the call, everything will be the same, except the file will be cleared. This means that if you call `MOONLogger.startWritingToLogFile()`, and then `MOONLogger.clearLogFile()`, future call to `MOONLog(...)` will be written to the log file.

</br>
##### `MOONLogger.getLogFile(...)`
`getLogFile(...)` is used to retrieve the log file. It takes a `completionHandler` that will contain both the `logFile` as an `NSData?`, and the `mimeType` of the data (currently this will be `text/plain`) as a `String`. If you have just made a lot of calls to `MOONLog(...)`, it might take a while before the `completionHandler` is called as it waits for all the logs to be written to the log file. By default the `completionHandler` will be called on the main thread, but you can override this by passing a `dispatch_queue_t` to the `callbackQueue` parameter.

The `logFile` argument of the `completionHandler` is an optional and will be `nil` if there was some problem retrieving the file (like if the file has not yet been created). You should use optional binding (`guard let ...`) to get the actual data. A typical use case might look like this:
```
MOONLogger.getLogFile() { logFile, mimeType in
	guard let logFile = logFile else { return }
	<# Your Code #>
}
```

<br />

Below is a screenshot with example output of MOON Logger. The first two are from a simple `MOONLog()` call (without any arguments), and the rest are from a call with a `String` as an argument: `MOONLog("...")`.

![Image](http://imgur.com/qluneiY.png)

## <a name="links"></a>Links
- Documentation for `strftime`: http://www.cplusplus.com/reference/ctime/strftime/
- `strftime` helper site: http://strftime.net

## Todo

- Add support for different levels of logging (like `Information`, `Debug`, `Error`, `Warning`, etc...). A useful addition to this would be to be able to set which `MOONLog(...)` calls to include in the log file.
- Write more tests


## Contact

- [@vegather on Twitter](http://www.twitter.com/vegather)
