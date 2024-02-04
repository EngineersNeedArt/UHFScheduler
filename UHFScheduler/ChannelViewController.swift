//
//  ChannelViewController.swift
//  UHFScheduler
//
//  Created by John Calhoun on 8/25/22.
//

import AVFoundation
import Cocoa
import CoreMedia
import UniformTypeIdentifiers


class ChannelViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate,
		NSMenuItemValidation, NSTabViewDelegate, NSTableViewDataSource, NSTableViewDelegate,
		NSTextFieldDelegate, ListProgramSelectedDelegate, ProgramSelectedDelegate {
	
	/// Used internally, it does not represent a JSON object from a file.
	public struct ScheduleDayType: Codable {
		var start_time: String						// ISO 8601 time format.
		var duration: Int							// duration in seconds.
		var title: String							// title to display.
		var day_ordinal: Int						// ordinal value representing the day in the schedule.
		var hasDescription: Bool					// True if the resource has a description.
		var error: Bool								// True if there are errors, e.g. path is broken.
	}
	
	public struct ResourceType: Codable {
		var path: String							// required relative path to file (relative to schedule JSON)
		var duration: Int							// required duration in seconds
		var title: String?							// optional title ("image" kind will not have a title)
		var series_id: String?						// optional identifier of series of "movie"
		var order: Int?								// optional order within series
		var description: String?					// optional description of "movie"
		var year: Int?								// optional year "movie" was released
		var start_offset: Int?						// optional offset in seconds to begin film
	}
	
	public struct ProgramType: Codable {
		var start_time: String						// required ISO 8601 time format
		var resource_id: String						// required resource identifier
		var category_id: String?					// optional category identifier
	}
	
	public struct ListInfoType: Codable {
		var title: String?							// optional name of the list
		var description: String?					// optional description of the list
	}
	
	public struct ListType: Codable {
		var version: String							// required, "UHF List - v1"
		var info: ListInfoType?						// optional info about the list
		var resources: [String:ResourceType]		// required dictionary of ResourceTypes, key is unique string
	}
	
	public struct ScheduleType: Codable {
		var version: String							// required, "UHF Schedule - v1"
		var resources: [String:ResourceType]		// required dictionary of ResourceTypes, key is unique string
		var days: [[ProgramType]]					// required array of array of ProgramType
	}
	
	public struct ScheduleDescriptorType: Codable {
		var start_date: String						// required ISO 8601 date format
		var schedule_path: String					// required relative path to schedule
	}
	
	public struct ChannelInfoType: Codable {
		var title: String?							// optional name of the channel
		var description: String?					// optional description of the channel
		var logo_path: String?						// optional relative path to watermark
	}
	
	public struct SeriesType: Codable {
		var title: String							// required title of the series
		var logo_path: String?						// optional logo for the series
	}
	
	public struct CategoryType: Codable {
		var id: String								// required id for the cateogry (must be unique among categories)
		var title: String							// required title for the category
		var chyron_path: String?					// optional artwork for the category
	}
	
	public struct ListProgramType: Codable {
		var start_time: String						// required ISO 8601 time format
		var list_ids: [String]						// required list identifier
		var end_time: String?						// optional ISO 8601 time format
	}
	
	public struct SelectedListProgramType: Codable {
		var weekday_ordinal: Int					// Weekday, 0 = Sunday, etc.
		var listProgram: ListProgramType			// required
	}
	
	public struct ListScheduleType: Codable {
		var schedule: [ListProgramType]				// required array of seven ListProgramType
	}
	
	public struct ListDescriptorType: Codable {
		var list_path: String						// required (relative) path to list
	}
	
	public struct ManifestType: Codable {
		var version: String							// required, "UHF channel - v1"
		var info: ChannelInfoType?					// optional info about the channel
		var schedules: [ScheduleDescriptorType]		// required array, must be in ascending date order
		var series: [String:SeriesType]?			// optional series array
		var lists: [String:ListDescriptorType]?		// optional array of list descriptors
		var categories: [CategoryType]?				// optional category array
		var dotw_list_schedule: [ListScheduleType]?	// optional day-of-the-week array (7 elements)
		var beginning_of_broadcast_day: String?		// optional when broadcasting begins (ISO 8601 time format)
	}
	
	public struct SeriesDataSourceType {
		var id: String
		var title: String
		var logo: NSImage?
	}
	
	public struct ListsDataSourceType {
		var id: String
		var list_path: String
		var title: String?
		var description: String?
		var uniquePathSet: Set<String>?
	}
	
	public struct ListsContentDataSourceType {
		var id: String
		var path: String
		var duration: Int
		var title: String?
	}
	
	
	@IBOutlet var manifestTabView: NSTabView!
	
	@IBOutlet var infoContainerView: NSView!
	
	@IBOutlet var placeholderTextField: NSTextField!
	
	@IBOutlet var channelInfoTitleTextField: NSTextField!
	@IBOutlet var channelInfoDescriptionTextField: NSTextField!
	@IBOutlet var resourceDatabaseTextField: NSTextField!
	
	@IBOutlet var scheduleCollectionView: NSCollectionView!
	@IBOutlet var setBOBDViewController: NSViewController!
	@IBOutlet var bobdTextField: NSTextField!
	
	@IBOutlet var resourceTimeTextField: NSTextField!
	@IBOutlet var resourceYearTextField: NSTextField!
	@IBOutlet var resourceIdentifierTextField: NSTextField!
	@IBOutlet var resourceSeriesIdentifierTextField: NSTextField!
	@IBOutlet var resourceTitleTextField: NSTextField!
	@IBOutlet var resourceDescriptionTextField: NSTextField!
	@IBOutlet var resourceDurationTextField: NSTextField!
	@IBOutlet var resourceStartOffsetTextField: NSTextField!
	@IBOutlet var resourceOrderTextField: NSTextField!
	@IBOutlet var resourcePathTextField: NSTextField!
	@IBOutlet var resourceSelectPathButton: NSButton!
	@IBOutlet var resourceDeleteButton: NSButton!
	
	@IBOutlet var seriesTableView: NSTableView!
	@IBOutlet var seriesTitleTextField: NSTextField!
	@IBOutlet var seriesIdentifierTextField: NSTextField!
	@IBOutlet var seriesLogoImageView: NSImageView!
	@IBOutlet var assignSeriesLogoButton: NSButton!
	@IBOutlet var addSeriesViewController: NSViewController!
	@IBOutlet var addSeriesTitleTextField: NSTextField!
	@IBOutlet var addSeriesIdentifierTextField: NSTextField!
	@IBOutlet var deleteSeriesButton: NSButton!
	
	@IBOutlet var listsTableView: NSTableView!
	@IBOutlet var listTitleTextField: NSTextField!
	@IBOutlet var listIdentifierTextField: NSTextField!
	@IBOutlet var listDescriptionTextField: NSTextField!
	@IBOutlet var removeListButton: NSButton!
	@IBOutlet var listContentTableView: NSTableView!
	@IBOutlet var addListContentButton: NSButton!
	@IBOutlet var removeListContentButton: NSButton!
	@IBOutlet var newListViewController: NSViewController!
	@IBOutlet var newListTitleTextField: NSTextField!
	@IBOutlet var newListIdentifierTextField: NSTextField!
	
	@IBOutlet var newChannelViewController: NSViewController!
	@IBOutlet var newChannelNumberOfWeeksTextField: NSTextField!
	@IBOutlet var newChannelStartDateTextField: NSTextField!
	
	@IBOutlet var contentTableView: NSTableView!
	
	@IBOutlet var weeklyCollectionView: NSCollectionView!
	
	let supportedOMXPlayerExtensions = ["avi", "mov", "mkv", "mp4", "m4v"]
	
	var channelDirectoryURL: URL?
	
	var manifest: ManifestType?
	var manifestDirty: Bool = false
	
	var schedules: [ScheduleType] = []
	var schedulesDirty: [Bool] = []
	
	var seriesDataSource: [SeriesDataSourceType] = []
	var seriesDataSourceInvalid = true
	
	var lists: [String:ListType] = [:]
	var listsDirty: [String: Bool] = [:]
	
	var listsDataSource: [ListsDataSourceType] = []
	var listsDataSourceInvalid = true
	
	var listsContentDataSource: [ListsContentDataSourceType] = []
	var listsContentDataSourceInvalid = true

	var selectedProgram: ScheduleDayType? = nil
	var selectedListProgram: SelectedListProgramType? = nil
	
	var sourceResources: [ResourceType] = []
	
	var resourceDatabase: [String:ResourceType] = [:]
	var resourceDatabaseDirty = false
	
	var schedulePaths: Set<String> = []
	
	var wasDragDestinationIndex: Int? = nil
	
	var dirtyTextField: NSTextField? = nil
	
	var blacklistedURLs: [String] = []
	
	let bookmarks = Bookmarks.restore() ?? Bookmarks(data: [:])
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.scheduleCollectionView.register (NSNib (nibNamed: "ScheduleCollectionViewItem",
				bundle: Bundle (for: ScheduleCollectionViewItem.self)),
				forItemWithIdentifier: NSUserInterfaceItemIdentifier (rawValue: "com.UHFScheduler.scheduleCell"))
		
		let scheduleLayout = NSCollectionViewGridLayout ()
		scheduleLayout.maximumNumberOfRows = 1
		scheduleLayout.minimumItemSize = NSMakeSize (96, 764 + 36)
		self.scheduleCollectionView.collectionViewLayout = scheduleLayout
		self.scheduleCollectionView.registerForDraggedTypes ([.string])
		
		self.contentTableView.setDraggingSourceOperationMask (.link, forLocal: true)
		self.contentTableView.registerForDraggedTypes ([.string])
		self.contentTableView.tableColumns[0].sortDescriptorPrototype = NSSortDescriptor (key: "title", ascending: true)
		self.contentTableView.tableColumns[1].sortDescriptorPrototype = NSSortDescriptor (key: "duration", ascending: true)
		
		self.listContentTableView.tableColumns[0].sortDescriptorPrototype = NSSortDescriptor (key: "title", ascending: true)
		self.listContentTableView.tableColumns[1].sortDescriptorPrototype = NSSortDescriptor (key: "duration", ascending: true)
		
		self.weeklyCollectionView.register (NSNib (nibNamed: "WeeklyCollectionViewItem",
				bundle: Bundle (for: WeeklyCollectionViewItem.self)),
				forItemWithIdentifier: NSUserInterfaceItemIdentifier (rawValue: "weeklyCell"))
		
		let weeklyLayout = NSCollectionViewGridLayout ()
		weeklyLayout.maximumNumberOfRows = 1
		weeklyLayout.minimumItemSize = NSMakeSize (96, 764 + 36)
		self.weeklyCollectionView.collectionViewLayout = weeklyLayout
		
		self.updateUserInterface ()
    }
	
	func updateUserInterface () {
		placeholderTextField.isHidden = self.manifest != nil
		infoContainerView.isHidden = self.manifest == nil
	}
	
	func channelIsDirty () -> Bool {
		if self.manifestDirty == true {
			return true
		}
		
		for oneDirtySchedule in self.schedulesDirty {
			if oneDirtySchedule == true {
				return true
			}
		}
		
		for (_, oneDirtyList) in self.listsDirty {
			if oneDirtyList == true {
				return true
			}
		}
		
		return false
	}
	
	func markChannelDirty (_ dirty: Bool) {
		self.manifestDirty = dirty
	}
	
	func markScheduleDirty (scheduleIndex: Int, dirty: Bool) {
		self.schedulesDirty[scheduleIndex] = dirty
	}
	
	func scheduleDate (dayOrdinal index: Int) -> Date? {
		guard let scheduleDescriptors = self.manifest?.schedules else {
			return nil
		}
		
		var localIndex = index
		let iso8601Formatter = ISO8601DateFormatter ()
		iso8601Formatter.formatOptions = [.withFullDate]
		var descriptorIndex = 0
		for oneScheduleDescriptor in scheduleDescriptors {
			let dayCount = self.schedules[descriptorIndex].days.count
			if dayCount > localIndex {
				if let theDate = iso8601Formatter.date (from: oneScheduleDescriptor.start_date) {
					return Calendar.current.date (byAdding: .day, value: localIndex, to: theDate)
				} else {
					print ("scheduleDate(dayOrdinal:) error")
					return nil
				}
			} else {
				localIndex -= dayCount
			}
			descriptorIndex = descriptorIndex + 1
		}
		return nil
	}
	
	/// Return the index for the manifest schedules[] array given an index representing all days in the schedule.
	
	func schedulesIndex (dayOrdinal index: Int) -> Int? {
		guard index >= 0 else {
			return nil
		}
		
		var localIndex = index
		for (scheduleIndex, oneSchedule) in self.schedules.enumerated () {
			let dayCount = oneSchedule.days.count
			if dayCount > localIndex {
				return scheduleIndex
			} else {
				localIndex -= dayCount
			}
		}
		
		return nil
	}
	
	func dayIndex (dayOrdinal index: Int) -> Int? {
		var localIndex = index
		for oneSchedule in self.schedules {
			let dayCount = oneSchedule.days.count
			if dayCount > localIndex {
				return localIndex
			} else {
				localIndex -= dayCount
			}
		}
		
		return nil
	}
	
	func daysPrograms (dayOrdinal index: Int) -> [ProgramType] {
		var localIndex = index
		for oneSchedule in self.schedules {
			let dayCount = oneSchedule.days.count
			if dayCount > localIndex {
				return oneSchedule.days[localIndex]
			} else {
				localIndex -= dayCount
			}
		}
		return []
	}
	
	// BOGUS: NIX THIS FUNCTION
	
//	func resource (fromSchedule schedule: ScheduleType, withIdentifier id: String) -> ResourceType? {
//		return schedule.resources[id]
//	}
	
	func setDurationForResource (scheduleIndex: Int, id: String, duration: Int) {
		self.schedules[scheduleIndex].resources[id]?.duration = duration
	}
	
	func preflightResourceURLs (scheduleIndex: Int, programs: [ProgramType]) {
		DispatchQueue.global(qos: .userInitiated).async {
			let schedule = self.schedules[scheduleIndex]
			var failedToReadFile = true
			while failedToReadFile {
				failedToReadFile = false
				for oneProgram in programs {
					if let resource = schedule.resources[oneProgram.resource_id] {
						let resourceURL = URL (fileURLWithPath: resource.path, relativeTo: self.channelDirectoryURL)
						let asset = AVAsset(url: resourceURL)
						let duration = asset.duration
						let durationTime = CMTimeGetSeconds(duration)
						if (durationTime == 0.0) && (self.blacklistedURLs.contains (resourceURL.path) == false) {
							let semaphore = DispatchSemaphore(value: 0)
							DispatchQueue.main.async {
								let openPanel = NSOpenPanel()
								openPanel.allowsMultipleSelection = false
								openPanel.canChooseDirectories = true
								openPanel.canChooseFiles = false
								openPanel.message = "Select the directory containing " + resourceURL.lastPathComponent
								openPanel.begin { (result) -> Void in
									if result == NSApplication.ModalResponse.OK {
										for oneURL in openPanel.urls {
											self.bookmarks.store (url: oneURL)
											self.bookmarks.dump ()
										}
										semaphore.signal()
									} else {
										semaphore.signal()
										self.blacklistedURLs.append (resourceURL.path)
										return
									}
								}
							}
							semaphore.wait()
							failedToReadFile = true
							break
						} else {
							self.setDurationForResource (scheduleIndex: scheduleIndex, id: oneProgram.resource_id, duration: Int(ceil (durationTime)))
						}
					}
				}
			}
		}
	}
	
	func removeOrphanedResources (scheduleIndex: Int) {
		let schedule = self.schedules[scheduleIndex]
		
		// Build sets of resource ID's from the .resources and from the day schedules.
		let resourceIDSet : Set<String> = Set (schedule.resources.keys)
		var scheduleIDSet : Set<String> = []
		for oneDaysSchedule in schedule.days {
			for oneProgram in oneDaysSchedule {
				scheduleIDSet.insert (oneProgram.resource_id)
			}
		}
		
		// Subtract schedule resource IDs from the set of all IDs to find orphaned resources.
		let orphanedIDSet = resourceIDSet.subtracting (scheduleIDSet)
		for oneOrphanedID in orphanedIDSet {
			self.schedules[scheduleIndex].resources.removeValue (forKey: oneOrphanedID)
			print ("removeOrphanedResources(); info, removed orphaned resource: " + oneOrphanedID)
		}
		
		// Subtract all resource IDs from the set of schedules IDs to find missing resources.
		let missingIDSet = scheduleIDSet.subtracting (resourceIDSet)
		if missingIDSet.count > 0 {
			print ("removeOrphanedResources(); error, there is a resource ID on the schedule, not among the resources.")
		}
	}
	
	func displayTitle (forResource resource: ResourceType) -> String {
		var title = resource.title ?? "Missing title"
		if let seriesID = resource.series_id, let seriesTitle = self.manifest?.series?[seriesID]?.title {
			title = seriesTitle
		}
		return title
	}
	
	/// Somewhat arbitrary way of 'ranking' two Resources. We prefer a Resource with a description over one without, one with a year over one
	/// without, one with an order vs. one without. Otherwise, fall back to the first of the two.
	
	func preferredResource (choiceA: ResourceType, choiceB: ResourceType) -> ResourceType {
		if (choiceA.description != nil) && (choiceB.description == nil) {
			return choiceA
		} else if (choiceB.description != nil) && (choiceA.description == nil) {
			return choiceB
		} else if  (choiceA.year != nil) && (choiceB.year == nil) {
			return choiceA
		} else if (choiceB.year != nil) && (choiceA.year == nil) {
			return choiceB
		} else if  (choiceA.order != nil) && (choiceB.order == nil) {
			return choiceA
		} else if (choiceB.order != nil) && (choiceA.order == nil) {
			return choiceB
		}
		
		return choiceA
	}
	
	func ffProbeGetDurationSeconds (inputFilePath: String) -> Int {
		guard let launchPath = Bundle.main.path (forResource: "ffprobe", ofType: "") else {
			return 0
		}
		
		let ffprobeProcess = Process ()
		ffprobeProcess.launchPath = launchPath
		ffprobeProcess.arguments = ["-show_format", inputFilePath, "-v", "0"]
		let pipe = Pipe ()
		ffprobeProcess.standardOutput = pipe
		ffprobeProcess.launch ()
		ffprobeProcess.waitUntilExit ()
		let data = pipe.fileHandleForReading.readDataToEndOfFile ()
		if let string = String (data: data, encoding: String.Encoding.utf8) {
			if let durationRange = string.range (of: "duration=") {
				let durationEnd = durationRange.upperBound
				let durationPortion = string[durationEnd..<string.endIndex]
				if let numberRange = durationPortion.range(of: "\n") {
					let numberEnd = numberRange.lowerBound
					let numberPortion = string[durationPortion.startIndex..<numberEnd]
					if let floatyDuration = Double (numberPortion) {
						return Int (ceil (floatyDuration))
					}
				}
			}
		}
		
		return 0
	}
	
	func newResource (fromURL fileURL: URL) -> ResourceType? {
		guard let channelURL = self.channelDirectoryURL else {
			return nil
		}
		
		if self.supportedOMXPlayerExtensions.contains (fileURL.pathExtension) {
			let asset = AVAsset (url: fileURL)
			var duration = Int (ceil (CMTimeGetSeconds (asset.duration)))
			if (duration == 0) && (fileURL.pathExtension == "mkv") {
				duration = self.ffProbeGetDurationSeconds (inputFilePath: fileURL.path)
			}
			
			if duration > 0 {
				let relativePath = self.getRelativeFilePath (fileURL, relativeTo: channelURL)
				let title = fileURL.deletingPathExtension ().lastPathComponent
				let resource = ResourceType (path: relativePath, duration: duration, title: title,
						series_id: nil, order: nil, description: nil, year: nil, start_offset: nil)
				return resource
			} else {
				print ("newResource(fromURL:); error, unable to get duration for " + fileURL.lastPathComponent)
			}
		}
		
		return nil
	}
	
	func offsetSchedule (days: Int) {
		let iso8601Formatter = ISO8601DateFormatter ()
		iso8601Formatter.formatOptions = [.withFullDate]
		
		if let manifest = self.manifest {
			for (index, oneSchedule) in manifest.schedules.enumerated() {
				if let oldDate = iso8601Formatter.date (from: oneSchedule.start_date) {
					if let newDate = Calendar.current.date(byAdding: .day, value: days, to: oldDate) {
						let newDataString = iso8601Formatter.string (from: newDate)
						self.manifest!.schedules[index].start_date = newDataString
					}
				}
			}
			self.scheduleCollectionView.reloadData ()
		}
	}
	
	func getRelativeFilePath (_ url: URL, relativeTo relativeURL: URL) -> String {
		let urlPathComponents = url.pathComponents
		let relativeURLPathComponents = relativeURL.pathComponents
		var index = 0;
		let shortestIndex = min (urlPathComponents.count, relativeURLPathComponents.count)
		while index < shortestIndex, urlPathComponents[index] == relativeURLPathComponents[index] {
			index = index + 1
		}
		
		var relativePath = ""
		var directoryDepth = relativeURLPathComponents.count - index
		for _ in 0..<directoryDepth {
			relativePath = relativePath + "../"	// BOGUS, need a forward slash as well
		}
		directoryDepth = urlPathComponents.count - index
		for pathIndex in 0..<directoryDepth {
			relativePath = relativePath + urlPathComponents[index + pathIndex]
			if (pathIndex + 1) < directoryDepth {
				relativePath = relativePath + "/"
			}
		}
		
		return relativePath
	}
	
	// MARK: - Resource Database
	
	func exportResourceDatabase (toURL url: URL) {
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		if let json = try? encoder.encode (Array (self.resourceDatabase.values)) {
			do {
				try json.write (to: url)
			}
			catch {
				print ("exportResourceDatabase(); write JSON error.")
			}
		} else {
			print ("exportResourceDatabase(); encode JSON error.")
		}
	}
	
	/// Walk all the schedules and extract their resources. Populate the database with these resources, using their schedule identifiers as keys.
	
	func initialPopulateResourceDatabase () {
		for oneSchedule in self.schedules {
			for oneDay in oneSchedule.days {
				for oneProgram in oneDay {
					if let newResource = oneSchedule.resources[oneProgram.resource_id] {
						if let existingResource = self.resourceDatabase[oneProgram.resource_id] {
							self.resourceDatabase[oneProgram.resource_id] = self.preferredResource (choiceA: existingResource,
									choiceB: newResource)
						} else {
							self.resourceDatabase[oneProgram.resource_id] = newResource
						}
					}
				}
			}
		}
	}
	
	func matchingResourceFromDatabase (_ sourceResource: ResourceType) -> (resource:ResourceType, identifier:String?) {
		for (identifier, resource) in self.resourceDatabase {
			if resource.path == sourceResource.path {
				return (ResourceType (path: resource.path, duration: resource.duration, title: resource.title,
						series_id: resource.series_id, order: resource.order, description: resource.description,
						year: resource.year, start_offset: resource.start_offset), identifier)
			}
		}
		return (sourceResource, nil)
	}
	
	func mergeChangedResourceToDatabase (_ resource: ResourceType, identifier: String) {
		if self.resourceDatabase[identifier] != nil {
			self.resourceDatabase[identifier]?.order = resource.order
			self.resourceDatabase[identifier]?.title = resource.title
			self.resourceDatabase[identifier]?.description = resource.description
			self.resourceDatabase[identifier]?.year = resource.year
			self.resourceDatabase[identifier]?.series_id = resource.series_id
			self.resourceDatabase[identifier]?.start_offset = resource.start_offset
			self.resourceDatabaseDirty = true
		}
	}
	
	func populateSchedulePathsArray () {
		for oneSchedule in self.schedules {
			for oneProgramDay in oneSchedule.days {
				for oneProgram in oneProgramDay {
					if let path = oneSchedule.resources[oneProgram.resource_id]?.path {
						self.schedulePaths.insert (path)
					}
				}
			}
		}
	}
	
	// MARK: - Channel Info
	
	func updateManifestInfo () {
		if let unwrappedManifest = self.manifest, let channelInfo = unwrappedManifest.info {
			self.channelInfoTitleTextField.stringValue = channelInfo.title ?? ""
			self.channelInfoDescriptionTextField.stringValue = channelInfo.description ?? ""
		}
	}
	
	func setChannelInfoTitle (_ title: String) {
		if self.manifest?.info != nil {
			self.manifest?.info?.title = title
		} else {
			let info = ChannelInfoType (title: title, description: nil, logo_path: nil)
			self.manifest?.info = info
		}
		self.markChannelDirty (true)
	}
	
	func setChannelInfoDescription (_ description: String) {
		if self.manifest?.info != nil {
			self.manifest?.info?.description = description
		} else {
			let info = ChannelInfoType (title: nil, description: description, logo_path: nil)
			self.manifest?.info = info
		}
		self.markChannelDirty (true)
	}
	
	// MARK: - Selected Program
	
	func currentlySelectedScheduleIndex () -> Int? {
		guard let selection = self.selectedProgram else {
			return nil
		}
		
		return self.schedulesIndex (dayOrdinal: selection.day_ordinal)
	}
	
	func currentlySelectedDayIndex () -> Int? {
		guard let selection = self.selectedProgram else {
			return nil
		}
		
		return self.dayIndex (dayOrdinal: selection.day_ordinal)
	}
	
	func currentlySelectedProgramIndex (scheduleIndex: Int) -> Int? {
		guard let selection = self.selectedProgram else {
			return nil
		}
		
		let programs = self.daysPrograms (dayOrdinal: selection.day_ordinal)
		for (index, oneProgram) in programs.enumerated () {
			if oneProgram.start_time == selection.start_time {
				return index
			}
		}
		
		return nil
	}
	
	func currentlySelectedResourceIdentifier () -> String? {
		guard let selection = self.selectedProgram else {
			return nil
		}
		
		let programs = self.daysPrograms (dayOrdinal: selection.day_ordinal)
		for oneProgram in programs {
			if oneProgram.start_time == selection.start_time {
				return oneProgram.resource_id
			}
		}
		
		return nil
	}
	
	func currentlySelectedResource () -> ResourceType? {
		guard let selection = self.selectedProgram else {
			return nil
		}
		
		let programs = self.daysPrograms (dayOrdinal: selection.day_ordinal)
		for oneProgram in programs {
			if oneProgram.start_time == selection.start_time {
				if let scheduleIndex = self.schedulesIndex (dayOrdinal: selection.day_ordinal) {
					return self.schedules[scheduleIndex].resources[oneProgram.resource_id]
				} else {
					return nil
				}
			}
		}
		
		return nil
	}
	
	func programSchedule (forDayOrdinal dayOrdinal: Int, startTime: String) -> ScheduleDayType? {
		var program: ScheduleDayType? = nil
		let daysSchedule = self.daysSchedule (dayOrdinal: dayOrdinal)
		for oneSchedule in daysSchedule {
			if oneSchedule.start_time == startTime {
				program = oneSchedule
				break
			}
		}
		return program
	}
	
	func programAWeekPriorToSelection () -> ScheduleDayType?{
		guard let selection = self.selectedProgram else {
			return nil
		}
		return self.programSchedule (forDayOrdinal: selection.day_ordinal - 7, startTime: selection.start_time)
	}
	
	func programAWeekFollowingSelection () -> ScheduleDayType?{
		guard let selection = self.selectedProgram else {
			return nil
		}
		return self.programSchedule (forDayOrdinal: selection.day_ordinal + 7, startTime: selection.start_time)
	}
	
	func programADayPriorToSelection () -> ScheduleDayType?{
		guard let selection = self.selectedProgram else {
			return nil
		}
		return self.programSchedule (forDayOrdinal: selection.day_ordinal - 1, startTime: selection.start_time)
	}
	
	func programADayFollowingSelection () -> ScheduleDayType?{
		guard let selection = self.selectedProgram else {
			return nil
		}
		return self.programSchedule (forDayOrdinal: selection.day_ordinal + 1, startTime: selection.start_time)
	}
	
	func programPriorToSelection () -> ScheduleDayType?{
		guard let selection = self.selectedProgram else {
			return nil
		}
		var program: ScheduleDayType? = nil
		let daysSchedule = self.daysSchedule (dayOrdinal: selection.day_ordinal)
		for oneSchedule in daysSchedule {
			if oneSchedule.start_time == selection.start_time {
				break
			}
			program = oneSchedule
		}
		return program
	}
	
	func programFollowingSelection () -> ScheduleDayType?{
		guard let selection = self.selectedProgram else {
			return nil
		}
		var program: ScheduleDayType? = nil
		let daysSchedule = self.daysSchedule (dayOrdinal: selection.day_ordinal)
		var nextOne = false
		for oneSchedule in daysSchedule {
			if nextOne {
				program = oneSchedule
				break
			}
			if oneSchedule.start_time == selection.start_time {
				nextOne = true
			}
		}
		return program
	}
	
	func setSelectedProgramStartTime (_ startTime: String) -> String {
		let formatter = DateFormatter ()
		formatter.dateFormat = "HH:mm"
		if let newDate = formatter.date (from: startTime) {
			let newStartTime = formatter.string (from: newDate)
			if let scheduleIndex = self.currentlySelectedScheduleIndex () {
				if let dayIndex = self.currentlySelectedDayIndex () {
					if let programIndex = self.currentlySelectedProgramIndex (scheduleIndex: scheduleIndex) {
						self.schedules[scheduleIndex].days[dayIndex][programIndex].start_time = newStartTime
						self.markScheduleDirty (scheduleIndex: scheduleIndex, dirty: true)
						self.schedules[scheduleIndex].days[dayIndex].sort (by: {$0.start_time < $1.start_time})
						self.scheduleCollectionView.reloadData ()
						return newStartTime
					}
				}
			}
		}
		
		return startTime
	}
	
	func addMinutesToSelectedProgramStartTime (_ minutes: Int) -> String? {
		guard let selection = self.selectedProgram else {
			return nil
		}
		
		let formatter = DateFormatter ()
		formatter.dateFormat = "HH:mm"
		
		guard let startTimeDate = formatter.date (from: selection.start_time) else {
			return nil
		}
		
		guard let newStartTimeDate = Calendar.current.date (byAdding: .minute, value: minutes, to: startTimeDate) else {
			return nil
		}
		
		let newStartTime = formatter.string (from: newStartTimeDate)
		return self.setSelectedProgramStartTime (newStartTime)
	}
	
	/// Change the identifier used as the ResourceType key in the current schedule.
	
	func setSelectedProgramResourceIdentifier (_ resourceID: String) -> Bool {
		if let scheduleIndex = self.currentlySelectedScheduleIndex () {
			// Sanity check, disallow changing the resource ID to something already in the schedule.
			// BOGUS: SHOULD ALLOW IF 'PATH' IS THE SAME.
			if self.schedules[scheduleIndex].resources[resourceID] != nil {
				return false
			}
			
			// Find the rresource ID for the currently selected program. Remove key, assign resource to new key.
			if let wasResourceID = self.currentlySelectedResourceIdentifier () {
				if let wasResource = self.schedules[scheduleIndex].resources.removeValue (forKey: wasResourceID) {
					self.schedules[scheduleIndex].resources[resourceID] = wasResource
					
					// Walk the rest of the schedule and change the identifier.
					for (dayIndex, oneProgramDay) in self.schedules[scheduleIndex].days.enumerated () {
						for (programIndex, oneProgram) in oneProgramDay.enumerated () {
							if oneProgram.resource_id == wasResourceID {
								self.schedules[scheduleIndex].days[dayIndex][programIndex].resource_id = resourceID
								self.markScheduleDirty (scheduleIndex: scheduleIndex, dirty: true)
							}
						}
					}
					
					// Success.
					return true
				}
			}
		}
		
		// Failure.
		return false
	}
	
	/// Change the title for the ResourceType of the currently seelcted program.
	
	func setSelectedProgramTitle (_ title: String) {
		if let scheduleIndex = self.currentlySelectedScheduleIndex () {
			if let resourceID = self.currentlySelectedResourceIdentifier () {
				self.schedules[scheduleIndex].resources[resourceID]?.title = title
				if let resource = self.schedules[scheduleIndex].resources[resourceID] {
					self.mergeChangedResourceToDatabase (resource, identifier: resourceID)
				}
				self.markScheduleDirty (scheduleIndex: scheduleIndex, dirty: true)
			}
		}
	}
	
	func setSelectedProgramYear (_ yearString: String) {
		if let scheduleIndex = self.currentlySelectedScheduleIndex () {
			if let resourceID = currentlySelectedResourceIdentifier () {
				if yearString.count == 0 {
					self.schedules[scheduleIndex].resources[resourceID]?.year = nil
				} else {
					self.schedules[scheduleIndex].resources[resourceID]?.year = Int (yearString)
				}
				if let resource = self.schedules[scheduleIndex].resources[resourceID] {
					self.mergeChangedResourceToDatabase (resource, identifier: resourceID)
				}
				self.markScheduleDirty (scheduleIndex: scheduleIndex, dirty: true)
			}
		}
	}
	
	func setSelectedProgramSeriesIdentifier (_ identifier: String) {
		if let scheduleIndex = self.currentlySelectedScheduleIndex () {
			if let resourceID = currentlySelectedResourceIdentifier () {
				self.schedules[scheduleIndex].resources[resourceID]?.series_id = identifier
				if let resource = self.schedules[scheduleIndex].resources[resourceID] {
					self.mergeChangedResourceToDatabase (resource, identifier: resourceID)
				}
				self.markScheduleDirty (scheduleIndex: scheduleIndex, dirty: true)
			}
		}
	}
	
	func setSelectedProgramOrder (_ orderSring: String) {
		if let scheduleIndex = self.currentlySelectedScheduleIndex () {
			if let resourceID = currentlySelectedResourceIdentifier () {
				self.schedules[scheduleIndex].resources[resourceID]?.order = orderSring.count > 0 ? Int (orderSring) : nil
				if let resource = self.schedules[scheduleIndex].resources[resourceID] {
					self.mergeChangedResourceToDatabase (resource, identifier: resourceID)
				}
				self.markScheduleDirty (scheduleIndex: scheduleIndex, dirty: true)
			}
		}
	}
	
	func setSelectedStartOffset (_ startOffsetSring: String) -> String {
		if let scheduleIndex = self.currentlySelectedScheduleIndex () {
			if let resourceID = currentlySelectedResourceIdentifier () {
				var dateString = ""
				let formatter = DateFormatter()
				formatter.dateFormat = "HH:mm:ss"
				if let newDate = formatter.date (from: startOffsetSring) {
					dateString = formatter.string (from: newDate)
					let calendar = Calendar.current
					let seconds = (calendar.component (.hour, from: newDate) * 60 * 60) + (calendar.component (.minute, from: newDate) * 60) + calendar.component (.second, from: newDate)
					self.schedules[scheduleIndex].resources[resourceID]?.start_offset = seconds
				} else {
					self.schedules[scheduleIndex].resources[resourceID]?.start_offset = nil
				}
				if let resource = self.schedules[scheduleIndex].resources[resourceID] {
					self.mergeChangedResourceToDatabase (resource, identifier: resourceID)
				}
				self.markScheduleDirty (scheduleIndex: scheduleIndex, dirty: true)
				
				return dateString
			}
		}
		
		return ""
	}
	
	func setSelectedProgramDescription (_ description: String) {
		if let scheduleIndex = self.currentlySelectedScheduleIndex () {
			if let resourceID = currentlySelectedResourceIdentifier () {
				self.schedules[scheduleIndex].resources[resourceID]?.description = description
				if let resource = self.schedules[scheduleIndex].resources[resourceID] {
					self.mergeChangedResourceToDatabase (resource, identifier: resourceID)
				}
				self.markScheduleDirty (scheduleIndex: scheduleIndex, dirty: true)
			}
		}
	}
	
	func setSelectedProgramPath (_ path: String) {
		if let scheduleIndex = self.currentlySelectedScheduleIndex () {
			if let resourceID = currentlySelectedResourceIdentifier () {
				self.schedules[scheduleIndex].resources[resourceID]?.path = path
				let duration = self.duration (forResourceWithPath: path)
				if (duration != 0.0) {
					self.schedules[scheduleIndex].resources[resourceID]?.duration = Int (ceil (duration))
				}
				if let resource = self.schedules[scheduleIndex].resources[resourceID] {
					self.mergeChangedResourceToDatabase (resource, identifier: resourceID)
				}
				self.markScheduleDirty (scheduleIndex: scheduleIndex, dirty: true)
			}
		}
	}
	
	func daysSchedule (dayOrdinal: Int) -> [ScheduleDayType] {
		var scheduleDay: [ScheduleDayType] = []
		
		if let scheduleIndex = self.schedulesIndex (dayOrdinal: dayOrdinal) {
			let schedule = self.schedules[scheduleIndex]
			let programs = self.daysPrograms (dayOrdinal: dayOrdinal)
			for oneProgram in programs {
				if let resource = schedule.resources[oneProgram.resource_id] {
					let pathLegit = self.readableAtPath (path: resource.path)
					let hasDescription = resource.description != nil && resource.description!.count > 0
					let dayProgram = ScheduleDayType (start_time: oneProgram.start_time, duration: resource.duration,
							title: self.displayTitle (forResource: resource), day_ordinal: dayOrdinal,
							hasDescription: hasDescription, error: pathLegit == false)
					scheduleDay.append (dayProgram)
				}
			}
		}
		
		return scheduleDay
	}
	
	func deleteSelectedProgram () {
		guard let selection = self.selectedProgram else {
			return
		}
		
		if let scheduleIndex = self.currentlySelectedScheduleIndex () {
			if let dayIndex = self.currentlySelectedDayIndex () {
				for (index, oneProgram) in self.schedules[scheduleIndex].days[dayIndex].enumerated () {
					if oneProgram.start_time == selection.start_time {
						self.schedules[scheduleIndex].days[dayIndex].remove (at: index)
						self.markScheduleDirty (scheduleIndex: scheduleIndex, dirty: true)
						if let itemSelected = self.scheduleCollectionView.item (at: selection.day_ordinal) as? ScheduleCollectionViewItem {
							itemSelected.setSelectedProgram (nil)
							itemSelected.setSchedule (self.daysSchedule (dayOrdinal: selection.day_ordinal))
							self.selectedProgram = nil
							self.markScheduleDirty (scheduleIndex: scheduleIndex, dirty: true)
						}
						break
					}
				}
			}
		}
	}
	
	func durationString (fromDuration duration: Int?) -> String {
		if let unwrappedDuration = duration {
			let formatter = DateComponentsFormatter ()
			formatter.allowedUnits = [.hour, .minute, .second]
			formatter.unitsStyle = .positional // .abbreviated
			return formatter.string (from: TimeInterval(unwrappedDuration))!
		}
		
		return "unknown"
	}
	
	func updateProgramView (withProgram program: ScheduleDayType) {
		if let scheduleIndex = self.schedulesIndex (dayOrdinal: program.day_ordinal) {
			let schedule = self.schedules[scheduleIndex]
			let programs = self.daysPrograms (dayOrdinal: program.day_ordinal)
			for oneProgram in programs {
				if oneProgram.start_time == program.start_time, let resource = schedule.resources[oneProgram.resource_id] {
					self.resourceTimeTextField.stringValue = program.start_time
					self.resourceYearTextField.stringValue = ""
					if let year = resource.year {
						self.resourceYearTextField.stringValue = String (year)
					}
					self.resourceIdentifierTextField.stringValue = oneProgram.resource_id
					self.resourceTitleTextField.stringValue = resource.title ?? ""
					self.resourceSeriesIdentifierTextField.stringValue = resource.series_id ?? ""
					self.resourceDescriptionTextField.stringValue = resource.description ?? ""
					self.resourceDurationTextField.stringValue = self.durationString (fromDuration: resource.duration)
					self.resourceStartOffsetTextField.stringValue = resource.start_offset != nil ? self.durationString (fromDuration: resource.start_offset) : ""
					self.resourceOrderTextField.stringValue = resource.order != nil ? String (resource.order!) : ""
					self.resourcePathTextField.stringValue = resource.path
					self.resourcePathTextField.textColor = self.readableAtPath(path: resource.path) ? NSColor.black : NSColor.systemRed
				}
			}
		}
	}
	
	func selectProgram (selected: ScheduleDayType) {
		// Save edits to current text field before changing selection.
		if let textField = self.dirtyTextField {
			self.handleTextFieldEditing (textField)
		}
		
		self.updateProgramView (withProgram: selected)
		
		if let previousSelection = self.selectedProgram {
			if let itemSelected = self.scheduleCollectionView.item (at: previousSelection.day_ordinal) as? ScheduleCollectionViewItem {
				itemSelected.setSelectedProgram (nil)
			}
		}
		self.selectedProgram = selected
		
		if let itemSelected = self.scheduleCollectionView.item (at: selected.day_ordinal) as? ScheduleCollectionViewItem {
			itemSelected.setSelectedProgram (selected)
		}
	}
	
	func selectListProgram (selected: SelectedListProgramType) {
		// Save edits to current text field before changing selection.
//		if let textField = self.dirtyTextField {
//			self.handleTextFieldEditing (textField)
//		}
		
//		self.updateProgramView (withProgram: selected)
		
		self.selectedListProgram = selected
		self.weeklyCollectionView.reloadData ()
	}
	
	// MARK: - Selected Series
	
	func setSelectedSeriesTitle (_ title: String) {
		if self.seriesTableView.selectedRow >= 0 {
			self.manifest?.series?[self.seriesDataSource[seriesTableView.selectedRow].id]?.title = title
			self.seriesDataSourceInvalid = true
			self.seriesTableView.reloadData ()
			self.markChannelDirty (true)
		}
	}
	
	func setSelectedSeriesIdentifier (_ identifier: String) {
		if self.seriesTableView.selectedRow >= 0 {
			let wasID = self.seriesDataSource[seriesTableView.selectedRow].id
			if let series = self.manifest?.series?.removeValue (forKey: wasID) {
				self.manifest?.series?[identifier] = series
				self.seriesDataSourceInvalid = true
				self.seriesTableView.reloadData ()
				self.markChannelDirty (true)
			}
		}
	}
	
	func setSelectedSeriesLogoPath (_ path: String) {
		if self.seriesTableView.selectedRow >= 0 {
			self.manifest?.series?[self.seriesDataSource[seriesTableView.selectedRow].id]?.logo_path = path
			self.seriesDataSourceInvalid = true
			self.seriesTableView.reloadData ()
			self.markChannelDirty (true)
		}
	}
	
	func updateSeriesInfo (_ series: SeriesDataSourceType?) {
		if let unwrappedSeries = series {
			self.seriesTitleTextField.stringValue = unwrappedSeries.title
			self.seriesIdentifierTextField.stringValue = unwrappedSeries.id
			self.seriesLogoImageView.image = unwrappedSeries.logo
		} else {
			self.seriesTitleTextField.stringValue = ""
			self.seriesIdentifierTextField.stringValue = ""
			self.seriesLogoImageView.image = nil
		}
	}
	
	func deleteSelectedSeries () {
		if self.seriesTableView.selectedRow >= 0 {
			let seriesID = self.seriesDataSource[seriesTableView.selectedRow].id
			self.manifest?.series?.removeValue(forKey: seriesID)
			self.updateSeriesInfo (nil)
			self.seriesDataSourceInvalid = true
			self.seriesTableView.reloadData ()
			self.markChannelDirty (true)
		}
	}
	
	// BOGUS: Nix this function.
	func getList (matchingID id: String) -> ListType? {
		return self.lists[id]
	}
	
	func updateListInfo (_ list: ListsDataSourceType?) {
		if let unwrappedList = list {
			self.listTitleTextField.stringValue = unwrappedList.title ?? ""
			self.listIdentifierTextField.stringValue = unwrappedList.id
			self.listDescriptionTextField.stringValue = unwrappedList.description ?? ""
		} else {
			self.listTitleTextField.stringValue = ""
			self.listIdentifierTextField.stringValue = ""
			self.listDescriptionTextField.stringValue = ""
		}
	}
	
	// MARK: - Selected Lists
	
	func setSelectedListTitle (_ title: String?) {
		let index = self.listsTableView.selectedRow
		guard index >= 0 else {
			return
		}
		
		let identifier = self.listsDataSource[index].id
		self.lists[identifier]?.info?.title = title
		self.listsDataSourceInvalid = true
		self.listsDirty[identifier] = true
	}
	
	func setSelectedListDescription (_ description: String?) {
		let index = self.listsTableView.selectedRow
		guard index >= 0 else {
			return
		}

		let identifier = self.listsDataSource[index].id
		self.lists[identifier]?.info?.description = description
		self.listsDataSourceInvalid = true
		self.listsDirty[identifier] = true
	}
	
	/// Adds ResourceType to the currently selected ListType unless a resource with the same file path is already there.
	/// Returns True only if the resource was added.
	
	func addResourceToSelectedList (resource: ResourceType) -> Bool {
		let index = self.listsTableView.selectedRow
		guard index >= 0 else {
			return false
		}
		
		let identifier = self.listsDataSource[index].id
		guard let list = self.lists[identifier] else {
			return false
		}
		
		// Check against the set of all the resource paths. We will not add a file that is already present.
		if let pathSet = self.listsDataSource[index].uniquePathSet {
			if pathSet.contains (resource.path) {
				print ("addResourceToSelectedList(); info, resource with path: " + resource.path + ", not adding.")
				return false
			}
		} else {
			listsDataSource[index].uniquePathSet = Set<String>()
			listsDataSource[index].uniquePathSet?.insert(resource.path)
		}
		
		// Resource is not already in the list, add it.
		var count = list.resources.count
		var uuid = identifier + String (format: "%04d", count)
		while list.resources[uuid] != nil {
			count = count + 1
			uuid = identifier + String (format: "%04d", count)
		}
		self.lists[identifier]!.resources[uuid] = resource
		self.listsDataSourceInvalid = true
		self.listsDirty[identifier] = true
		self.listsContentDataSourceInvalid = true
		return true
	}
	
	// MARK: - Validation
	
	func validateScheduleFilesExist () {
		for oneSchedule in self.schedules {
			for oneDaysSchedule in oneSchedule.days {
				for oneProgram in oneDaysSchedule {
					let resourceID = oneProgram.resource_id
					if let resourcePath = oneSchedule.resources[resourceID]?.path {
						if self.readableAtPath (path: resourcePath) == false {
							print ("validateScheduleFilesExist(); Error, schedule resource with path " + resourcePath + " is missing.")
						}
					} else {
						print ("validateScheduleFilesExist(); Error, Missing path for resource with ID: " + resourceID)
					}
				}
			}
		}
		
		for (_, listValue) in self.lists {
			for (_, resourceValue) in listValue.resources {
				if self.readableAtPath (path: resourceValue.path) == false {
					print ("validateScheduleFilesExist(); Error, list resource with path " + resourceValue.path + " is missing.")
				}
			}
		}
	}
	
	func validateLegalCharactersInPath () {
		for oneSchedule in self.schedules {
			for oneDaysSchedule in oneSchedule.days {
				for oneProgram in oneDaysSchedule {
					let resourceID = oneProgram.resource_id
					if let resourcePath = oneSchedule.resources[resourceID]?.path {
						let pathComponents = resourcePath.components(separatedBy: "/")
						for oneComponent in pathComponents {
							if oneComponent.rangeOfCharacter (from: CharacterSet (charactersIn: "|<>/\\\"?*")) != nil {
								print ("validateLegalCharactersInPath(); Error, bad character in schedule resource with path " + resourcePath)
							}
							if oneComponent.last == " " {
								print ("validateLegalCharactersInPath(); Error, trailing space in schedule resource with path " + resourcePath)
							}
						}
					} else {
						print ("validateLegalCharactersInPath(); Error, Missing path for resource with ID: " + resourceID)
					}
				}
			}
		}
		
		for (_, listValue) in self.lists {
			for (_, resourceValue) in listValue.resources {
				let pathComponents = resourceValue.path.components(separatedBy: ":")
				for oneComponent in pathComponents {
					if oneComponent.contains("|<>/\\\"?*") {
						print ("validateLegalCharactersInPath(); Error, bad character in list resource with path " + resourceValue.path)
					}
					if oneComponent.last == " " {
						print ("validateLegalCharactersInPath(); Error, trailing space in list resource with path " + resourceValue.path)
					}
				}
			}
		}
	}
	
	func duration (forResourceWithPath path: String) -> Float64 {
		let resourceURL = URL (fileURLWithPath: path, relativeTo: self.channelDirectoryURL)
		let asset = AVAsset (url: resourceURL)
		let duration = asset.duration
		return CMTimeGetSeconds (duration)
	}
	
	func reassignScheduleDurations () {
		for (scheduleIndex, oneSchedule) in self.schedules.enumerated () {
			for oneDaysSchedule in oneSchedule.days {
				for oneProgram in oneDaysSchedule {
					let resourceID = oneProgram.resource_id
					if let resourcePath = oneSchedule.resources[resourceID]?.path {
						let duration = self.duration (forResourceWithPath: resourcePath)
						if (duration == 0.0) {
							let wasDuration = self.schedules[scheduleIndex].resources[resourceID]?.duration
							print ("reassignScheduleDurations(); Error, duration == 0 for resource with ID: " + resourceID + ". Duration was: " + String(wasDuration ?? 0) + ".")
						} else {
							let wasDuration = self.schedules[scheduleIndex].resources[resourceID]?.duration
							let newDuration = Int (ceil (duration))
							if wasDuration != newDuration {
								self.schedules[scheduleIndex].resources[resourceID]?.duration = newDuration
								self.markScheduleDirty (scheduleIndex: scheduleIndex, dirty: true)
								print ("reassignScheduleDurations(); Info, Modified duration for resource with ID: " + resourceID + ". Duration was: " + String(wasDuration ?? 0) + ", is now: " + String(newDuration) + ".")
							}
						}
					} else {
						print ("reassignScheduleDurations(); Error, Missing path for resource with ID: " + resourceID)
					}
				}
			}
		}
	}
	
	func reassignListDurations () {
		for (listIdentifier, listValue) in self.lists {
			for (resourceID, resourceValue) in listValue.resources {
				let duration = self.duration (forResourceWithPath: resourceValue.path)
				if (duration == 0.0) {
					print ("reassignListDurations(); Error, duration == 0 for list resource with ID: " + resourceID)
				} else {
					let wasDuration = resourceValue.duration
					let newDuration = Int (ceil (duration))
					if wasDuration != newDuration {
						self.lists[listIdentifier]?.resources[resourceID]?.duration = newDuration
						self.listsDirty[listIdentifier] = true
						print ("reassignListDurations(); Info, Modified duration for resource with ID: " + resourceID + ". Duration was: " + String(wasDuration ) + ", is now: " + String(newDuration) + ".")
					}
				}
			}
		}
	}
	
	// MARK: - File I/O
	
	func readManifest (_ url: URL) -> ManifestType? {
		if let jsonData = try? Data (contentsOf: url) {
			let decoder = JSONDecoder()
			if let manifest = try? decoder.decode(ManifestType.self, from: jsonData) {
				return manifest
			} else {
				print ("readManifest(); decode JSON error.")
			}
		} else {
			print ("readManifest(); load manifest error.")
		}
		return nil
	}
	
	func openChannelFiles (_ url: URL) -> Bool {
		var success = false
		if let manifestURL = URL (string: "manifest.json", relativeTo: url), let manifest = self.readManifest (manifestURL) {
			self.channelDirectoryURL = url
			self.manifest = manifest
			
			for oneScheduleDescriptor in manifest.schedules {
				if let scheduleURL = URL (string: oneScheduleDescriptor.schedule_path, relativeTo: self.channelDirectoryURL),
						let jsonData = try? Data (contentsOf: scheduleURL) {
					let decoder = JSONDecoder ()
					if let schedule = try? decoder.decode (ScheduleType.self, from: jsonData) {
						self.schedules.append (schedule)
					} else {
						print ("openChannelFiles(); decode schedule JSON error, url = ", scheduleURL.path)
					}
				} else {
					print ("openChannelFiles(); load schedule error.")
				}
			}
			
			if let listsDescriptors = manifest.lists {
				for (id, oneListDescriptor) in listsDescriptors {
					if let listURL = URL (string: oneListDescriptor.list_path, relativeTo: self.channelDirectoryURL),
							let jsonData = try? Data (contentsOf: listURL) {
						let decoder = JSONDecoder()
						if let list = try? decoder.decode (ListType.self, from: jsonData) {
							self.lists[id] = list
						} else {
							print ("openChannelFiles(); decode lists JSON error, url = ", listURL.path)
						}
					} else {
						print ("openChannelFiles(); load lists error.")
					}
				}
			}
			
			success = true
		}
		return success
	}
	
	func writeJSONManifest (_ channel: ManifestType, toURL url: URL) -> Bool {
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		if let json = try? encoder.encode (channel) {
			do {
				try json.write (to: url)
				return true
			}
			catch {
				print ("writeJSONChannel(); write JSON error.")
			}
		} else {
			print ("writeJSONChannel(); encode JSON error.")
		}
		return false
	}
	
	func writeJSONSchedule (_ schedule: ScheduleType, toURL url: URL) -> Bool {
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		if let json = try? encoder.encode (schedule) {
			do {
				try json.write (to: url)
				return true
			}
			catch {
				print ("writeJSONSchedule(); write JSON error.")
			}
		} else {
			print ("writeJSONSchedule(); encode JSON error.")
		}
		
		return false
	}
	
	func writeJSONList (_ list: ListType, toURL url: URL) -> Bool {
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		if let json = try? encoder.encode (list) {
			do {
				try json.write (to: url)
				return true
			}
			catch {
				print ("writeJSONSList(); write JSON error.")
			}
		} else {
			print ("writeJSONSList(); encode JSON error.")
		}
		
		return false
	}
	
	func writeChannel () {
		guard let unwrappedManifest = self.manifest, let unwrappedChannelDirectoryURL = self.channelDirectoryURL else {
			print ("writeChannel(); no manifest error.")
			return;
		}
		
		// Write manifest.
		if self.manifestDirty {
			if let manifestURL = URL (string: "manifest.json", relativeTo: unwrappedChannelDirectoryURL) {
				if self.writeJSONManifest (unwrappedManifest, toURL: manifestURL) == false {
					print ("writeChannel(); failed to write manifest error.")
					return
				}
			} else {
				print ("writeChannel(); no manifest URL error.")
			}
		}
		
		for (index, oneDirtySchedule) in self.schedulesDirty.enumerated () {
			if oneDirtySchedule {
				if let scheduleURL = URL (string: unwrappedManifest.schedules[index].schedule_path, relativeTo: unwrappedChannelDirectoryURL) {
					self.removeOrphanedResources (scheduleIndex: index)
					if self.writeJSONSchedule (self.schedules[index], toURL: scheduleURL) {
						self.schedulesDirty[index] = false
					}
				}
			}
		}
		
		for (id, oneDirtyList) in self.listsDirty {
			if oneDirtyList, let listDescriptor = unwrappedManifest.lists?[id], let oneList = self.lists[id] {
				if let listURL = URL (string: listDescriptor.list_path, relativeTo: unwrappedChannelDirectoryURL) {
					if self.writeJSONList (oneList, toURL: listURL) {
						self.listsDirty[id] = false
					}
				}
			}
		}
		
		self.markChannelDirty (false)
	}
	
	// MARK: - IBActions
	
	@IBAction func validate (sender: AnyObject) {
		self.validateScheduleFilesExist ()
		self.validateLegalCharactersInPath ()
	}
	
	@IBAction func fixDurations (sender: AnyObject) {
		self.reassignScheduleDurations ()
		self.reassignListDurations ()
	}
	
	@IBAction func newChannel (sender: AnyObject) {
		let newDateFormater = DateFormatter ()
		newDateFormater.dateFormat = "MM/dd/yyyy"
		self.newChannelStartDateTextField.stringValue = newDateFormater.string (from: Date.now)
		self.presentAsSheet (self.newChannelViewController)
	}
	
	@IBAction func newChannelOkay (sender: AnyObject) {
		if let presentedViewController = self.presentedViewControllers?.first {
			let numberOfWeeks = self.newChannelNumberOfWeeksTextField.intValue
			guard numberOfWeeks > 0 else {
				// BOGUS: PUT UP ALERT.
				return;
			}
			
			let startDateString = self.newChannelStartDateTextField.stringValue
			self.dismiss (presentedViewController)
			
			let newDateFormater = DateFormatter ()
			newDateFormater.dateFormat = "MM/dd/yyyy"
			guard var startDate = newDateFormater.date (from: startDateString) else {
				// BOGUS: PUT UP ALERT.
				return;
			}
			
			var scheduleDescriptors: [ScheduleDescriptorType] = []
			let descriptorDateFormater = DateFormatter ()
			descriptorDateFormater.dateFormat = "yyyy-MM-dd"
			
			for index in 1...numberOfWeeks {
	//			var resources: [ResourceNewType] = []
	//			let resourceStub = ResourceNewType (path: "DUMMY_PATH", duration: 0)
	//			resources.append (resourceStub)
				
				var programs: [[ProgramType]] = []
				for _ in 0...6 {
					let programDay: [ProgramType] = []
//					let newDateFormater = DateFormatter ()
//					newDateFormater.dateFormat = "HH:mm"
//					let programStub = ProgramType (start_time: newDateFormater.string (from: Date.now), resource_id: "1234")
//					programDay.append (programStub)
					programs.append (programDay)
				}
				
				let descriptorDateString = descriptorDateFormater.string (from: startDate)
				let schedulePath = String (format: "schedule%d.json", index - 1)
				let descriptor = ScheduleDescriptorType.init(start_date: descriptorDateString, schedule_path: schedulePath)
				scheduleDescriptors.append (descriptor)
				let newSchedule = ScheduleType (version: "UHF Schedule - v1", resources: [:], days: programs)
				self.schedules.append (newSchedule)
				self.schedulesDirty.append (true)
				startDate = Calendar.current.date (byAdding: .day, value: 7, to: startDate)!
			}
			
			for _ in 0...6 {
				
			}
			self.manifest = ManifestType (version: "UHF Channel - v1", schedules: scheduleDescriptors)
			self.markChannelDirty (true)
			
			// Force save.
			self.saveAsChannel (sender: sender)
		}
	}
	
	@IBAction func newChannelCancel (sender: AnyObject) {
		if let presentedViewController = self.presentedViewControllers?.first {
			self.dismiss (presentedViewController)
		}
	}
	
	@IBAction func openChannel (sender: AnyObject) {
		let openPanel = NSOpenPanel()
		openPanel.message = "Select the directory containing the schedule files:"
		openPanel.allowsMultipleSelection = false
		openPanel.canChooseDirectories = true
		openPanel.canChooseFiles = false
		openPanel.begin { (result) -> Void in
			if result == NSApplication.ModalResponse.OK {
				if let urlSelected = openPanel.url, self.openChannelFiles (urlSelected) {
					self.initialPopulateResourceDatabase ()
					self.resourceDatabaseTextField.stringValue = String (format: "%ld video resources in database.", self.resourceDatabase.count)
					self.schedulePaths.removeAll ()
					self.populateSchedulePathsArray ()
					self.updateUserInterface ()
					self.updateManifestInfo ()
					self.scheduleCollectionView.reloadData ()
					self.weeklyCollectionView.reloadData ()
					
					var dayCount = 0
					if let unwrappedManifest = self.manifest {
						for oneSchedule in self.schedules {
							dayCount = dayCount + oneSchedule.days.count
						}
						
						for _ in 1...unwrappedManifest.schedules.count {
							self.schedulesDirty.append (false)
						}
						
						if let listDescriptors = unwrappedManifest.lists {
							for (id, _) in listDescriptors {
								self.listsDirty[id] = false
							}
						}
					}
				} else {
					print ("Invalid Channel Directory.")
				}
			}
		}
	}
	
	@IBAction func saveChannel (sender: AnyObject) {
		self.writeChannel ()
	}
	
	@IBAction func saveAsChannel (sender: AnyObject) {
		let savePanel = NSSavePanel ()
		savePanel.allowedContentTypes = [UTType.json]
		savePanel.nameFieldStringValue = "manifest"
		savePanel.message = "Select the directory to create your channel:"
		savePanel.begin { (result) -> Void in
			if result == NSApplication.ModalResponse.OK {
				if let theURL = savePanel.url {
					let parentDirectory = theURL.deletingLastPathComponent ()
					self.channelDirectoryURL = URL (fileURLWithPath: parentDirectory.path, isDirectory: true)
					self.writeChannel ()
				}
			}
		}
	}
	
	@IBAction func importResources (sender: AnyObject) {
		print ("unimplemented")
	}
	
	@IBAction func exportResources (sender: AnyObject) {
		let savePanel = NSSavePanel ()
		savePanel.allowedContentTypes = [UTType.json]
		savePanel.begin { (result) -> Void in
			if result == NSApplication.ModalResponse.OK {
				if let theURL = savePanel.url {
					self.exportResourceDatabase (toURL: theURL)
				}
			}
		}
	}
	
	@IBAction func selectResourcePath (sender: AnyObject) {
		guard let channelURL = self.channelDirectoryURL else {
			return
		}
		var message = "Select a new file for the resource:"
		if let selectedResource = self.currentlySelectedResource (), let title = selectedResource.title {
			message = "Select a new file for resource: " + title
		}
		let openPanel = NSOpenPanel ()
		openPanel.allowsMultipleSelection = false
		openPanel.canChooseDirectories = false
		openPanel.canChooseFiles = true
		openPanel.message = message
		openPanel.begin { (result) -> Void in
			if result == NSApplication.ModalResponse.OK, let url = openPanel.url {
				self.setSelectedProgramPath (self.getRelativeFilePath (url, relativeTo: channelURL))
				self.scheduleCollectionView.reloadData ()
				if let selected = self.selectedProgram {
					self.updateProgramView (withProgram: selected)
				}
			}
		}
	}
	
	@IBAction func deleteProgram (sender: AnyObject) {
		self.deleteSelectedProgram ()
		self.schedulePaths.removeAll ()
		self.populateSchedulePathsArray ()
		self.contentTableView.reloadData()
	}
	
	@IBAction func setBOBD (sender: AnyObject) {
		self.presentAsSheet (self.setBOBDViewController)
		self.bobdTextField.stringValue = self.manifest?.beginning_of_broadcast_day ?? ""
	}
	
	@IBAction func setBOBDOkay (sender: AnyObject) {
		if let presentedViewController = self.presentedViewControllers?.first {
			let formatter = DateFormatter ()
			formatter.dateFormat = "HH:mm"
			if let bobdDate = formatter.date (from: self.bobdTextField.stringValue) {
				self.manifest?.beginning_of_broadcast_day = formatter.string (from: bobdDate)
				self.markChannelDirty (true)
				self.scheduleCollectionView.reloadData ()
				self.dismiss (presentedViewController)
			} else {
				NSSound.beep ()
			}
		}
	}
	
	@IBAction func setBOBDCancel (sender: AnyObject) {
		if let presentedViewController = self.presentedViewControllers?.first {
			self.dismiss (presentedViewController)
		}
	}
	
	@IBAction func loadContent (sender: AnyObject) {
		let openPanel = NSOpenPanel()
		openPanel.allowsMultipleSelection = false
		openPanel.canChooseDirectories = true
		openPanel.canChooseFiles = false
		openPanel.message = "Select a directory of video content:"
		openPanel.begin { (result) -> Void in
			if result == NSApplication.ModalResponse.OK {
				self.sourceResources.removeAll ()
				for oneURL in openPanel.urls {
					self.bookmarks.store (url: oneURL)
					do {
						let contentURLs = try FileManager.default.contentsOfDirectory (at: oneURL, includingPropertiesForKeys: nil)
						for oneContentURL in contentURLs {
							if let resource = self.newResource(fromURL: oneContentURL) {
								self.sourceResources.append (resource)
							}
						}
					} catch let error as NSError {
						print (error.localizedDescription)
					}
				}
				self.sourceResources.sort { (lhs: ResourceType, rhs: ResourceType) -> Bool in
					if let lhSeriesID = lhs.series_id, let rhSeriesID = rhs.series_id, lhSeriesID == rhSeriesID,
					   let lhOrder = lhs.order, let rhOrder = rhs.order {
						return lhOrder > rhOrder
					}
					else if let lhTitle = lhs.title, let rhTitle = rhs.title {
						return lhTitle.compare (rhTitle) == .orderedAscending
					} else {
						return lhs.path.compare (rhs.path) == .orderedAscending
					}
				}
				self.bookmarks.dump ()
				self.contentTableView.reloadData ()
			}
		}
		
		self.contentTableView.reloadData()
	}
	
	@IBAction func shuffleContent (sender: AnyObject) {
		self.sourceResources.shuffle ()
		self.contentTableView.reloadData()
	}
	
	@IBAction func newSeries (sender: AnyObject) {
		self.presentAsSheet (self.addSeriesViewController)
	}
	
	@IBAction func addSeriesOkay (sender: AnyObject) {
		if let presentedViewController = self.presentedViewControllers?.first {
			if let unwrappedManifest = self.manifest {
				if unwrappedManifest.series == nil {
					self.manifest?.series = [:]
				}
				let newSeries = SeriesType (title: self.addSeriesTitleTextField.stringValue, logo_path: nil)
				self.manifest?.series?[self.addSeriesIdentifierTextField.stringValue] = newSeries
				self.seriesDataSourceInvalid = true
				self.seriesTableView.reloadData ()
				self.markChannelDirty (true)
			}
			self.dismiss (presentedViewController)
		}
	}
	
	@IBAction func addSeriesCancel (sender: AnyObject) {
		if let presentedViewController = self.presentedViewControllers?.first {
			self.dismiss (presentedViewController)
		}
	}
	
	@IBAction func addSeriesLogo (sender: AnyObject) {
		guard let channelURL = self.channelDirectoryURL else {
			return
		}
		
		let openPanel = NSOpenPanel()
		openPanel.allowsMultipleSelection = false
		openPanel.canChooseDirectories = false
		openPanel.canChooseFiles = true
		openPanel.begin { (result) -> Void in
			if result == NSApplication.ModalResponse.OK {
				if let urlSelected = openPanel.url {
					let relativePath = self.getRelativeFilePath (urlSelected, relativeTo: channelURL)
					self.setSelectedSeriesLogoPath (relativePath)
					self.seriesLogoImageView.image = NSImage (contentsOf: urlSelected)
				}
			}
		}
	}
	
	@IBAction func deleteSeries (sender: AnyObject) {
		let alert = NSAlert ()
		alert.messageText = "Are you sure you want to delete the selected series?"
//		alert.informativeText = ""
		alert.addButton(withTitle: "OK")
		alert.addButton(withTitle: "Cancel")
		alert.alertStyle = .warning
		let returnValue = alert.runModal()
		if returnValue.rawValue == 1000 {	// BOGUS, 1000 and 1001 being returned, not .OK and .cancel
			self.deleteSelectedSeries ()
		}
	}
	
	@IBAction func newList (sender: AnyObject) {
		self.presentAsSheet (self.newListViewController)
	}
	
	@IBAction func newListOkay (sender: AnyObject) {
		if let presentedViewController = self.presentedViewControllers?.first {
			let title = self.newListTitleTextField.stringValue
			let identifier = self.newListIdentifierTextField.stringValue
			self.dismiss (presentedViewController)
			
			if identifier.count > 0, let channelURL = self.channelDirectoryURL {
				let savePanel = NSSavePanel ()
				savePanel.allowedContentTypes = [UTType.json]
				savePanel.begin { (result) -> Void in
					if result == NSApplication.ModalResponse.OK {
						if let theURL = savePanel.url {
							let newListInfo = ListInfoType (title: title, description: nil)
							let newList = ListType (version: "UHF List - v1", info: newListInfo, resources: [:])
							self.lists[identifier] = newList
							self.listsDirty[identifier] = true
							
							if let unwrappedManifest = self.manifest {
								if unwrappedManifest.lists == nil {
									self.manifest?.lists = [:]
								}
								
								let relativePath = self.getRelativeFilePath (theURL, relativeTo: channelURL)
								let newListDescriptor = ListDescriptorType (list_path: relativePath)
								self.manifest?.lists?[identifier] = newListDescriptor
								self.listsDataSourceInvalid = true
								self.listsContentDataSourceInvalid = true
								self.listsTableView.reloadData ()
								self.listContentTableView.reloadData ()
								self.markChannelDirty (true)
							}
						}
					}
				}
			}
		}
	}
	
	@IBAction func newListCancel (sender: AnyObject) {
		if let presentedViewController = self.presentedViewControllers?.first {
			self.dismiss (presentedViewController)
		}
	}
	
	/// Completely remove a list from the manifest. The list file itself is not deleted.
	
	@IBAction func removeList (sender: AnyObject) {
		let index = self.listsTableView.selectedRow
		if index >= 0 {
			let id = self.listsDataSource[index].id
			self.manifest?.lists?.removeValue(forKey: id)
			self.lists.removeValue(forKey: id)
			self.markChannelDirty (true)
			self.seriesDataSourceInvalid = true
			self.listsContentDataSourceInvalid = true
			self.listsTableView.reloadData ()
		}
	}
	
	/// Add content to the currently selected list.
	
	@IBAction func addListContent (sender: AnyObject) {
		let openPanel = NSOpenPanel ()
		openPanel.allowsMultipleSelection = true
		openPanel.canChooseDirectories = false
		openPanel.canChooseFiles = true
		openPanel.begin { (result) -> Void in
			if result == NSApplication.ModalResponse.OK {
				for oneURL in openPanel.urls {
					if let resource = self.newResource (fromURL: oneURL) {
						self.addResourceToSelectedList (resource: resource)
					}
				}
				self.seriesDataSourceInvalid = true		// BOGUS: not needed yet at this point.
				self.listsTableView.reloadData ()
				self.listContentTableView.reloadData ()
			}
		}
	}
	
	@IBAction func removeListContent (sender: AnyObject) {
		let listIndex = self.listsTableView.selectedRow
		if listIndex >= 0 {
			let identifier = self.listsDataSource[listIndex].id
			let selectedRows = self.listContentTableView.selectedRowIndexes
			for index in selectedRows {
				let resourceID = self.listsContentDataSource[index].id
				self.lists[identifier]?.resources.removeValue (forKey: resourceID)
			}
			self.listsDirty[identifier] = true
			self.seriesDataSourceInvalid = true		// BOGUS: not needed yet at this point.
			self.listsContentDataSourceInvalid = true
			self.listContentTableView.reloadData ()
		}
	}
	
	@IBAction func addThirtyMinutes (sender: AnyObject) {
		if self.view.window?.firstResponder == self.scheduleCollectionView {
			if let newStartTime = self.addMinutesToSelectedProgramStartTime (30) {
				self.selectedProgram?.start_time = newStartTime
				self.resourceTimeTextField.stringValue = newStartTime
			} else {
				NSSound.beep ()
			}
		}
	}
	
	@IBAction func subtractThirtyMinutes (sender: AnyObject) {
		if self.view.window?.firstResponder == self.scheduleCollectionView {
			if let newStartTime = self.addMinutesToSelectedProgramStartTime (-30) {
				self.selectedProgram?.start_time = newStartTime
				self.resourceTimeTextField.stringValue = newStartTime
			} else {
				NSSound.beep ()
			}
		}
	}
	
	@IBAction func addFiveMinutes (sender: AnyObject) {
		if self.view.window?.firstResponder == self.scheduleCollectionView {
			if let newStartTime = self.addMinutesToSelectedProgramStartTime (5) {
				self.selectedProgram?.start_time = newStartTime
				self.resourceTimeTextField.stringValue = newStartTime
			} else {
				NSSound.beep ()
			}
		}
	}
	
	@IBAction func subtractFiveMinutes (sender: AnyObject) {
		if self.view.window?.firstResponder == self.scheduleCollectionView {
			if let newStartTime = self.addMinutesToSelectedProgramStartTime (-5) {
				self.selectedProgram?.start_time = newStartTime
				self.resourceTimeTextField.stringValue = newStartTime
			} else {
				NSSound.beep ()
			}
		}
	}
	
	@IBAction func goPreviousWeek (sender: AnyObject) {
		if self.view.window?.firstResponder == self.scheduleCollectionView {
			if let previousProgram = self.programAWeekPriorToSelection () {
				self.selectProgram (selected: previousProgram)
				self.scheduleCollectionView.scrollToItems (at: [IndexPath (item: previousProgram.day_ordinal, section: 0)], scrollPosition: .centeredHorizontally)
			} else {
				NSSound.beep ()
			}
		}
	}
	
	@IBAction func goNextWeek (sender: AnyObject) {
		if self.view.window?.firstResponder == self.scheduleCollectionView {
			if let nextProgram = self.programAWeekFollowingSelection () {
				self.selectProgram (selected: nextProgram)
				self.scheduleCollectionView.scrollToItems (at: [IndexPath (item: nextProgram.day_ordinal, section: 0)], scrollPosition: .centeredHorizontally)
			} else {
				NSSound.beep ()
			}
		}
	}
	
	@IBAction func goToday (sender: AnyObject) {
		if let tabViewItem = self.manifestTabView.selectedTabViewItem, tabViewItem.identifier as! String == "schedules" {
			let iso8601Formatter = ISO8601DateFormatter ()
			iso8601Formatter.formatOptions = [.withFullDate]
			if let startDateString = self.manifest?.schedules.first?.start_date,
					let startDate = iso8601Formatter.date (from: startDateString) {
				let daysIntoSchedule: Int = Calendar.current.dateComponents ([.day], from: startDate, to: Date ()).day!
				self.scheduleCollectionView.scrollToItems (at: [IndexPath (item: daysIntoSchedule, section: 0)], scrollPosition: .centeredHorizontally)
			}
		}
	}
	
	@IBAction func offsetFiftyTwoWeeks (sender: AnyObject) {
		self.offsetSchedule (days: 364)
		self.markChannelDirty (true)
	}
	
	override func keyDown (with event: NSEvent) {
		if self.view.window?.firstResponder == self.scheduleCollectionView {
			if event.keyCode == 123 {
				if let previousProgram = self.programADayPriorToSelection () {
					self.selectProgram (selected: previousProgram)
					self.scheduleCollectionView.scrollToItems (at: [IndexPath (item: previousProgram.day_ordinal, section: 0)], scrollPosition: .centeredHorizontally)
				} else {
					NSSound.beep ()
				}
			} else if event.keyCode == 124 {
				if let nextProgram = self.programADayFollowingSelection () {
					self.selectProgram (selected: nextProgram)
					self.scheduleCollectionView.scrollToItems (at: [IndexPath (item: nextProgram.day_ordinal, section: 0)], scrollPosition: .centeredHorizontally)
				} else {
					NSSound.beep ()
				}
			} else if event.keyCode == 126 {
				if let previousProgram = self.programPriorToSelection () {
					self.selectProgram (selected: previousProgram)
					self.scheduleCollectionView.scrollToItems (at: [IndexPath (item: previousProgram.day_ordinal, section: 0)], scrollPosition: .centeredHorizontally)
				} else {
					NSSound.beep ()
				}
			} else if event.keyCode == 125 {
				if let nextProgram = self.programFollowingSelection () {
					self.selectProgram (selected: nextProgram)
					self.scheduleCollectionView.scrollToItems (at: [IndexPath (item: nextProgram.day_ordinal, section: 0)], scrollPosition: .centeredHorizontally)
				} else {
					NSSound.beep ()
				}
			} else {
				print(event.keyCode)
			}
		}
	}
	
	// MARK: - NSCollectionViewDelegate
	
	// MARK: - NSCollectionViewDataSource
	
	func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
		var count = 0
		
		if collectionView == self.scheduleCollectionView {
			if self.manifest != nil {
				for oneSchedule in self.schedules {
					count = count + oneSchedule.days.count
				}
			}
		} else if collectionView == self.weeklyCollectionView {
			count = 7
		}
		
		return count
	}
	
	func readableAtPath (path: String) -> Bool {
		let resourceURL = URL (fileURLWithPath: path, relativeTo: self.channelDirectoryURL)
		let exists = FileManager.default.isReadableFile (atPath: resourceURL.path)
		return exists
	}
	
	func collectionView (_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
		if collectionView == self.scheduleCollectionView {
			let item = collectionView.makeItem (withIdentifier:
					NSUserInterfaceItemIdentifier (rawValue: "com.UHFScheduler.scheduleCell"),
					for: indexPath)
			if let scheduleItem = item as? ScheduleCollectionViewItem {
				if let date = self.scheduleDate (dayOrdinal: indexPath.item) {
					let dateFormatter = DateFormatter ()
					dateFormatter.timeZone = TimeZone (abbreviation: "UTC")
					dateFormatter.dateFormat = "MM/dd/YY"
					let dateString = dateFormatter.string (from: date)
					scheduleItem.dateTextField.stringValue = dateString
					
					dateFormatter.dateFormat = "EEE"
					scheduleItem.dayTextField.stringValue = dateFormatter.string (from: date)
					
					var isToday = false
					if let utcTimezone = TimeZone (abbreviation: "UTC") {
						let timezoneDelta = TimeInterval (utcTimezone.secondsFromGMT (for: date) - TimeZone.current.secondsFromGMT (for: date))
						let convertedDate = date.addingTimeInterval (timezoneDelta)
						isToday = Calendar.current.isDateInToday (convertedDate)
					}
					scheduleItem.dateTextField.backgroundColor = isToday ? #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1) : #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
					scheduleItem.dayTextField.backgroundColor = isToday ? #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1) : #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
					
					if let scheduleIndex = self.schedulesIndex (dayOrdinal: indexPath.item) {
						let schedule = self.schedules[scheduleIndex]
						let programs = self.daysPrograms(dayOrdinal: indexPath.item)
						var scheduleDay:[ScheduleDayType] = []
						var failedToReadFile = false
						for oneProgram in programs {
							if let resource = schedule.resources[oneProgram.resource_id] {
								if resource.duration == 0 {
									let resourceURL = URL (fileURLWithPath: resource.path, relativeTo: self.channelDirectoryURL)
									let asset = AVAsset (url: resourceURL)
									let duration = asset.duration
									let durationTime = CMTimeGetSeconds (duration)
									if (durationTime == 0.0) && (self.blacklistedURLs.contains (resourceURL.path) == false) {
										failedToReadFile = true
									} else {
										self.setDurationForResource (scheduleIndex: scheduleIndex, id: oneProgram.resource_id,
												duration: Int (ceil (durationTime)))
									}
								}
								let pathLegit = self.readableAtPath (path: resource.path)
								let hasDescription = resource.description != nil && resource.description!.count > 0
								let dayProgram = ScheduleDayType (start_time: oneProgram.start_time, duration: resource.duration,
										title: self.displayTitle (forResource: resource), day_ordinal: indexPath.item,
										hasDescription: hasDescription, error: pathLegit == false)
								scheduleDay.append (dayProgram)
							}
						}
						
						scheduleItem.setSchedule (scheduleDay)
						scheduleItem.setSelectedProgram (nil)
						if let selection = self.selectedProgram, indexPath.item == selection.day_ordinal {
							scheduleItem.setSelectedProgram (selection)
						}
						
						scheduleItem.setBOBD (self.manifest?.beginning_of_broadcast_day)
						
						let dayIndex = Calendar.current.component (.weekday, from: date)
						if (dayIndex == 6) || (dayIndex == 7) {
							scheduleItem.containerView.fillColor = #colorLiteral(red: 0.9640509486, green: 0.9640509486, blue: 0.9640509486, alpha: 1)
						} else {
							scheduleItem.containerView.fillColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
						}
						
						if failedToReadFile {
							print ("Failed to get duration.")
							self.preflightResourceURLs (scheduleIndex: scheduleIndex, programs: programs)
						}
					}
					
					scheduleItem.containerView.delegate = self
				}
			}
			return item
		} else {	// weeklyCollectionView
			let item = collectionView.makeItem (withIdentifier:
					NSUserInterfaceItemIdentifier (rawValue: "weeklyCell"), for: indexPath)
			if let weeklyItem = item as? WeeklyCollectionViewItem {
				let dayNames = ["Sun", "Mon", "Tues", "Wed", "Thurs", "Fri", "Sat"]
				weeklyItem.dayTextField.stringValue = dayNames[indexPath.item]
				weeklyItem.dayTextField.backgroundColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
				if (indexPath.item == 0) || (indexPath.item == 6) {
					weeklyItem.containerView.fillColor = #colorLiteral(red: 0.9640509486, green: 0.9640509486, blue: 0.9640509486, alpha: 1)
				} else {
					weeklyItem.containerView.fillColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
				}
				
				if let listScheduleArray = self.manifest?.dotw_list_schedule, listScheduleArray.count > indexPath.item {
					weeklyItem.setListSchedule (listScheduleArray[indexPath.item])
				} else {
					weeklyItem.setListSchedule (nil)
				}
				weeklyItem.setWeekdayOrdinal (indexPath.item)
				
				weeklyItem.setSelectedProgram (nil)
				if let selection = self.selectedListProgram, indexPath.item == selection.weekday_ordinal {
					weeklyItem.setSelectedProgram (selection.listProgram)
				}
				
				weeklyItem.setBOBD (self.manifest?.beginning_of_broadcast_day)
				weeklyItem.containerView.delegate = self
			}
			return item
		}
	}
	
	func collectionView(_ collectionView: NSCollectionView, pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
		let item = NSPasteboardItem ()
		item.setString (String (indexPath.item), forType: .string)
		return item
	}
	
	func collectionView (_ collectionView: NSCollectionView, validateDrop draggingInfo: NSDraggingInfo,
			proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>,
			dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>) -> NSDragOperation {
		if collectionView == self.scheduleCollectionView {
			let itemIndex = proposedDropIndexPath.pointee.item
			if let oldIndex = self.wasDragDestinationIndex, oldIndex != itemIndex {
				if let item = collectionView.item (at: oldIndex) as? ScheduleCollectionViewItem {
					item.clearProposedDrop ()
					self.wasDragDestinationIndex = nil
				}
			}
			
			if let item = collectionView.item (at: itemIndex) as? ScheduleCollectionViewItem,
					let index = Int (draggingInfo.draggingPasteboard.string (forType: .string)!) {
				let localPoint = self.view.convert (draggingInfo.draggingLocation, to: collectionView)
				_ = item.proposedProgramDrop (self.sourceResources[index], yLocation: localPoint.y)
				self.wasDragDestinationIndex = itemIndex
			}
		}
		return .copy
	}
	
	func collectionView (_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, indexPath: IndexPath,
			dropOperation: NSCollectionView.DropOperation) -> Bool {
		if collectionView == self.scheduleCollectionView {
			if let oldIndex = self.wasDragDestinationIndex, oldIndex != indexPath.item {
				if let item = collectionView.item (at: oldIndex) as? ScheduleCollectionViewItem {
					item.clearProposedDrop ()
					self.wasDragDestinationIndex = nil
				}
			}
			
			if let item = collectionView.item (at: indexPath.item) as? ScheduleCollectionViewItem,
					let index = Int (draggingInfo.draggingPasteboard.string (forType: .string)!) {
				let localPoint = self.view.convert (draggingInfo.draggingLocation, to: collectionView)
				let rawResource = self.sourceResources[index]
				let resourceIdentifier = self.matchingResourceFromDatabase (rawResource)
				if let dropTime = item.proposedProgramDrop (self.sourceResources[index], yLocation: localPoint.y) {
					item.clearProposedDrop ()
					if let scheduleIndex = self.schedulesIndex (dayOrdinal: indexPath.item),
							let dayIndex = self.dayIndex (dayOrdinal: indexPath.item) {
						let longID = String (format: "%8@", UUID ().uuidString)
						let substringIndex = longID.index (longID.startIndex, offsetBy: 8)
						let idSubstring = longID[..<substringIndex]
						var identifier = String (idSubstring)
						if let unwrappedIdentifier = resourceIdentifier.identifier {
							identifier = unwrappedIdentifier
						}
						let newProgram = ProgramType (start_time: dropTime, resource_id: identifier)
						self.schedules[scheduleIndex].days[dayIndex].append (newProgram)
						self.schedules[scheduleIndex].days[dayIndex].sort (by: {$0.start_time < $1.start_time})
						let resource = resourceIdentifier.resource
						self.schedules[scheduleIndex].resources[identifier] = resource
						item.setSchedule (self.daysSchedule (dayOrdinal: indexPath.item))
						self.markScheduleDirty (scheduleIndex: scheduleIndex, dirty: true)
						let pathLegit = self.readableAtPath (path: resource.path)
						let dayProgram = ScheduleDayType (start_time: newProgram.start_time, duration: resource.duration,
								title: self.displayTitle (forResource: resource), day_ordinal: indexPath.item,
								hasDescription: true, error: pathLegit == false)
						self.selectProgram (selected: dayProgram)
						
						self.schedulePaths.removeAll ()
						self.populateSchedulePathsArray ()
						self.contentTableView.reloadData()
					}
				}
			}
		}
		
		return true
	}
	
	// MARK: - NSMenuItemValidation
	
	func validateMenuItem (_ menuItem: NSMenuItem) -> Bool {
		if menuItem.identifier == NSUserInterfaceItemIdentifier (rawValue: "new") {
			return self.manifest == nil
		} else if menuItem.identifier == NSUserInterfaceItemIdentifier (rawValue: "open") {
			return self.manifest == nil
		} else if menuItem.identifier == NSUserInterfaceItemIdentifier (rawValue: "save") {
			return self.channelIsDirty ()
		}
		
		return true
	}
	
	// MARK: - NSTabViewDelegate
	
	func tabView(_ tabView: NSTabView, shouldSelect tabViewItem: NSTabViewItem?) -> Bool {
		return self.manifest != nil
	}
	
	// MARK: - NSTableViewDataSource
	
	func numberOfRows (in tableView: NSTableView) -> Int {
		if tableView == self.contentTableView {
			return self.sourceResources.count
		} else if tableView == self.seriesTableView {
			if let series = self.manifest?.series, self.seriesDataSourceInvalid {
				self.seriesDataSource.removeAll ()
				for (oneKey, oneSeries) in series {
					var logoImage: NSImage? = nil
					if let logoPath = oneSeries.logo_path, let logoURL = URL (string: logoPath, relativeTo: self.channelDirectoryURL) {
						logoImage = NSImage (contentsOf: logoURL)
					}
					let seriesData = SeriesDataSourceType (id: oneKey, title: oneSeries.title, logo: logoImage)
					self.seriesDataSource.append (seriesData)
				}
				self.seriesDataSource.sort (by: {$0.title < $1.title })
				self.seriesDataSourceInvalid = false
			}
			return self.seriesDataSource.count
		} else if tableView == self.listsTableView {
			if let lists = self.manifest?.lists, self.listsDataSourceInvalid {
				self.listsDataSource.removeAll ()
				for (identifier, oneList) in lists {
					var listData = ListsDataSourceType (id: identifier, list_path: oneList.list_path)
					listData.title = self.lists[identifier]?.info?.title
					listData.description = self.lists[identifier]?.info?.description
					if let list = self.lists[identifier] {
						let pathSet : Set<String> = Set (list.resources.values.map {
							return $0.path
						})
						listData.uniquePathSet = pathSet
					}
					
					self.listsDataSource.append (listData)
				}
				self.listsDataSourceInvalid = false
			}
			return listsDataSource.count
		} else if tableView == self.listContentTableView {
			let index = self.listsTableView.selectedRow
			if index >= 0 {
				let listID = self.listsDataSource[index].id
				if let resources = self.lists[listID]?.resources, self.listsContentDataSourceInvalid {
					self.listsContentDataSource.removeAll ()
					for (identifier, oneResource) in resources {
						var listContentData = ListsContentDataSourceType (id: identifier, path: oneResource.path, duration: oneResource.duration)
						listContentData.title = oneResource.title
						self.listsContentDataSource.append (listContentData)
					}
					self.listsContentDataSourceInvalid = false
				}
				return self.listsContentDataSource.count
			}
		}
		
		return 0
	}
	
	func tableView (_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		if tableView == self.contentTableView {
			if tableColumn?.identifier.rawValue == "title" {
				if let cell = tableView.makeView (withIdentifier: NSUserInterfaceItemIdentifier (rawValue: "contentTitleCell"), owner: nil) as? NSTableCellView {
					var cellText = self.sourceResources[row].title ?? "No Title"
					if self.schedulePaths.contains (self.sourceResources[row].path) {
						cellText = "🔹 " + cellText
					}
					cell.textField?.stringValue = cellText
					return cell
				}
			} else if tableColumn?.identifier.rawValue == "duration" {
				if let cell = tableView.makeView (withIdentifier: NSUserInterfaceItemIdentifier (rawValue: "contentDurationCell"), owner: nil) as? NSTableCellView {
					cell.textField?.stringValue = self.durationString (fromDuration: self.sourceResources[row].duration)
					return cell
				}
			}
		} else if tableView == self.seriesTableView {
			if tableColumn?.identifier.rawValue == "title" {
				if let cell = tableView.makeView (withIdentifier: NSUserInterfaceItemIdentifier (rawValue: "seriesTitleCell"), owner: nil) as? NSTableCellView {
					cell.textField?.stringValue = self.seriesDataSource[row].title
					return cell
				}
			} else if tableColumn?.identifier.rawValue == "id" {
				if let cell = tableView.makeView (withIdentifier: NSUserInterfaceItemIdentifier (rawValue: "seriesIDCell"), owner: nil) as? NSTableCellView {
					cell.textField?.stringValue = self.seriesDataSource[row].id
					return cell
				}
			} else if tableColumn?.identifier.rawValue == "logo" {
				if let cell = tableView.makeView (withIdentifier: NSUserInterfaceItemIdentifier (rawValue: "seriesLogoCell"), owner: self) as? NSTableCellView {
					cell.imageView?.image = self.seriesDataSource[row].logo
					return cell
				}
			}
		} else if tableView == self.listsTableView {
			if tableColumn?.identifier.rawValue == "title" {
				if let cell = tableView.makeView (withIdentifier: NSUserInterfaceItemIdentifier (rawValue: "listsTitleCell"), owner: nil) as? NSTableCellView {
					cell.textField?.stringValue = self.listsDataSource[row].title ?? ""
					return cell
				}
			} else if tableColumn?.identifier.rawValue == "id" {
				if let cell = tableView.makeView (withIdentifier: NSUserInterfaceItemIdentifier (rawValue: "listsIDCell"), owner: nil) as? NSTableCellView {
					if let listDescriptors = self.manifest?.lists, listDescriptors.count > row {
						cell.textField?.stringValue = self.listsDataSource[row].id
						return cell
					}
				}
			} else if tableColumn?.identifier.rawValue == "resources" {
				if let cell = tableView.makeView (withIdentifier: NSUserInterfaceItemIdentifier (rawValue: "listsResourcesCell"), owner: nil) as? NSTableCellView {
					if self.lists.count > row {
						let id = self.listsDataSource[row].id
						if let oneList = self.lists[id] {
							cell.textField?.stringValue = String (oneList.resources.count)
							return cell
						}
					}
				}
			}
		} else if tableView == self.listContentTableView {
			let index = self.listsTableView.selectedRow
			if index >= 0 {
				if tableColumn?.identifier.rawValue == "title" {
					if let cell = tableView.makeView (withIdentifier: NSUserInterfaceItemIdentifier (rawValue: "listContentTitleCell"),
							owner: nil) as? NSTableCellView {
						var title = self.listsContentDataSource[row].title ?? "Untitled"
						if self.readableAtPath (path: self.listsContentDataSource[row].path) == false {
							title = "⚠️ " + title
						}
						cell.textField?.stringValue = title
						return cell
					}
				} else if tableColumn?.identifier.rawValue == "duration" {
					if let cell = tableView.makeView (withIdentifier: NSUserInterfaceItemIdentifier (rawValue: "listContentDurationCell"),
							owner: nil) as? NSTableCellView {
						let duration = self.listsContentDataSource[row].duration
						cell.textField?.stringValue = self.durationString (fromDuration: duration)
						return cell
					}
				}
			}
		}
		
		return nil
	}
	
	func tableView (_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
		if tableView == self.contentTableView {
			let item = NSPasteboardItem ()
			item.setString (String(row), forType: .string)
			return item
		}
		return nil
	}
	
	// MARK: - NSTableViewDelegate
	
	func tableViewSelectionDidChange (_ notification: Notification) {
		if let tableView = notification.object as? NSTableView {
			if tableView == self.seriesTableView {
				if tableView.selectedRow >= 0 {
					self.updateSeriesInfo (self.seriesDataSource[tableView.selectedRow])
				} else {
					self.updateSeriesInfo (nil)
				}
				self.seriesTitleTextField.isEnabled = self.seriesTableView.selectedRow >= 0
				self.assignSeriesLogoButton.isEnabled = self.seriesTableView.selectedRow >= 0
				self.deleteSeriesButton.isEnabled = self.seriesTableView.selectedRow >= 0
			} else if tableView == self.listsTableView {
				if tableView.selectedRow >= 0 {
					self.updateListInfo (self.listsDataSource[tableView.selectedRow])
				} else {
					self.updateListInfo (nil)
				}
				self.listsContentDataSourceInvalid = true
				self.listContentTableView.reloadData ()
				self.removeListButton.isEnabled = tableView.selectedRow >= 0
				self.addListContentButton.isEnabled = tableView.selectedRow >= 0
				self.removeListContentButton.isEnabled = listsTableView.selectedRow >= 0 && self.listContentTableView.numberOfSelectedRows > 0
			} else if tableView == self.listContentTableView {
				self.removeListContentButton.isEnabled = listsTableView.selectedRow >= 0 && self.listContentTableView.numberOfSelectedRows > 0
			}
		}
	}
	
	func tableView (_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
		guard let sortDescriptor = tableView.sortDescriptors.first else {
			return
		}
		
		if tableView == self.contentTableView {
			if sortDescriptor.key == "title" {
				if sortDescriptor.ascending {
					self.sourceResources.sort (by: {$0.title ?? "No Title" < $1.title ?? "No Title"})
				} else {
					self.sourceResources.sort (by: {$0.title ?? "No Title" > $1.title ?? "No Title"})
				}
				tableView.reloadData()
			} else if sortDescriptor.key == "duration" {
				if sortDescriptor.ascending {
					self.sourceResources.sort (by: {$0.duration < $1.duration})
				} else {
					self.sourceResources.sort (by: {$0.duration > $1.duration})
				}
				tableView.reloadData()
			}
		} else if tableView == self.listContentTableView {
			let index = self.listsTableView.selectedRow
			if index >= 0 {
				if sortDescriptor.key == "title" {
					if sortDescriptor.ascending {
						self.listsContentDataSource.sort(by: {$0.title ?? "No Title" < $1.title ?? "No Title"})
					} else {
						self.listsContentDataSource.sort (by: {$0.title ?? "No Title" > $1.title ?? "No Title"})
					}
					tableView.reloadData ()
				} else if sortDescriptor.key == "duration" {
					if sortDescriptor.ascending {
						self.listsContentDataSource.sort (by: {
							$0.duration < $1.duration
						})
					} else {
						self.listsContentDataSource.sort (by: {
							$0.duration > $1.duration
						})
					}
					tableView.reloadData ()
				}
			}
		}
	}
	
	// MARK: - NSTextFieldDelegate
	
	func handleTextFieldEditing (_ textField: NSTextField) {
		if textField == self.channelInfoTitleTextField {
			self.setChannelInfoTitle (textField.stringValue)
		} else if textField == self.resourceYearTextField {
			self.setSelectedProgramYear (textField.stringValue)
		} else if textField == self.channelInfoDescriptionTextField {
			self.setChannelInfoDescription (textField.stringValue)
		} else if textField == self.resourceTimeTextField {
			textField.stringValue = self.setSelectedProgramStartTime (textField.stringValue)
		} else if textField == self.resourceIdentifierTextField {
			if self.setSelectedProgramResourceIdentifier (textField.stringValue) == false {
				NSSound.beep ()
			}
		} else if textField == self.resourceSeriesIdentifierTextField {
			self.setSelectedProgramSeriesIdentifier (textField.stringValue)
		} else if textField == self.resourceTitleTextField {
			self.setSelectedProgramTitle (textField.stringValue)
		} else if textField == self.resourceDescriptionTextField {
			self.setSelectedProgramDescription (textField.stringValue)
		} else if textField == self.seriesTitleTextField {
			self.setSelectedSeriesTitle (textField.stringValue)
		} else if textField == self.resourceStartOffsetTextField {
			textField.stringValue = self.setSelectedStartOffset (textField.stringValue)
		} else if textField == self.resourceOrderTextField {
			self.setSelectedProgramOrder (textField.stringValue)
		} else if textField == self.listTitleTextField {
			self.setSelectedListTitle (textField.stringValue)
		} else if textField == self.listDescriptionTextField {
			self.setSelectedListDescription (textField.stringValue)
		} else if textField == self.seriesIdentifierTextField {
			self.setSelectedSeriesIdentifier (textField.stringValue)
		}
		
		// Indicate dirty text field handled.
		if self.dirtyTextField == textField {
			self.dirtyTextField = nil
		}
	}
	
	func controlTextDidChange (_ obj: Notification) {
		if let textField = obj.object as? NSTextField {
			self.dirtyTextField = textField
		}
	}
	
	func controlTextDidEndEditing (_ obj: Notification) {
		if let textField = obj.object as? NSTextField {
			self.handleTextFieldEditing (textField)
		}
	}
	
	// MARK: - ListProgramSelectedDelegate
	
	func listProgramSelected (_ dayView: WeeklyDayView, selected: ListProgramType?) {
		if let unwrappedSelected = selected {
			let selectedList = SelectedListProgramType.init(weekday_ordinal: dayView.weekdayOrdinal, listProgram: unwrappedSelected)
			self.selectListProgram (selected: selectedList)
		}
	}
	
	// MARK: - ProgramSelectedDelegate
	
	func programSelected (_ dayView: CalendarDayView, selected: ScheduleDayType) {
		self.view.window?.makeFirstResponder (self.scheduleCollectionView)
		self.selectProgram (selected: selected)
	}
}
