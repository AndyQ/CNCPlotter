//
//  DraggableTextView.swift
//  //  CNCPlotter
//
//  Created by Andy Qua on 29/12/2016.
//  Copyright © 2016 Andy Qua. All rights reserved.
//

import Cocoa

let notif_newDataAvailable = NSNotification.Name("NOTIF_NewDataAvailable")

class DraggableTextView: NSTextView {
    
    var acceptableTypes: Set<String> { return [NSURLPboardType] }
    
    
    var isReceivingDrag = false {
        didSet {
            needsDisplay = true
        }
    }
    required init?(coder: NSCoder) {
        
        super.init(coder:coder)
        
        register(forDraggedTypes: Array(acceptableTypes))
    }
    
    
    func shouldAllowDrag(_ draggingInfo: NSDraggingInfo) -> Bool {
        
        var canAccept = false
        
        let pasteBoard = draggingInfo.draggingPasteboard()
        
        if pasteBoard.canReadObject(forClasses: [NSURL.self], options: [:] ) { //filteringOptions) {
            canAccept = true
        }
        return canAccept
        
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let allow = shouldAllowDrag(sender)
        isReceivingDrag = allow
        return allow ? .copy : NSDragOperation()
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        isReceivingDrag = false
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let allow = shouldAllowDrag(sender)
        return allow
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        isReceivingDrag = false
        let pasteBoard = sender.draggingPasteboard()
        
        if let urls = pasteBoard.readObjects(forClasses: [NSURL.self], options: [:]) as? [URL], urls.count > 0 {
            dump( "Found URLs - \(urls)")
            NotificationCenter.default.post(name: notif_newDataAvailable, object: nil, userInfo: ["url":urls[0]])

            return true
        }
        
        return false
    }
    


    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
