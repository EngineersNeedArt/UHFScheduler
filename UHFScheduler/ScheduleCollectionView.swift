//
//  ScheduleCollectionView.swift
//  UHFScheduler
//
//  Created by John Calhoun on 8/25/22.
//

import Cocoa

class ScheduleCollectionView: NSCollectionView {
	
	override func setFrameSize (_ newSize: NSSize) {
		let size = collectionViewLayout?.collectionViewContentSize ?? newSize
		super.setFrameSize(size)
		if let scrollView = enclosingScrollView {
			scrollView.hasHorizontalScroller = size.width > scrollView.frame.width
		}
	}
	
	override func validateProposedFirstResponder (_ responder: NSResponder, for event: NSEvent?) -> Bool {
		print ("validateProposedFirstResponder")
		return false
	}
	
	override func becomeFirstResponder () -> Bool {
		return true
	}
	
	override func resignFirstResponder() -> Bool {
		return true
	}
	
}
