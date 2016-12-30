//
//  ViewController.swift
//  CNCPlotter
//
//  Created by Andy Qua on 29/12/2016.
//  Copyright © 2016 Andy Qua. All rights reserved.
//

import Cocoa

extension NSTextView {
    func append(string: String) {
        self.textStorage?.append(NSAttributedString(string: string))
        self.scrollToEndOfDocument(nil)
    }
}


class ViewController: NSViewController {
    @IBOutlet weak var connectedBtn: NSButton!
    @IBOutlet weak var refreshBtn: NSButton!
    @IBOutlet weak var serialDeviceCombo: NSComboBox!
    @IBOutlet var txtGCode: NSTextView!
    @IBOutlet var txtConsole: NSTextView!

    var serialHandler : SerialHandler!
    var serialDevices = [String]()
    
    var streaming = false
    var gcode = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        serialHandler = SerialHandler()
//        serialHandler.testMode = true
        serialHandler.portOpenCallback = { [weak self] in
            self?.serialPortOpened()
        }
        
        serialHandler.portCloseCallback = { [weak self] in
            self?.serialPortClosed()
        }
        
        serialHandler.readPrintDataCallback = { [weak self] (data) in
            self?.serialPortReadData( data:data )
        }
        
        // Get the list of serial devices
        refreshSerialPorts( autoConnectIfPossible:true)

    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func refreshSerialPorts( autoConnectIfPossible: Bool = false ) {
        serialDevices = serialHandler.getUSBSerialDevices()
        serialDeviceCombo.removeAllItems()
        serialDeviceCombo.addItems(withObjectValues: serialDevices)
        serialDeviceCombo.stringValue = ""
        
        // If we have a wchusbserial14xxx device connected then open that otherwise don't
        let filteredStrings = serialDevices.filter({(item: String) -> Bool in
            return item.lowercased().contains("wchusbserial14".lowercased())
        })
        
        if filteredStrings.count > 0 {
            let device = filteredStrings[0]
            let index = serialDevices.index(of: device)!
            serialDeviceCombo.selectItem(at: index)
            
            if autoConnectIfPossible {
                serialHandler.open( device: device)
            }
        }
        
    }

    @IBAction func connectPressed(_ sender: AnyObject) {
        if self.connectedBtn.title == "Connect" {
            serialHandler.open(device:serialDeviceCombo.stringValue)
        } else {
            serialHandler.close()
        }
    }

    @IBAction func refreshSerialPortsPressed(_ sender: AnyObject) {
        refreshSerialPorts()
    }
    
    @IBAction func sendGCodePressed(_ sender: AnyObject) {
        self.txtConsole.string = ""
        if let text = self.txtGCode.string {
            streaming = true
            gcode = text.components(separatedBy: "\n")
        }
        
        sendGCode()
    }
    
    @IBAction func stopPressed(_ sender: AnyObject) {
        self.gcode.removeAll(keepingCapacity: false)
    }
    
    @IBAction func clearConsolePressed(_ sender: AnyObject) {
        self.txtConsole.string = ""
    }
    
    @IBAction func upPressed(_ sender: AnyObject) {
        serialHandler.send( "G01 Y17\nM18\n")
    }
    
    @IBAction func downPressed(_ sender: AnyObject) {
        serialHandler.send( "G01 Y-17\nM18\n")
    }
    
    @IBAction func leftPressed(_ sender: AnyObject) {
        serialHandler.send( "G01 X-17\nM18\n")
    }
    
    @IBAction func rightPressed(_ sender: AnyObject) {
        serialHandler.send( "G01 X17\nM18\n")
    }
    
    @IBAction func homePressed(_ sender: AnyObject) {
        serialHandler.send( "G01 X0 Y0\nM18\n")
    }
    
    @IBAction func rehomePressed(_ sender: AnyObject) {
        serialHandler.send( "H\nM18\n")
    }
    
    @IBAction func raisePenPressed(_ sender: AnyObject) {
        serialHandler.send( "U\n")
    }
    
    @IBAction func lowerPenPressed(_ sender: AnyObject) {
        serialHandler.send( "D\n")
    }
    
    func sendGCode() {
        if gcode.count == 0 {
            if streaming {
                streaming = false
                // turn off motors
                serialHandler.send("M18 (Turn off motors)\n")
            }
            return
        }
        
        // Pop first line from the list and send it
        var line = ""
        while line == "" && gcode.count > 0 {
            line = gcode.remove(at: 0).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if line != "" {
            line += "\n"
            //txtConsole.append(string: line )
            serialHandler.send(line)
//            print( "Sending \(line)")
        }
    }

    // MARK: serialManager callbacks
    func serialPortOpened() {
        
        self.connectedBtn.title = "Disconnect"
    }
    
    func serialPortClosed() {
        self.connectedBtn.title = "Connect"
        self.connectedBtn.isEnabled = true
        
        refreshSerialPorts()
    }
    
    var currentLine = ""
    func serialPortReadData( data : Data ) {
        if let str = String(data: data, encoding: .utf8) {
            print( "received \(str)")

            // Append buffer to currentLine (up to "\n")
            for var c in str.characters {
                if c == "\r" {
                    continue
                }
                if c == "\r\n" {
                    c = "\n"
                }

                currentLine.append(c)
                if c == "\n" {
//                    print( "  currLine - [\(currentLine)]")
                    txtConsole.append(string: currentLine)
                    
                    if currentLine == "ok\n" {
//                        print( "Sending next gcode")
                        sendGCode()
                    } else {
                        if currentLine.hasPrefix(("ok") ) {
//                            print( "Currentline - \(currentLine)")
                        }
                    }
                    currentLine = ""
                }
            }
        }
    }
}

