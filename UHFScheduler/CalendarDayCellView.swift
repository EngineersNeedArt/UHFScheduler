//
//  CalendarDayCellView.swift
//  UHFScheduler
//
//  Created by John Calhoun on 8/27/22.
//

import Cocoa


protocol ProgramSelectDelegate: AnyObject {
	func programSelected (_ dayView: CalendarDayCellView, resource: ChannelViewController.ResourceType)
}


class CalendarDayCellView: NSTableCellView {
	
	var schedule: [ChannelViewController.ScheduleDayType] = []
	var programRects: [CGRect] = []
	weak var delegate: ProgramSelectDelegate?
	
	
	func setSchedule (_ schedule: [ChannelViewController.ScheduleDayType]) {
		self.schedule = schedule
	}
	
	override func mouseDown(with event: NSEvent) {
		super.mouseDown(with: event)
		
		if event.clickCount == 1 {
			let clickLocation = self.convert(event.locationInWindow, from: nil)
			for (index, oneRect) in self.programRects.enumerated() {
				if oneRect.contains(clickLocation) {
					delegate?.programSelected (self, resource: self.schedule[index].resource)
				}
			}
		}
	}
	
	override func draw (_ dirtyRect: NSRect) {
		super.draw (dirtyRect)
		
		guard let context = NSGraphicsContext.current?.cgContext else {
			print("could not get graphics context")
			return
		}
		
		self.programRects.removeAll ()
		let bounds = self.bounds
		
		// Drawing code here.
		context.setLineWidth(1)
		for i in 1...47 {
			let fraction = CGFloat(i) / 48.0
			let rect = CGRect (x: 0, y: bounds.size.height - (fraction * bounds.size.height), width: bounds.size.width, height: 0)
			context.setStrokeColor(i == 24 ? NSColor.blue.cgColor : ((i % 2) != 0) ? NSColor.lightGray.cgColor : NSColor.darkGray.cgColor)
			context.stroke(rect)
		}
		
		for oneProgram in self.schedule {
			let dateFormatter = DateFormatter()
			dateFormatter.dateFormat = "HH:mm"
			if let startTime = dateFormatter.date (from: oneProgram.start_time) {
				let hours = Calendar.current.component(.hour, from: startTime)
				let minutes = Calendar.current.component(.minute, from: startTime)
				let startMinutes = (CGFloat(hours) * 60.0) + CGFloat(minutes)
				let startFraction = startMinutes / (24.0 * 60.0)
				let durationMinutes = CGFloat(oneProgram.resource.duration ?? 0) / 60.0
				let endMinutes = startMinutes + durationMinutes
				let endFraction = endMinutes / (24.0 * 60.0)
				
				let rect = CGRect (x: 0, y: bounds.size.height - (endFraction * bounds.size.height),
						width: bounds.size.width, height: (endFraction - startFraction) * bounds.size.height)
				self.programRects.append (rect)
				context.setFillColor(NSColor.cyan.cgColor)
				context.fill(rect)
				context.setStrokeColor(NSColor.black.cgColor)
				context.setLineWidth(1)
				context.stroke(rect)
			}
		}
	}
}
