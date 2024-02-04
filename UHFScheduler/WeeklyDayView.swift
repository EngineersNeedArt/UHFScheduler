//
//  WeeklyDayView.swift
//  UHFScheduler
//

import Cocoa


protocol ListProgramSelectedDelegate: AnyObject {
	func listProgramSelected (_ dayView: WeeklyDayView, selected: ChannelViewController.ListProgramType?)
}


class WeeklyDayView: NSView {
	
	let colorsArray = [#colorLiteral(red: 1, green: 0.845275711, blue: 0.845275711, alpha: 1), #colorLiteral(red: 1, green: 0.925, blue: 0.85, alpha: 1), #colorLiteral(red: 1, green: 1, blue: 0.85, alpha: 1), #colorLiteral(red: 0.925, green: 1, blue: 0.85, alpha: 1), #colorLiteral(red: 0.85, green: 1, blue: 0.85, alpha: 1), #colorLiteral(red: 0.85, green: 1, blue: 0.925, alpha: 1), #colorLiteral(red: 0.85, green: 1, blue: 1, alpha: 1), #colorLiteral(red: 0.85, green: 0.925, blue: 1, alpha: 1), #colorLiteral(red: 0.85, green: 0.85, blue: 1, alpha: 1), #colorLiteral(red: 0.925, green: 0.85, blue: 1, alpha: 1), #colorLiteral(red: 1, green: 0.85, blue: 1, alpha: 1), #colorLiteral(red: 1, green: 0.85, blue: 0.925, alpha: 1)]
	let hourStrokeColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
	let halfHourStrokeColor = #colorLiteral(red: 0.9210989475, green: 0.9210989475, blue: 0.9210989475, alpha: 1)
	let noonStrokeColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
	let bobdStrokeColor = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1)
	
	var listSchedule: ChannelViewController.ListScheduleType? = nil
	var weekdayOrdinal: Int = 0
	var selected: ChannelViewController.ListProgramType? = nil
	var bobd: String? = nil
	var fillColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
	var programRects: [CGRect] = []
	var dropRect: CGRect? = nil
	weak var delegate: ListProgramSelectedDelegate?
	
	
	func setListSchedule (_ listSchedule: ChannelViewController.ListScheduleType?) {
		self.listSchedule = listSchedule
	}
	
	func setWeekdayOrdinal (_ ordinal: Int) {
		self.weekdayOrdinal = ordinal
	}
	
	func setSelectedProgram (_ selected: ChannelViewController.ListProgramType?) {
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
					if let listSchedule = self.listSchedule {
						let programArray = listSchedule.schedule
						delegate?.listProgramSelected (self, selected: programArray[index])
					}
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
		
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "HH:mm"
		if let listSchedule = self.listSchedule {
			let programArray = listSchedule.schedule
			var previousListProgram: ChannelViewController.ListProgramType? = nil
			var topFraction: CGFloat = -1.0
			var wasHours = 0
			var wasMinutes = 0
			for oneListProgram in programArray {
				if let startTime = dateFormatter.date (from: oneListProgram.start_time) {
					let hours = Calendar.current.component (.hour, from: startTime)
					let minutes = Calendar.current.component (.minute, from: startTime)
					let startMinutes = (CGFloat (hours) * 60.0) + CGFloat (minutes)
					let startFraction = startMinutes / (24.0 * 60.0)
					if oneListProgram.end_time != nil {
						print ("end_time")
						previousListProgram = nil
					} else {
						if previousListProgram != nil {
							let bottomFraction = startFraction
							let rect = CGRect (x: 0, y: bounds.size.height - (bottomFraction * bounds.size.height),
									width: bounds.size.width, height: (bottomFraction - topFraction) * bounds.size.height)
							self.programRects.append (rect)
							
							let colorIndex = ((wasHours * 1) + (wasMinutes / 60)) % 12
							var fillColor = self.colorsArray[colorIndex]
							if let selectedProgam = self.selected, let thisProgram = previousListProgram,
									selectedProgam.start_time == thisProgram.start_time {
								fillColor = NSColor.black
							}
							context.setFillColor (fillColor.cgColor)
							context.setBlendMode (.multiply)
							context.fill (rect)
							context.setBlendMode (.normal)
							context.setStrokeColor (NSColor.black.cgColor)
							context.setLineWidth (1)
							context.stroke (rect)
						}
						topFraction = startFraction
						previousListProgram = oneListProgram
						wasHours = hours
						wasMinutes = minutes
					}
				}
			}
			
			if previousListProgram != nil {
				let bottomFraction = 1.0
				let rect = CGRect (x: 0, y: bounds.size.height - (bottomFraction * bounds.size.height),
						width: bounds.size.width, height: (bottomFraction - topFraction) * bounds.size.height)
				self.programRects.append (rect)
				
				let colorIndex = ((wasHours * 2) + (wasMinutes / 30)) % 12
				var fillColor = self.colorsArray[colorIndex]
				if let selectedProgam = self.selected, let thisProgram = previousListProgram,
						selectedProgam.start_time == thisProgram.start_time {
					fillColor = NSColor.black
				}
				context.setBlendMode (.multiply)
				context.setFillColor (fillColor.cgColor)
				context.fill (rect)
				context.setBlendMode (.normal)
				context.setStrokeColor (NSColor.black.cgColor)
				context.setLineWidth (1)
				context.stroke (rect)
			}
		}
		
		if let unwrappedDropRect = self.dropRect {
			context.setStrokeColor (NSColor.red.cgColor)
			context.setLineWidth (2)
			context.stroke (unwrappedDropRect.insetBy(dx: 1, dy: 0))
		}
    }
}
