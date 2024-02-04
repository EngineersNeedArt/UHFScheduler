//
//  WeeklyCollectionView.swift
//  UHFScheduler
//
//  Created by John Calhoun on 8/25/22.
//

import Cocoa

class WeeklyCollectionView: NSCollectionView {
	
	override func setFrameSize (_ newSize: NSSize) {
		let size = collectionViewLayout?.collectionViewContentSize ?? newSize
		super.setFrameSize (size)
	}
	
	override func becomeFirstResponder () -> Bool {
		return true
	}
	
	override func resignFirstResponder() -> Bool {
		return true
	}
	
}
