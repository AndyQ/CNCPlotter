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
    
    @available(OSX 10.12.2, *)
    override open func makeTouchBar() -> NSTouchBar? {
        
        let touchBar = super.makeTouchBar()
        touchBar?.delegate = self
        
        return touchBar
    }

}

class NumberValueFormatter : NumberFormatter {

    override func isPartialStringValid(_ partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        if (partialString.utf8.count == 0) {
            return true
        }
        
        if (partialString.rangeOfCharacter(from:NSCharacterSet(charactersIn: "1234567890.").inverted) != nil) {
            NSBeep()
            return false
        }
        
        return true
    }
}

let xMin = -20
let xMax = 20
let yMin = -20
let yMax = 20

 class ViewController: NSViewController, NSTextFieldDelegate {
    @IBOutlet weak var connectedBtn: NSButton!
    @IBOutlet weak var refreshBtn: NSButton!
    @IBOutlet weak var serialDeviceCombo: NSComboBox!
    @IBOutlet var txtGCode: NSTextView!
    @IBOutlet var txtConsole: NSTextView!
    @IBOutlet weak var gcodeView: GCodeRenderingView!
    @IBOutlet weak var txtScaling: NSTextField!

    var serialHandler : SerialHandler!
    var serialDevices = [String]()
    
    var streaming = false
    var gcode = [String]()
    var gcodeFile : GCodeFile?
    
    var scale : Float = 1.0

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
        
        // Register for notifications of new gcode data
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.gcodeUpdated(_:)), name: notif_newDataAvailable, object: nil)
        
        let formatter = NumberFormatter()
        formatter.usesSignificantDigits = false
        formatter.allowsFloats = true
        formatter.numberStyle = .decimal

        self.txtScaling.formatter = NumberValueFormatter()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func gcodeUpdated( _ notification : NSNotification ) {
        
        guard let url = notification.userInfo?["url"] as? URL else { return }
        
        do {
            let str = try String(contentsOf: url)
            let lines = str.components(separatedBy: "\n")
            gcodeFile = GCodeFile(lines: lines)
            let stringRepresentation = gcodeFile!.writeGCode(scale: 1.0)
            
            txtGCode.string = stringRepresentation
            
            gcodeView.gcodeFile = gcodeFile!
            gcodeView.setNeedsDisplay(gcodeView.bounds)
            
            self.txtScaling.stringValue = "1.0"
        } catch let err {
            Swift.print( "Error loading file - \(err)")
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
        gcodeView.resetProgress()
        self.txtConsole.string = ""
        /*
        if let text = self.txtGCode.string {
            streaming = true
            gcode = text.components(separatedBy: "\n")
        }
        */
        streaming = true
        currentLineNr = 0
        sendGCode()
    }
    
    @IBAction func stopPressed(_ sender: AnyObject) {
        raisePenPressed(self)
        streaming = false

        gcodeView.resetProgress()
    }
    
    @IBAction func clearConsolePressed(_ sender: AnyObject) {
        self.txtConsole.string = ""
    }
    
    @IBAction func upPressed(_ sender: AnyObject) {
        serialHandler.send( "G01 Y\(yMax)\nM18\n")
    }
    
    @IBAction func downPressed(_ sender: AnyObject) {
        serialHandler.send( "G01 Y\(yMin)\nM18\n")
    }
    
    @IBAction func leftPressed(_ sender: AnyObject) {
        serialHandler.send( "G01 X\(xMin)\nM18\n")
    }
    
    @IBAction func rightPressed(_ sender: AnyObject) {
        serialHandler.send( "G01 X\(xMax)\nM18\n")
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
    
    @IBAction func refreshVisualisationPressed(_ sender: AnyObject) {
        gcodeView.resetProgress()

        // Update gcode with changes.
        guard let str = txtGCode.string else { return }
        let lines = str.components(separatedBy: "\n")
        gcodeFile = GCodeFile(lines: lines)
        let stringRepresentation = gcodeFile!.writeGCode(scale: scale)
        
        txtGCode.string = stringRepresentation
        
        gcodeView.gcodeFile = gcodeFile!
        gcodeView.setNeedsDisplay(gcodeView.bounds)
    }
    
    var currentLineNr = 0
    func sendGCode() {
        if !streaming
        {
            return
        }
        
        guard let gcode = gcodeFile else { return }
        
        if currentLineNr >= gcode.items.count {
            if streaming {
                streaming = false
                // turn off motors
                serialHandler.send("M18 (Turn off motors)\n")
            }
            return
        }
        
        // Pop first line from the list and send it
        var line = ""
        while line == "" && currentLineNr < gcode.items.count {
            line = gcode.items[currentLineNr].writeGCode(scale: scale).trimmingCharacters(in: .whitespacesAndNewlines)
            currentLineNr += 1
        }

        if line != "" {
            line += "\n"
            
//            print( "Sending \(line)")
            serialHandler.send(line)
            gcodeView.showProgress(gcodeLine: gcode.items[currentLineNr])
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
                    txtConsole.append(string: currentLine)
                    
                    if currentLine == "ok\n" {
                        sendGCode()
                    } else {
                        if currentLine.hasPrefix(("ok") ) {
                        }
                    }
                    currentLine = ""
                }
            }
        }
    }
    
    
    override func controlTextDidChange(_ notification: Notification) {

        guard let gcodeFile = gcodeFile else { return }
        
        if let textField = notification.object as? NSTextField,
            let formatter = textField.formatter as? NumberFormatter,
            let field_editor = textField.currentEditor() {
                if let val: Float = formatter.number(from: field_editor.string!)?.floatValue {
                    scale = val
                    
                    let stringRepresentation = gcodeFile.writeGCode(scale: scale)
                    txtGCode.string = stringRepresentation

                    gcodeView.scale = scale
                    gcodeView.setNeedsDisplay(gcodeView.bounds)
                }
        }


    }
}


@available(OSX 10.12.2, *)
extension ViewController: NSTouchBarDelegate {
    override func makeTouchBar() -> NSTouchBar? {
        // 1
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        // 2
        touchBar.customizationIdentifier = .travelBar
        // 3
        touchBar.defaultItemIdentifiers = [.infoLabelItem]
        // 4
        touchBar.customizationAllowedItemIdentifiers = [.infoLabelItem]
        return touchBar
    }
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItemIdentifier) -> NSTouchBarItem? {
        switch identifier {
        case NSTouchBarItemIdentifier.infoLabelItem:
            let customViewItem = NSCustomTouchBarItem(identifier: identifier)
            customViewItem.view = NSTextField(labelWithString: "Connect")
            return customViewItem
        default:
            return nil
        }
    }
}
