//
//  AppDelegate.swift
//  MOONLoggerTester
//
//  Created by Vegard Solheim Theriault on 26/01/16.
//  Copyright © 2016 MOON Wearables. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
//        MOONLogger.initializeLogFile()
        return true
    }

    func applicationWillTerminate(application: UIApplication) {
//        MOONLogger.forceSaveAndClose()
    }


}

