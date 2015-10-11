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

- Show two log statements using the global functions MOONLog(), MOONLog("Message")
- Show how to turn log saving, and time on and off
- Show how to retrieve the log file
- Show how to clear the log file
- Show how to force save in applicationWillTerminate in case of termination

MOON Logger exposes one global function: `func MOONLog(message: String = "")`. This 
function optionally takes a string as an argument. This means that you can either call
it with no arguments, like this `MOONLog()` to just print out the location of the call 
(see `viewDidLoad()` in the screenshot below). Or you can optionally pass in a log message,
like this `MOONLog("Logging from viewDidLoad")`, which will print out the location as
well as the message.

<br />

MOON Logger has two options available:
- `SHOULD_SAVE_LOG_TO_FILE`: Which sets if the log statements should be saved to a file
(off by default).
- `SHOULD_INCLUDE_TIME`: Which sets if the date and time should be included in the log 
statements. Turning this off will improve performance (on by default).

![Image](http://imgur.com/qluneiY.png)

## Contact

- [@vegather on Twitter](http://www.twitter.com/vegather)
- [vegard@moonwearables.com](mailto:vegard@moonwearables.com)

  