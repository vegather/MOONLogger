//
//  ViewController.swift
//  MOONLoggerTester
//
//  Created by Vegard Solheim Theriault on 26/01/16.
//  Copyright © 2016 MOON Wearables. All rights reserved.
//

import UIKit
import MessageUI

class ViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    @IBAction func forceSaveAndCloseButtonTapped() {
        MOONLogger.forceSaveAndCloseLogFile()
        print("forceSaveAndCloseButtonTapped")
    }
    
    @IBAction func clearFileButtonTapped() {
        MOONLogger.clearLogFile()
        print("clearFileButtonTapped")
    }
    
    @IBAction func openFileButtonTapped() {
        MOONLogger.initializeLogFile()
        print("openFileButtonTapped")
    }
    
    @IBAction func writeDataButtonTapped() {
        for i in 0..<1000 {
            MOONLog("MAIN:", i)
        }
    }
    
    
    
    // -------------------------------
    // MARK: Segue Management
    // -------------------------------
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        MOONLogger.getLogFile() {logFile, _ in
            guard let destination = segue.destinationViewController as? ViewFileViewController else { return }
            guard let logFile = logFile else { return }
            guard let text = String(data: logFile, encoding: NSUTF8StringEncoding) else { return }
            
            destination.text = text
        }
    }
    
    
    
    
    // -------------------------------
    // MARK: Private Helpers
    // -------------------------------
    
    func presentAlertWithTitle(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let ok    = UIAlertAction(title: "Got it", style: .Default, handler: nil)
        alert.addAction(ok)
        presentViewController(alert, animated: true, completion: nil)
    }
}
