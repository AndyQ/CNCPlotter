# CNCPlotter

OSX Companion app for the Arduino Powered CNC Plotter - See https://github.com/AndyQ/CNCPlotter-Arduino

Basic app for sending GCode down to the CNC Plotter.

Instructions for use:
 - Open app
 - If CNC Plotter is connected to mac, it should pick the correct serial port and connect to it
   Otherwise, select the serial port you are using and click connect
 - Drag a gcode file onto the GCode text view (or if you are that way inclined, you can manually type commands in).
 - Make sure that you press the Auto-Home button first.  This will move the plotter to the bottom left and then back into the center.
 - Then, press Send GCode to send the GCode file to the plotter.
 
## Installation
 - Well, at this point in time you need to build this yourself so Xcode is required. (I'll try to get a developer signed build uploaded soon).
 - I'm, also using Cocoapods as a dependancy manager (for the serial library - ORSSerialPort (https://github.com/armadsen/ORSSerialPort) so you'll need that installed too.
 - Then, make sure you first do a pod install to bring down the dependancies.
 - Open the CNCPlotter.xcworkspace in Xcode (NOT the xcproject).
 - Build, run and have fun
 
**Disclaimer - this works nicely for my plotter (built from instructions from http://www.instructables.com/id/How-to-Make-Arduino-Based-Mini-CNC-Plotter-Using-D), however, it may not work on your plotter. You use this software entirely at your own risk.**
