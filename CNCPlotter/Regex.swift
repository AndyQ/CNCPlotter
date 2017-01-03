//
//  Regex.swift
//  CNCPlotter
//
//  Created by Andy Qua on 01/01/2017.
//  Copyright © 2017 Andy Qua. All rights reserved.
//

import Cocoa

class Regex {
    let internalExpression: NSRegularExpression?
    let pattern: String
    
    init(_ pattern: String) {
        self.pattern = pattern

        do {
            self.internalExpression = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        } catch let err {
            print( "Error - \(err)")
            self.internalExpression = nil
        }
    }
    
    func replace( input: String, replacement : String ) -> String {
        guard let regex = self.internalExpression else { return input }
            
        return regex.stringByReplacingMatches(in: input, options: [], range: NSRange(location: 0, length: input.utf8.count), withTemplate: replacement)
    }
    
    func match( input: String ) -> [String] {
        guard let regex = self.internalExpression else { return [] }

        let matches =  regex.matches(in: input, options: [], range: NSRange(location: 0, length: input.utf8.count))
        
        let nsString = input as NSString
        return matches.map { nsString.substring(with: $0.range)}
    }
}
