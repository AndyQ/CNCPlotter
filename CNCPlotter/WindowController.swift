//
//  WindowController.swift
//  TouchBar
//
//  Created by Chris Ricker on 10/30/16.
//  Copyright © 2016 Ray Wenderlich. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {
  
  override func windowDidLoad() {
    super.windowDidLoad()
  }
  
/*
  @available(OSX 10.12.2, *)
  override func makeTouchBar() -> NSTouchBar? {
    guard let viewController = contentViewController as? ViewController else {
      return nil
    }
    return viewController.makeTouchBar()
  }
*/  
}
