//
//  GCodeParser.swift
//  CNCPlotter
//
//  Created by Andy Qua on 01/01/2017.
//  Copyright © 2017 Andy Qua. All rights reserved.
//

import Cocoa

class GCodeItem : CustomStringConvertible {
    var type : String = ""
    var value : Int = 0
    var elements : [String]
    var comments : String = ""
    
    var children = [String:Float]()
    
    init( elements : [String], comments : String ) {
        var i = 0
        
        self.elements = elements
        self.comments = comments
        for element in elements {
            var cmd = element.substring(to: 1)
            var val : Float = 0
            if cmd == "(" {
                cmd = element
            } else {
                val = Float(element.substring(from: 1))!
            }

            if i == 0 {
                self.type = cmd
                self.value = Int(val)
            } else {
                children[cmd] = val
            }
            i += 1
        }
    }
    
    func writeGCode( scale : Float ) -> String {
        
        var ret = ""
        if type != "" {
            ret = "\(type)\(value)"
        }

        for (key, var val) in children {
            if "XYZ".contains(key) {
                val *= scale
            }
            ret += " \(key)\(val)"
        }

        ret += comments
        
        return ret
    }
    
    func isPenUp() -> Bool {
        var ret = false
        if type == "M" && (value == 300 ) {
            if let val = children["S"],
                val == 50 || val == 90 {
                
                ret = true
            }
        }
        if type == "M" && (value == 190 ) {
            ret = true
        }
        
        return ret
    }
    
    func isPenDown() -> Bool {
        var ret = false
        if type == "M" && (value == 300 || value == 1) {
            if let val = children["S"],
                val == 30 || val == 130 {
                
                ret = true
            }
        }
        
        if type == "M" && (value == 1130 ) {
            ret = true
        }

        return ret
    }
    
    func isMove() -> Bool {
        return type == "G" && (value == 0 || value == 1)
    }
    
    func getPosition() -> (CGFloat,CGFloat) {
        if !isMove() {
            return (0,0)
        }
        var x :CGFloat = 0
        var y :CGFloat = 0
        
        // Now grab out the X and Y coords
        if let xVal = children["X"],
            let yVal = children["Y"] {
            
            x = CGFloat(xVal)
            y = CGFloat(yVal)
        }

        return (x,y)
    }
    
    var description: String {
        return writeGCode(scale:1.0)
    }
}

class GCodeFile : CustomStringConvertible {
    let re1 = Regex("\\s*[%#;].*")
    let re2 = Regex("\\s*\\(.*\\).*")
    let re3 = Regex("\\s+")
    let re4 = Regex("([a-zA-Z][0-9\\+\\-\\.]*)|(\\*[0-9]+)")
//    let re4 = Regex("([a-zA-Z][0-9\\+\\-\\.]*)|(\\*[0-9]+)*(\\(.*\\))")

    var items = [GCodeItem]()
    
    init() {
    }

    init( lines : [String] ) {
        parseGCode( lines: lines )
    }
    
    func parseGCode( lines : [String] ) {
        for line in lines {
            let gcodeItem = parseGCodeLine(line:line)
            items.append(gcodeItem)
        }
    }
    
    func parseGCodeLine( line : String ) -> GCodeItem  {
        
        // First, take a copy of the comments
        let commentItems = getComments( line:line )
        let comments = commentItems.count > 0 ? commentItems[0] : ""
        
        var ret = stripComments( line:line )
        ret = removeSpaces( line:ret ).uppercased()
        
        let elements = re4.match(input: ret)
        let gcodeItem = GCodeItem(elements:elements, comments:comments)
        return gcodeItem
    }
    

    func removeSpaces( line: String ) -> String {
        let s = re3.replace(input: line, replacement: "")
        return s

    }
    func getComments( line : String ) -> [String] {
        let c1 = re1.match(input: line)
        let c2 = re2.match(input: line)
        var ret = [String]()
        if c1.count > 0 {
            ret.append(contentsOf:c1)
        }
        if c2.count > 0 {
            ret.append(contentsOf:c2)
        }
        return ret
    }
    
    func stripComments( line : String ) -> String {
        
        let s = re1.replace(input: line, replacement: "")
        let s2 = re2.replace(input: s, replacement: "")
        
        return s2
    }
    
    func writeGCode( scale : Float ) -> String {
        var ret = ""
        for item in self.items {
            ret += "\(item.writeGCode(scale: scale))\n"
        }
        return ret
    }
    
    var description: String {
        return writeGCode(scale:1.0)
    }

}
