//
//  AppDelegate.swift
//

import Cocoa


@main
class AppDelegate: NSObject, NSApplicationDelegate {
	
	@IBOutlet var window: NSWindow!
	
	func applicationDidFinishLaunching (_ aNotification: Notification) {
		window.contentViewController = ChannelViewController ()
		window.contentView = window.contentViewController?.view
	}
	
	func applicationWillTerminate (_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
	
	func applicationSupportsSecureRestorableState (_ app: NSApplication) -> Bool {
		return true
	}
}
