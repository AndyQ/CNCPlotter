//
//  GCodeRenderingView.swift
//  CNCPlotter
//
//  Created by Andy Qua on 01/01/2017.
//  Copyright © 2017 Andy Qua. All rights reserved.
//

import Cocoa

class GCodeRenderingView: NSView  {
    var paths = [NSBezierPath]()
    var progressPaths = [NSBezierPath]()
    
    var gcodeFile : GCodeFile!
    
    var scale : Float = 1.0
    var plotSize = 40
    
    var xScale : CGFloat = 1
    var yScale : CGFloat = 1

    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if gcodeFile != nil {
            generatePaths()
        }

        NSColor.white.setFill()
        NSRectFill(dirtyRect);

        NSColor.black.set() // choose color
        for path in paths {
            path.stroke()
        }
        NSColor.red.set() // choose color
        for path in progressPaths {
            path.stroke()
        }
    }
    
    
    func generatePaths() {
        xScale = self.bounds.width / CGFloat(plotSize)
        yScale = self.bounds.height / CGFloat(plotSize)

        paths.removeAll()
        var drawing = false
        
        var currentPath = NSBezierPath()
        currentPath.lineWidth = 2
        paths.append(currentPath)
        

        var lineNr = 0
        for item in gcodeFile.items {
            lineNr += 1
            
            if item.isPenDown() {
                drawing = true
            } else if item.isPenUp() {
                drawing = false
                currentPath = NSBezierPath()
                currentPath.lineWidth = 2
                paths.append(currentPath)
            } else if item.isMove() {
                var (x,y) = item.getPosition()

                x *= CGFloat(scale)
                y *= CGFloat(scale)
                
                // Need to scale x and y to our view (in this app, x/y go between plotSize/2 (or 0-plotSize)
                x = (x + CGFloat(plotSize/2)) * xScale
                y = (y + CGFloat(plotSize/2)) * yScale
                
                // Drawing
                if !drawing {
                    currentPath.move(to: NSMakePoint(x, y)) // start point
                } else {
                    currentPath.line(to: NSMakePoint(x, y)) // destination
                }
            }
        }
    }
    
    
    func resetProgress() {
        self.progressPaths.removeAll()
        setNeedsDisplay(self.bounds)
    }
    
    var drawing = false
    var lastPoint : CGPoint?
    func showProgress( gcodeLine : GCodeItem ) {
        // Parse line
        if gcodeLine.isPenDown() {
            drawing = true
        } else if gcodeLine.isPenUp() {
            drawing = false
        } else if gcodeLine.isMove() {
            var (x,y) = gcodeLine.getPosition()
            
            x *= CGFloat(scale)
            y *= CGFloat(scale)
            
            // Need to scale x and y to our view (in this app, x/y go between plotSize/2 (or 0-plotSize)
            x = (x + CGFloat(plotSize/2)) * xScale
            y = (y + CGFloat(plotSize/2)) * yScale

            if let lp = lastPoint {
                if drawing {
                    let path = NSBezierPath()
                    path.lineWidth = 2
                    path.move(to: NSMakePoint(lp.x, lp.y)) // start point
                    path.line(to: NSMakePoint(x, y)) // destination
                    progressPaths.append(path)
                }
                lastPoint = CGPoint(x: x, y: y)
            } else {
                lastPoint = CGPoint(x: x, y: y)
            }
        }
        
        
        setNeedsDisplay(self.bounds)
    }
    
    func testData() -> [String] {
        let lines = [
            "(Scribbled version of /var/folders/34/c1zmvxyx6_58fy_cbfdwff980000gn/T/ink_ext_XXXXXX.svgUW59SY @ 3500.00)",
            "( unicorn.py --tab=\"plotter_setup\" --pen-up-angle=50 --pen-down-angle=30 --start-delay=150 --stop-delay=150 --xy-feedrate=3500 --z-feedrate=150 --z-height=0 --finished-height=0 --register-pen=true --x-home=0 --y-home=0 --num-copies=1 --continuous=false --pause-on-layer-change=false /var/folders/34/c1zmvxyx6_58fy_cbfdwff980000gn/T/ink_ext_XXXXXX.svgUW59SY )",
            "G21 (metric ftw)",
            "G90 (absolute mode)",
            "G92 X0.00 Y0.00 Z0.00 (you are here)",
            "",
            "M300 S30 (pen down)",
            "G4 P150 (wait 150ms)",
            "M300 S50 (pen up)",
            "G4 P150 (wait 150ms)",
            "M18 (disengage drives)",
            "M01 (Was registration test successful?)",
            "M17 (engage drives if YES, and continue)",
            "",
            "(Polyline consisting of 12 segments.)",
            "G1 X10.85 Y13.59 F3500.00",
            "M300 S30.00 (pen down)",
            "G4 P150 (wait 150ms)"]

        return lines
    }

}
