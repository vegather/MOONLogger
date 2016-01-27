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

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        MOONLog("Hello, World")
//        MOONLog("Hello", "World")
//        MOONLog(1, 2, 3, 4, 5, 6, 7, 8, 9)
//        MOONLog("My number is:", 2)
//        MOONLog("I have \(5) apples")
//        MOONLog("I have %d apples", 5)
//        MOONLog("Users", "Vegard", "Documents", "sometext.txt", separator: "/")
//        MOONLog()
        
        
    }
    
    @IBAction func sendEmailButtonTapped() {
        sendEmail()
        // test
        print("sendEmailButtonTapped")
    }
    
    @IBAction func forceSaveAndCloseButtonTapped() {
        MOONLogger.forceSaveAndClose()
        print("forceSaveAndCloseButtonTapped")
    }
    
    @IBAction func clearFileButtonTapped() {
        MOONLogger.clearLog()
        print("clearFileButtonTapped")
    }
    
    @IBAction func openFileButtonTapped() {
        MOONLogger.initializeLogFile()
        print("openFileButtonTapped")
    }
    
    @IBAction func writeDataButtonTapped() {
        for i in 0..<10 {
            MOONLog("MAIN", i)
        }
    }
    
    
    
    
    
    // -------------------------------
    // MARK: Email Handling
    // -------------------------------
    
    private func sendEmail() {
        if MFMailComposeViewController.canSendMail() {
            let formatter = NSDateFormatter()
            formatter.dateStyle = NSDateFormatterStyle.MediumStyle
            formatter.timeStyle = NSDateFormatterStyle.ShortStyle
            
            MOONLogger.getLogFile { logFile, mimeType in
                guard let logFile = logFile else {
                    print("Could not get the sleep data file")
                    return
                }
                
                print("SIZE: \(logFile.length)")
                
                let formattedDateTime = formatter.stringFromDate(NSDate())
                
                let composer = MFMailComposeViewController()
                composer.setSubject("LogFile - \(formattedDateTime)")
                composer.setToRecipients(["vegather@icloud.com"])
                composer.addAttachmentData(logFile, mimeType: mimeType, fileName: "LogFile - \(UIDevice.currentDevice().name) - \(formattedDateTime).txt")
                composer.mailComposeDelegate = self
                self.presentViewController(composer, animated: true, completion: nil)
            }
        } else {
            presentAlertWithTitle("Mail not available",
                message: "It appears you don't have mail set up on your phone. Go to Settings and add your mail address")
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        dismissViewControllerAnimated(true, completion: nil)
        
        if error == nil {
            if result == MFMailComposeResultCancelled {
                print("MFMailComposeResultCancelled")
            } else if result == MFMailComposeResultSaved {
                print("MFMailComposeResultSaved")
                presentAlertWithTitle("Saved", message: "Your draft saved successfully")
            } else if result == MFMailComposeResultSent {
                print("MFMailComposeResultSent")
                presentAlertWithTitle("Sent", message: "Successfully sent your log file.")
            } else if result == MFMailComposeResultFailed {
                print("MFMailComposeResultFailed")
            }
        } else {
            guard let error = error else { return }
            if UInt32(error.code) == MFMailComposeErrorCodeSendFailed.rawValue {
                presentAlertWithTitle("Failed to send your mail", message: error.localizedDescription)
            } else if UInt32(error.code) == MFMailComposeErrorCodeSaveFailed.rawValue {
                presentAlertWithTitle("Failed to save your draft", message: error.localizedDescription)
            }
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
