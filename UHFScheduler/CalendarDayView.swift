//
//  CalendarDayView.swift
//  UHFScheduler
//
//  Created by John Calhoun on 8/26/22.
//

import Cocoa


protocol ProgramSelectedDelegate: AnyObject {
	func programSelected (_ dayView: CalendarDayView, selected: ChannelViewController.ScheduleDayType)
}


class CalendarDayView: NSView {
	
	let colorsArray = [#colorLiteral(red: 1, green: 0.845275711, blue: 0.845275711, alpha: 1), #colorLiteral(red: 1, green: 0.925, blue: 0.85, alpha: 1), #colorLiteral(red: 1, green: 1, blue: 0.85, alpha: 1), #colorLiteral(red: 0.925, green: 1, blue: 0.85, alpha: 1), #colorLiteral(red: 0.85, green: 1, blue: 0.85, alpha: 1), #colorLiteral(red: 0.85, green: 1, blue: 0.925, alpha: 1), #colorLiteral(red: 0.85, green: 1, blue: 1, alpha: 1), #colorLiteral(red: 0.85, green: 0.925, blue: 1, alpha: 1), #colorLiteral(red: 0.85, green: 0.85, blue: 1, alpha: 1), #colorLiteral(red: 0.925, green: 0.85, blue: 1, alpha: 1), #colorLiteral(red: 1, green: 0.85, blue: 1, alpha: 1), #colorLiteral(red: 1, green: 0.85, blue: 0.925, alpha: 1)]
	let hourStrokeColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
	let halfHourStrokeColor = #colorLiteral(red: 0.9210989475, green: 0.9210989475, blue: 0.9210989475, alpha: 1)
	let noonStrokeColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
	let bobdStrokeColor = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1)
	
	var schedule: [ChannelViewController.ScheduleDayType] = []
	var selected: ChannelViewController.ScheduleDayType? = nil
	var bobd: String? = nil
	var fillColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
	var programRects: [CGRect] = []
	var dropRect: CGRect? = nil
	weak var delegate: ProgramSelectedDelegate?
	
	
	func setSchedule (_ schedule: [ChannelViewController.ScheduleDayType]) {
		self.schedule = schedule
	}
	
	func setSelectedProgram (_ selected: ChannelViewController.ScheduleDayType?) {
		self.selected = selected
		self.setNeedsDisplay (self.bounds)
	}
	
	func setBOBD (_ bobd: String?) {
		self.bobd = bobd
	}
	
	func proposedProgramDrop (_ program: ChannelViewController.ResourceType, yLocation: CGFloat) -> String? {
		let bounds = self.bounds
		let quarterHour = bounds.size.height / 72.0
		let fraction = min (max ((yLocation + quarterHour) / bounds.size.height, 0), 1.0)
		let nearestHalfHour = floor (fraction * 48.0) / 48.0
		let height = (CGFloat (program.duration) / (60 * 60 * 24)) * bounds.size.height
		let top = (nearestHalfHour * bounds.size.height) - height
		self.dropRect = CGRect (x: 0, y: top, width: bounds.size.width, height: height)
		
		let hour = 24 - Int (floor ((fraction * 24.0) + 0.5))
		let minutes = ((48 - Int (nearestHalfHour * 48)) % 2) == 0 ? 0 : 30
		return String (format: "%02d:%02d", hour, minutes)
	}
	
	func clearProposedDrop () {
		self.dropRect = nil
	}
	
	override func mouseDown (with event: NSEvent) {
		super.mouseDown (with: event)
		
		if event.clickCount == 1 {
			let clickLocation = self.convert (event.locationInWindow, from: nil)
			for (index, oneRect) in self.programRects.enumerated () {
				if oneRect.contains (clickLocation) {
					delegate?.programSelected (self, selected: self.schedule[index])
					break
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
		
		// Fill cell background.
		context.setFillColor(self.fillColor.cgColor)
		context.fill (bounds)
		
		// Stroke lines on every half-hour.
		context.setLineWidth(1)
		let font = NSFont.systemFont(ofSize: 9)
		for i in 1...47 {
			let fraction = CGFloat(i) / 48.0
			let rect = CGRect (x: 0, y: bounds.size.height - (fraction * bounds.size.height), width: bounds.size.width, height: 0)
			context.setStrokeColor(i == 24 ? self.noonStrokeColor.cgColor : ((i % 2) != 0) ? self.halfHourStrokeColor.cgColor : self.hourStrokeColor.cgColor)
			context.stroke(rect)
			
			if (i % 2) == 0 {
				let timeString = String (format: "%d:00", (i + 1) / 2)
				let string = NSAttributedString (string: timeString, attributes: [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: i == 24 ? self.noonStrokeColor : self.hourStrokeColor])
				let labelSize = string.size()
				let stringBounds = CGRect (x: round ((bounds.size.width - labelSize.width) / 2),
						y: round ((bounds.size.height - (fraction * bounds.size.height)) - (labelSize.height / 2)),
						width: labelSize.width,
						height: labelSize.height)
				context.setFillColor (fillColor.cgColor)
				context.fill (stringBounds.insetBy (dx: -2, dy: -2))
				string.draw(at: CGPoint(x: stringBounds.origin.x, y: stringBounds.origin.y))
			}
		}
		
		let formatter = DateFormatter ()
		formatter.dateFormat = "HH:mm"
		if let unwrappedBOBD = self.bobd, let bobdDate = formatter.date (from: unwrappedBOBD) {
			let minutes = Calendar.current.component(.minute, from: bobdDate)
			let hours = Calendar.current.component(.hour, from: bobdDate)
			let fraction = (CGFloat (hours) + (CGFloat (minutes) / 60.0)) / 24.0
			let rect = CGRect (x: 0, y: bounds.size.height - round (fraction * bounds.size.height), width: bounds.size.width, height: 0)
			context.setStrokeColor (self.bobdStrokeColor.cgColor)
			context.stroke (rect)
		}
		
		for oneProgram in self.schedule {
			let dateFormatter = DateFormatter()
			dateFormatter.dateFormat = "HH:mm"
			if let startTime = dateFormatter.date (from: oneProgram.start_time) {
				let hours = Calendar.current.component(.hour, from: startTime)
				let minutes = Calendar.current.component(.minute, from: startTime)
				let startMinutes = (CGFloat(hours) * 60.0) + CGFloat(minutes)
				let startFraction = startMinutes / (24.0 * 60.0)
				let durationMinutes = CGFloat (max (oneProgram.duration, 600)) / 60.0
				let endMinutes = startMinutes + durationMinutes
				let endFraction = endMinutes / (24.0 * 60.0)
				
				let rect = CGRect (x: 0, y: bounds.size.height - (endFraction * bounds.size.height),
						width: bounds.size.width, height: (endFraction - startFraction) * bounds.size.height)
				self.programRects.append (rect)
	
				let colorIndex = ((hours * 2) + (minutes / 30)) % 12
				var fillColor = colorsArray[colorIndex]
				var textColor = oneProgram.hasDescription ? NSColor.black : NSColor.blue
				if let selectedProgam = self.selected, selectedProgam.start_time == oneProgram.start_time {
					fillColor = NSColor.black
					textColor = NSColor.white
				}
				context.setFillColor (fillColor.cgColor)
				context.fill (rect)
				context.setStrokeColor (NSColor.black.cgColor)
				context.setLineWidth (1)
				context.stroke (rect)
				
				let title = oneProgram.title + " (" + oneProgram.start_time + ")"
				let string = NSAttributedString (string: title, attributes:
						[NSAttributedString.Key.font: font,
						NSAttributedString.Key.foregroundColor: textColor])
				string.draw (in: rect.insetBy (dx: 2, dy: 0))
				
				if oneProgram.error == true {
					let imageRect = NSRect (x: rect.maxX - 18, y: rect.minY + round ((rect.height - 14) / 2) + 0.5, width: 14, height: 14)
					_ = NSImage (named: "Warning")?.representations.first?.draw (in: imageRect)
				}
			}
		}
		
		if let unwrappedDropRect = self.dropRect {
			context.setStrokeColor (NSColor.red.cgColor)
			context.setLineWidth (2)
			context.stroke (unwrappedDropRect.insetBy(dx: 1, dy: 0))
		}
    }
	
}
