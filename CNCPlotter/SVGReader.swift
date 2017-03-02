//
//  SVGReader.swift
//  CNCPlotter
//
//  Created by Andy Qua on 12/01/2017.
//  Copyright © 2017 Andy Qua. All rights reserved.
//

import Cocoa

class Boundary {
    var segments = [Segment]()
}
class Layer {
    var segments = [Segment]()
}

class Segment {
    var points = [Point]()
}

class Point : CustomStringConvertible {
    var x : Float
    var y : Float
    var z : Float
    
    init( x : Float, y: Float, z: Float = 0) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    var description: String {
        return "x: \(x), y: \(y)"
    }

}

class SVGReader: NSObject {
    
    var grayscale = false
    
    var boundarys = [Boundary]()
    var z : Float? = nil
    var segment = -1
    var layer = 0
    var width :Float = 0
    var height :Float = 0
    var view_xmin : Float = 0
    var view_ymin  : Float = 0
    var view_width : Float = 0
    var view_height : Float = 0

    var nverts = 10
    
    func test() {
        if let url = Bundle.main.url(forResource: "tmp", withExtension: "svg") {
            readSVG( url:url)
        }
    }

//    var boundarys
    func readSVG(url : URL) {
        
        guard let str = try? String(contentsOf: url) else { return }
        let lines = str.components(separatedBy: "\n")

        boundarys.append( Boundary() )
        // check for use of grayscale in file
        for line in lines as [NSString] {
            if line.contains( "rgb(") {
                let intensity = handleRGBLine( line:line )
                if (intensity != 0) {
                    grayscale = true
                    break
                }
            }
        }

        for line in lines as [NSString] {
            let tokens = line.replacingOccurrences(of: "\"", with: "").components(separatedBy: " ")
            
            if line.contains( "<svg") {
                handleSVGLine(line:line, tokens:tokens)
            } else if line.contains( "<g ") {
                handleGLine(line:line, tokens:tokens)
            } else if line.contains( "<polyline ") {
                handlePolyLine(line:line, tokens:tokens)
            } else if line.contains( "<path ") {
                handlePathLine(line:line, tokens:tokens)
            }
        }
        
        // Set size
        xMin = Float.infinity
        xMax = -Float.infinity
        yMin = Float.infinity
        yMax = -Float.infinity
        
        if boundarys.count == 1 {
            // 2D file
            let boundary = boundarys[0]
            var sum = 0
            for segment in boundary.segments {
                sum += segment.points.count
            
                for point in segment.points {
                    let x = point.x
                    let y = point.y
                    if (x < xMin) {
                        xMin = x
                    }
                    if (x > xMax) {
                        xMax = x
                    }
                    if (y < yMin) {
                        yMin = y
                    }
                    if (y > yMax) {
                        yMax = y
                    }
                }
            }
            print( "   found \(boundary.segments.count) polygons - \(sum) vertices" )
            print( "   xmin: \(xMin), xmax \(xMax) dx: \(xMax-xMin)" )
            print( "   ymin: \(yMin), ymax \(yMax) dy: \(yMax-yMin)" )
        }
        
        autoscale()
    }
    
    //toolpaths, zmin, zmax
    var xyScale : Float = 1
    var xOff : Float = 0
    var yOff : Float = 0
    var xMin : Float = 0
    var xMax : Float = 0
    var yMin : Float = 0
    var yMax : Float = 0
    
    func autoscale() {
        // fit window
        xOff = -xMin*xyScale
        yOff = -yMin*xyScale
        if ((yMax-yMin) > (xMax-xMin)) {
            //xyScale = xyScale*(yMax-yMin)
        } else {
            //xyScale = xyScale*(xMax-xMin)
        }
    }
    
    func writeGCode() -> [String] {
        
        var text = [String]()
        text.append("G90G54") // absolute positioning with respect to set origin
        text.append("M300 S50") // move up before starting spindle

        var nsegment = 0
        for layer in 0 ..< boundarys.count { ///    ...range((len(boundarys)-1),-1,-1) {
            let path = boundarys[layer]

            for segment in 0 ..< path.segments.count{
                nsegment += 1
                var x = path.segments[segment].points[0].x*xyScale + xOff
                var y = path.segments[segment].points[0].y*xyScale + yOff
                text.append(String(format:"G00 X%0.4f Y%0.4f", x, y ))
                text.append("M300 S30\n") // move up before stopping spindle

                for vertex in 1 ..< path.segments[segment].points.count {
                    x = path.segments[segment].points[vertex].x*xyScale + xOff
                    y = path.segments[segment].points[vertex].y*xyScale + yOff
                    text.append(String(format:"G01 X%0.4f Y%0.4f", x, y ))
                }
                text.append("M300 S50\n") // move up before stopping spindle
            }
        }
        text.append("M300 S50\n") // move up before stopping spindle
        text.append("M05\n") // spindle stop
        print( "wrote \(nsegment) G code toolpath segments" )
        
        return text
    }
    
    
    func handleRGBLine( line : NSString ) -> Float {
        var start = line.range(of: "rgb(").location + 4
        var end = line.range(of: ",", options: [], range: NSMakeRange(start+1, line.length)).location
        let red = Float(line.substring( with: NSMakeRange( start, end)))!
        
        start = end + 1
        end = line.range(of: ",", options: [], range: NSMakeRange(start+1, line.length)).location
        let green = Float(line.substring( with: NSMakeRange( start, end)))!
        
        start = end + 1
        end = line.range(of: ",", options: [], range: NSMakeRange(start+1, line.length)).location
        let blue = Float(line.substring( with: NSMakeRange( start, end)))!
        
        let intensity = -(red + green + blue) / 3.0
        return intensity
    }
    
    func handleSVGLine( line: NSString, tokens : [String] ) {
        var viewBoxStr = ""
        for token in tokens {
            if token.hasPrefix( "width") {
                width = Float(strtod(token.components(separatedBy: "=")[1],nil))
            }
            if token.hasPrefix( "height") {
                height = Float(strtod(token.components(separatedBy: "=")[1],nil))
            }
            if token.hasPrefix( "viewBox") {
                viewBoxStr = token.components(separatedBy: "=")[1]
            }
        }
        
        view_xmin = 0
        view_ymin = 0
        view_width = width
        view_height = height
        if viewBoxStr != "" {
            var vbItems = viewBoxStr.components(separatedBy: ",")
            if vbItems.count == 4 {
                view_xmin = Float(strtod( vbItems[0], nil))
                view_ymin = Float(strtod( vbItems[1], nil))
                view_width = Float(strtod( vbItems[2], nil))
                view_height = Float(strtod( vbItems[3], nil))
            }
        }
    }
    
    func handleGLine( line: NSString, tokens : [String] ) {
        if line.contains( "rgb(" ) && grayscale == true {
            let intensity = handleRGBLine(line:line)
            if z != nil {
                layer += 1
                boundarys.append( Boundary() )
                segment = -1
                z = intensity
            }
        }
    }
    
    
    func handlePolyLine( line: NSString, tokens : [String] ) {
        
        for token in tokens {
            if token.hasPrefix("points=") {
                segment += 1
                boundarys[layer].segments.append(Segment())

                
                let points = token.components(separatedBy: "=")[1]
                let xy = points.components(separatedBy: " ")
                for point in xy {
                    let xy = point.components(separatedBy: ",")
                    var x = Float(strtod(xy[0],nil))
                    var  y = Float(strtod(xy[1],nil))
                    
                    x = width*(x - view_xmin)/view_width
                    y = height*(view_ymin-y)/view_height

                    let p = Point( x:x, y:y)
                    if grayscale && z != nil {
                    } else {
                        p.z = z!
                    }
                    boundarys[layer].segments[segment].points.append(p)
                }
                
            }
        }
    }
    
    func handlePathLine( line: NSString, tokens : [String] ) {
        segment += 1
        boundarys[layer].segments.append(Segment())
        
        var x0 : Float = 0
        var y0 : Float = 0
        for token in tokens {
            if token.hasPrefix("d=" ) {
                let points = token.components(separatedBy: "=")[1]

                var pos = 0
                while pos < points.length {
                    let c = points[pos]
                    pos += 1
                    if c == "M" || c == "L" {
                        (x0,pos) = getNextValue( line:points, pos:pos )
                        (y0,pos) = getNextValue( line:points, pos:pos )
                        
                        x0 = width*(x0 - view_xmin)/view_width
                        y0 = height*(view_ymin-y0)/view_height

                        let p = Point( x:x0, y:y0)
                        boundarys[layer].segments[segment].points.append(p)
                    } else if c == "C" {
                        var (x1,newPos) = getNextValue( line:points, pos:pos )
                        var (y1,newPos2) = getNextValue( line:points, pos:newPos )
                        var (x2,newPos3) = getNextValue( line:points, pos:newPos2 )
                        var (y2,newPos4) = getNextValue( line:points, pos:newPos3 )
                        var (x3,newPos5) = getNextValue( line:points, pos:newPos4 )
                        var (y3,newPos6) = getNextValue( line:points, pos:newPos5 )
                        pos = newPos6
                        
                        x1 = width*(x1 - view_xmin)/view_width
                        y1 = height*(view_ymin-y1)/view_height
                        x2 = width*(x2 - view_xmin)/view_width
                        y2 = height*(view_ymin-y2)/view_height
                        x3 = width*(x3 - view_xmin)/view_width
                        y3 = height*(view_ymin-y3)/view_height

                        for i in 0 ..< nverts {
                            let u : Float = Float(i)/(Float(nverts)-1.0)
                            
                            let x = (powf(1-u, 3) * x0) + (3*u*powf((1-u), 2) * x1)  + (3*powf(u, 2)*(1-u) * x2) + (powf(u, 3) * x3)
                            let y = (powf(1-u, 3) * y0) + (3*u*powf((1-u), 2) * y1)  + (3*powf(u, 2)*(1-u) * y2) + (powf(u, 3) * y3)

                            let p = Point( x:x, y:y)
                            boundarys[layer].segments[segment].points.append(p)
                        }
                        x0 = x3
                        y0 = y3

                    }
                }
            }
        }
    }
    
    func getNextValue( line : String, pos : Int ) -> (Float,Int) {
        let digits = ["0","1","2","3","4","5","6","7","8","9","."]
        let notdigits = ["M","C","L","Z","\""]
        let white = [" ","+",","]
        var string = ""
        var currPos = pos
        while currPos < line.length {
            let c = line[currPos]
            if white.contains(c) {
                currPos += 1
            } else {
                break
            }
        }
        while currPos < line.length {
            let c = line[currPos]
            if digits.contains(c) {
                string += c
                currPos += 1
            } else {
                break
            }
        }
        return (Float(strtod(string,nil)),currPos)
    }
/*
        ptr = 3+find(str[line],"d="")
            while 1 {
            char = str[line][ptr]
            if (char == "M") {
            ptr += 1
            (x0,ptr) = path_get_next(ptr)
            (y0,ptr) = path_get_next(ptr)
            x0 = width*(x0 - view_xmin)/view_width
            y0 = height*(view_ymin-y0)/view_height
            boundarys[layer][segment].append([x0,y0,[]])
            } elif (char == "L") {
            ptr += 1
            (x1,ptr) = path_get_next(ptr)
            (y1,ptr) = path_get_next(ptr)
            x1 = width*(x1 - view_xmin)/view_width
            y1 = height*(view_ymin-y1)/view_height
            boundarys[layer][segment].append([x1,y1,[]])
            } elif (char == "C") {
            ptr += 1
            (x1,ptr) = path_get_next(ptr)
            (y1,ptr) = path_get_next(ptr)
            x1 = width*(x1 - view_xmin)/view_width
            y1 = height*(view_ymin-y1)/view_height
            (x2,ptr) = path_get_next(ptr)
            (y2,ptr) = path_get_next(ptr)
            x2 = width*(x2 - view_xmin)/view_width
            y2 = height*(view_ymin-y2)/view_height
            (x3,ptr) = path_get_next(ptr)
            (y3,ptr) = path_get_next(ptr)
            x3 = width*(x3 - view_xmin)/view_width
            y3 = height*(view_ymin-y3)/view_height
            for i in range(nverts) {
            u = i/(nverts-1.0)
            x = ((1-u)**3 * x0) + (3*u*(1-u)**2 * x1) \
            + (3*u**2*(1-u) * x2) + (u**3 * x3)
            y = ((1-u)**3 * y0) + (3*u*(1-u)**2 * y1) \
            + (3*u**2*(1-u) * y2) + (u**3 * y3)
            boundarys[layer][segment].append([x,y,[]])
            }
            x0 = x3
            y0 = y3
            } elif (char == """) {
        break
        } else {
            ptr += 1
        }
    }
                 
*/
    
}
