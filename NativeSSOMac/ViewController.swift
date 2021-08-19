//
//  ViewController.swift
//  NativeSSOMac
//
//  Created by Huan Liu on 8/14/21.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var label: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        label.text = "haha"
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    
    @IBAction func login(_ sender: Any) {
    }
    
    @IBAction func logout(_ sender: Any) {
    }
}

