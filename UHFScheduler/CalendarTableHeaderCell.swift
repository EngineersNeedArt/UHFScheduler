//
//  CalendarTableHeaderCell.swift
//  UHFScheduler
//
//  Created by John Calhoun on 8/27/22.
//


import Cocoa


class CalendarTableHeaderCell: NSTableHeaderCell {
	
	var cellBackgroundColor: NSColor = NSColor.red
	
	var index: Int = 0
	
	override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
		cellBackgroundColor.set ()
		let rect = NSRect(x: cellFrame.origin.x, y: cellFrame.origin.y - 3,
				width: cellFrame.size.width - 2, height: cellFrame.size.height + 10)
		NSBezierPath (rect: rect).fill()
		
//		let str = NSAttributedString(string: stringValue, attributes:
//			[NSAttributedString.Key.foregroundColor: NSColor.red,
//			 NSAttributedString.Key.font: NSFont(name: "Skia", size: 14)])
//
//		str.draw(in: cellFrame)
		
		super.drawInterior (withFrame: cellFrame, in: controlView)
	}
	
//	override func draw (withFrame cellFrame: NSRect, in controlView: NSView) {
//		super.draw (withFrame: cellFrame, in: controlView)
//		
//		controlView.layer?.backgroundColor = self.cellBackgroundColor.cgColor
//	}
}
