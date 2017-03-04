//
//  SerialHandler.swift
//  CNCPlotter
//  Created by Andy Qua on 22/10/2016.
//  Copyright © 2016 Andy Qua. All rights reserved.
//

import Cocoa
import CoreFoundation

import IOKit
import IOKit.serial

class SerialHandler : NSObject, ORSSerialPortDelegate {
    let standardInputFileHandle = FileHandle.standardInput
    var serialPort: ORSSerialPort?
    
    var portOpenCallback : (()->())?
    var portCloseCallback : (()->())?
    var readPrintDataCallback : ((Data)->())?
    
    var isOpen = false
    
    var testMode = false
    var testStopped = true
    var testPaused = true
    
    func getUSBSerialDevices() -> [String] {
        var portIterator: io_iterator_t = 0
        let kernResult = findSerialDevices(deviceType: kIOSerialBSDAllTypes, serialPortIterator: &portIterator)
        if kernResult == KERN_SUCCESS {
            
            return getSerialPaths(portIterator: portIterator)
        }
        
        return []
    }
    
    func findSerialDevices(deviceType: String,  serialPortIterator: inout io_iterator_t ) -> kern_return_t {
        var result: kern_return_t = KERN_FAILURE
        let classesToMatch = IOServiceMatching(kIOSerialBSDServiceValue)
        if var classesToMatchDict = (classesToMatch!) as NSDictionary as? [String: Any] {
            classesToMatchDict[kIOSerialBSDTypeKey] = deviceType
            let classesToMatchCFDictRef = (classesToMatchDict as NSDictionary) as CFDictionary
            result = IOServiceGetMatchingServices(kIOMasterPortDefault, classesToMatchCFDictRef, &serialPortIterator);
            return result
        }
        
        return KERN_FAILURE
    }
    
    func getSerialPaths(portIterator: io_iterator_t) -> [String] {
        var devices = [String]()
        
        var serialService: io_object_t
        repeat {
            serialService = IOIteratorNext(portIterator)
            if (serialService != 0) {
                let key: CFString! = "IOCalloutDevice" as NSString
                let bsdPathAsCFtring: AnyObject? =
                    IORegistryEntryCreateCFProperty(serialService, key, kCFAllocatorDefault, 0).takeUnretainedValue()
                if let path = bsdPathAsCFtring as? String {
                    devices.append(path)
                }
            }
        } while serialService != 0;
        
        return devices
    }
    
    func open( device : String ) {
        
        if testMode {
            serialPort = ORSSerialPort(path:"")
            isOpen = true
        } else {
            self.serialPort = ORSSerialPort(path: device) // please adjust to your handle
            self.serialPort?.delegate = self
            self.serialPort?.baudRate = 9600
//            self.serialPort?.baudRate = 115200
            self.serialPort?.rts = true
            self.serialPort?.dtr = true
            serialPort?.open()
        }
    }
    
    func close() {
        isOpen = false
        serialPort?.close()
    }
    
    func send(_ command: String, data : Any? = nil) {
        if !testMode {
            if let data = command.data(using: .utf8) {
                self.serialPort?.send(data)
            }
        } else {
            DispatchQueue.main.async{ [weak self] in
                if let data = "ok\n".data(using: .utf8) {
                    self?.readPrintDataCallback?(data)
                }
            }
        }

    }
    
    func sendData( data : Data) {
        if !testMode {
            self.serialPort?.send(data)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { [weak self] in
                if let data = "ok\n".data(using: .utf8) {
                    self?.readPrintDataCallback?(data)
                }
            })
        }
    }
    
    // ORSSerialPortDelegate
    
    func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
        readPrintDataCallback?( data )
    }
    
    func serialPortWasRemoved(fromSystem serialPort: ORSSerialPort) {
        self.serialPort = nil
        portCloseCallback?()
        print("Serial port (\(serialPort)) was removed")
    }
    
    func serialPortWasClosed(_ serialPort: ORSSerialPort) {
        self.serialPort = nil
        portCloseCallback?()
        print("Serial port (\(serialPort)) was closed")
    }
    
    func serialPort(_ serialPort: ORSSerialPort, didEncounterError error: Error) {
        print("Serial port (\(serialPort)) encountered error: \(error)")
        self.serialPort?.close()
        portCloseCallback?()
    }
    
    func serialPortWasOpened(_ serialPort: ORSSerialPort) {
        print("Serial port \(serialPort) was opened")
        portOpenCallback?()
        
        isOpen = true
    }
    
    
/*
    func testModeDataSender() {
        let dm = DataManager.instance
        
        // Simulate sending data from the serial port
        if let pixels = dm.pixels {
            var i = 0
            for r in 0 ..< dm.imageSize {
                for c in 0 ..< dm.imageSize {
                    if pixels[i] == .on {
                        let bytes :[UInt8] = [0xff, UInt8(c/100), UInt8(c%100), UInt8(r/100), UInt8(r%100)]
                        let data = Data(bytes:bytes)
                        DispatchQueue.main.async { [weak self] in
                            self?.readPrintDataCallback?( data)
                        }
                        usleep(1000)
                    }
                    
                    i += 1
                    
                    while testPaused {
                        usleep(1000)
                    }
                    
                    if testStopped {
                        break
                    }
                }
                
                if testStopped {
                    break
                }
            }
        }
    }
 */
}
