//
//  WeeklyCollectionViewItem.swift
//  UHFScheduler
//
//  Created by John Calhoun on 8/25/22.
//

import Cocoa

class WeeklyCollectionViewItem: NSCollectionViewItem {
	
	@IBOutlet var dateTextField: NSTextField!
	
	@IBOutlet var dayTextField: NSTextField!
	
	@IBOutlet var containerView: WeeklyDayView!
	
	var listSchedule: ChannelViewController.ListScheduleType? = nil
	
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
	func setListSchedule (_ listSchedule: ChannelViewController.ListScheduleType?) {
		self.listSchedule = listSchedule
		
		self.containerView.setListSchedule(listSchedule)
		self.containerView.setNeedsDisplay (self.containerView.bounds)
	}
	
	func setSelectedProgram (_ selected: ChannelViewController.ListProgramType?) {
		self.containerView.setSelectedProgram (selected)
		self.containerView.setNeedsDisplay (self.containerView.bounds)
	}
	
	func setWeekdayOrdinal (_ ordinal: Int) {
		self.containerView.weekdayOrdinal = ordinal
	}
	
	func setBOBD (_ bobd: String?) {
		self.containerView.setBOBD (bobd)
		self.containerView.setNeedsDisplay (self.containerView.bounds)
	}
	
	func proposedProgramDrop (_ program: ChannelViewController.ResourceType, yLocation: CGFloat) -> String? {
		var dropTime: String? = nil
		if let localPoint = self.collectionView?.convert(CGPoint (x: 0, y: yLocation), to: self.containerView) {
			dropTime = self.containerView.proposedProgramDrop (program, yLocation: localPoint.y)
			self.containerView.setNeedsDisplay (self.containerView.bounds)
		}
		
		return dropTime
	}
	
	func clearProposedDrop () {
		self.containerView.clearProposedDrop ()
		self.containerView.setNeedsDisplay (self.containerView.bounds)
	}
}
