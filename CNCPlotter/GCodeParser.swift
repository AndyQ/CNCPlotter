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
    
    var children = [String:Float]()
    
    init( elements : [String] ) {
        var i = 0
        
        self.elements = elements
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
        var ret = "\(type)\(value)"

        for (key, var val) in children {
            if "XYZ".contains(key) {
                val *= scale
            }
            ret += " \(key)\(val)"
        }

        return ret
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

    init( lines : [String] ) {
        parseGCode( lines: lines )
    }
    
    func parseGCode( lines : [String] ) {
        for line in lines {
            parseGCodeLine(line:line)
        }
    }
    
    func parseGCodeLine( line : String )  {
        var ret = stripComments( line:line )
        ret = removeSpaces( line:ret ).uppercased()
        
        let elements = re4.match(input: ret)
        if elements.count > 0 {
            let gcodeItem = GCodeItem(elements:elements)
            items.append(gcodeItem)
        }
    }
    

    func removeSpaces( line: String ) -> String {
        let s = re3.replace(input: line, replacement: "")
        return s

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
