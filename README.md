# MOON Logger

## Description

A replacement for the standard print statement in Swift for both iOS and OS X, to give 
more information about where the log come from. It will print out the date and time, 
line number, file, function, and the actual message, neatly organized into columns. 
It also has on option to save the log file to a .txt file, and retrieve it later.

It should be thread safe, as everything runs on a single serial queue. A side-effect of
this is that if your app crashes, the last log statements before the crash won't have had
time to be printed to the console yet. A workaround for this is to hit the ⧐ button


## Demo

Testing

![Image](http://imgur.com/qluneiY.png)

## Contact

- [@vegather on Twitter](http://www.twitter.com/vegather)
- [vegard@moonwearables.com](mailto:vegard@moonwearables.com)

  