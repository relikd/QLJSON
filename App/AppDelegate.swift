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
			if let url = UserDefaults.standard.url(forKey: "defaultApp") {
				menu.items.first!.title = "Last Used (\(url.nameWithoutExt))"
			} else {
				menu.items.first!.title = "Last Used"
			}
			guard menu.items.count == 2 else {
				return // populate only once
			}
			let me = Bundle.main.bundleURL
			let apps = appsCanOpen(".json").filter { $0 != me }.sortedByLastName()
			for appUrl in apps {
				let item = menu.addItem(withTitle: appUrl.nameWithoutExt, action: #selector(Document.openInEditor), keyEquivalent: "")
				item.representedObject = appUrl
			}
		default: break
		}
	}
}


// MARK: Helper

extension Array where Element == URL {
	/// Case-insensitive compare of `lastPathComponent`.
	func sortedByLastName() -> [Element] {
		sorted { $0.lastPathComponent.localizedLowercase < $1.lastPathComponent.localizedLowercase }
	}
}

extension URL {
	/// `deletingPathExtension().lastPathComponent`
	var nameWithoutExt: String { deletingPathExtension().lastPathComponent }
}

/// Find all default applications for handling filetype.
func appsCanOpen(_ ext: String) -> [URL] {
	let tmp = URL(string: "a." + ext, relativeTo: FileManager.default.temporaryDirectory)!
	FileManager.default.createFile(atPath: tmp.path, contents: nil)
	defer {
		try? FileManager.default.removeItem(at: tmp)
	}
	if #available(macOS 12.0, *) {
		return NSWorkspace.shared.urlsForApplications(toOpen: tmp)
	} else if let x = LSCopyApplicationURLsForURL(tmp as CFURL, .all) {
		return x.takeRetainedValue() as? [URL] ?? []
	}
	return []
}
