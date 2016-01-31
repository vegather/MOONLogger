//
//  ViewFileViewController.swift
//  MOONLoggerTester
//
//  Created by Vegard Solheim Theriault on 27/01/16.
//  Copyright © 2016 MOON Wearables. All rights reserved.
//

import UIKit

class ViewFileViewController: UIViewController {

    var text: String = "" {
        didSet {
            guard textView != nil else { return }
            textView.text = text
        }
    }
    
    @IBOutlet private weak var textView: UITextView! {
        didSet {
            textView.text = text
        }
    }
}
