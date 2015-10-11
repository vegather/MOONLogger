# MOON Logger

## Description

A replacement for the standard print statement in Swift for both iOS and OS X, to give 
more information about where the log come from. It will print out the date and time, 
line number, file, function, and the actual message, neatly organized into columns. 
It also has on option to save the log file to a .txt file, and retrieve it later.

It should be thread safe, as everything runs on a single serial queue. A side-effect of
this though, is that if your app crashes, the last log statements before the crash won't 
have had time to be printed to the console yet. A workaround for this is to hit the 
![Debug Run Button](http://imgur.com/t5NmEEQ.png)-button a few times until you see the 
final log messages.



## Instructions

MOON Logger exposes one global function: `func MOONLog(message: String = "")`. This 
function optionally takes a string as an argument. This means that you can either call
it with no arguments, like this `MOONLog()` to just print out the location of the call 
(see `viewDidLoad()` in the screenshot below). Or you can optionally pass in a log message,
like this `MOONLog("Logging from viewDidLoad")`, which will print out the location as
well as the message.

<br />

MOON Logger has two options available, both of which are at the top of MOONLogger.swift:
- `SHOULD_SAVE_LOG_TO_FILE`: Which sets if the log statements should be saved to a file
(off by default).
- `SHOULD_INCLUDE_TIME`: Which sets if the date and time should be included in the log 
statements. Turning this off will improve performance (on by default).

<br />

To handle the log file, MOON Logger exposes a struct with three static functions:
- `static func forceSave()`
- `static func clearLog()`
- `static func getLogFile(completionHandler: (logFile: NSData?, mimeType: String?) -> ())`

The first function, `forceSave()`, is useful if you need to ensure that the log file gets
save immediately. A typical place for this would be just before the application gets 
terminated in `applicationWillTerminate(...)`, like this:
```
func applicationWillTerminate(application: UIApplication) {
	MOONLogger.forceSave()
}
```

The second function, `clearLog()`, is to delete the log file. This is useful after the
log file has somehow been collected, and you don't need it anymore.


The third function, `getLogFile(...)` is to retrieve the log file. It has a 
completionHandler closure that will contain both the data, and the MIME type of the data
(currently this will be text/txt). Notice that both of these are optional though. This is
because the file retrieval might fail (in the case it hasn't been created yet), and you
should use optional binding to get the values (`if let ...`). A typical use case might
look like this:
```
MOONLogger.getLogFile { (logFile: NSData?, mimeType: String?) -> () in
	if let logFile = logFile, mimeType = mimeType {
		...
	}
}
```

<br />

Below is a screenshot with example output of MOON Logger. The first two are from a simple
`MOONLog()` call (without any arguments), and the rest are from a call with a message
as an argument: `MOONLog("...")`.

![Image](http://imgur.com/qluneiY.png)

## Contact

- [@vegather on Twitter](http://www.twitter.com/vegather)
- [vegard@moonwearables.com](mailto:vegard@moonwearables.com)

  