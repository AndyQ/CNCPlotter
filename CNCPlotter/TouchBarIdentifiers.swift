//
//  TouchBarIdentifiers.swift
//  TouchBar
//
//  Created by Andy Pereira on 10/31/16.
//  Copyright © 2016 Ray Wenderlich. All rights reserved.
//

import AppKit

extension NSTouchBarItemIdentifier {
  static let infoLabelItem = NSTouchBarItemIdentifier("com.andyqua.InfoLabel")
  static let visitedLabelItem = NSTouchBarItemIdentifier("com.andyqua.VisitedLabel")
  static let visitSegmentedItem = NSTouchBarItemIdentifier("com.andyqua.VisitedSegementedItem")
  static let visitedItem = NSTouchBarItemIdentifier("com.andyqua.VisitedItem")
  static let ratingLabel = NSTouchBarItemIdentifier("com.andyqua.RatingLabel")
  static let ratingScrubber = NSTouchBarItemIdentifier("com.andyqua.RatingScrubber")
}

extension NSTouchBarCustomizationIdentifier {
  static let travelBar = NSTouchBarCustomizationIdentifier("com.andyqua.ViewController.TravelBar")
}
