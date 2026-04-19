import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
	}
	
	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
	
	func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
		return true
	}
	
	// MARK: Main Menu
	
	// only selected menus have the delegate set
	func menuNeedsUpdate(_ menu: NSMenu) {
		switch menu.identifier {
		case .init(rawValue: "open-in-app"):
			if menu.items.count == 1 { // populate once
				let me = Bundle.main.bundleURL
				let apps = appURLs().filter { $0 != me }//.sorted { $0.lastPathComponent < $1.lastPathComponent }
				for appUrl in apps {
					let item = menu.addItem(withTitle: String(appUrl.lastPathComponent.dropLast(4)), action: #selector(Document.openInEditor), keyEquivalent: "")
					item.representedObject = appUrl
				}
			}
			break
		default: break
		}
	}
	
	/// Find all default applications for handling JSON files
	func appURLs() -> [URL] {
		if #available(macOS 12.0, *) {
			return NSWorkspace.shared.urlsForApplications(toOpen: .json)
		} else {
			let tmp = URL(string: "a.json", relativeTo: FileManager.default.temporaryDirectory)!
			FileManager.default.createFile(atPath: tmp.path, contents: nil)
			defer {
				try? FileManager.default.removeItem(at: tmp)
			}
			if let x = LSCopyApplicationURLsForURL(tmp as CFURL, .all) {
				return x.takeRetainedValue() as? [URL] ?? []
			}
			return []
		}
	}
}
