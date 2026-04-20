import Cocoa

class Document: NSDocument, NSWindowDelegate {
	let web = WebViewer()
	
	override var isInViewingMode: Bool {true}
	override nonisolated class var autosavesInPlace: Bool {true}
	
	override func makeWindowControllers() {
		let window = NSWindow(contentViewController: web)
		addWindowController(NSWindowController(window: window))
		restoreWindowSize(window)
		window.makeKeyAndOrderFront(nil)
		window.delegate = self
	}
	
	func windowDidResize(_ notification: Notification) {
		persistWindowSize(notification.object as! NSWindow)
	}
	
	override nonisolated func read(from url: URL, ofType typeName: String) throws {
		try MainActor.assumeIsolated {
			try web.load(fromFile: url)
			try watchForChanges(url)
		}
	}
	
	// MARK: - Window resize
	
	/// Save current window size to user-defaults
	func persistWindowSize(_ win: NSWindow) {
		UserDefaults.standard.set(Int(win.frame.width), forKey: "winSizeW")
		UserDefaults.standard.set(Int(win.frame.height), forKey: "winSizeH")
	}
	
	/// Restore previous window size
	func restoreWindowSize(_ win: NSWindow) {
		let w = UserDefaults.standard.integer(forKey: "winSizeW")
		let h = UserDefaults.standard.integer(forKey: "winSizeH")
		if w > 0 && h > 0 {
			win.setFrame(CGRect(origin: win.frame.origin, size: .init(width: w, height: h)), display: true)
		}
	}
	
	// MARK: - File change watcher
	
	deinit {
		watcher?.cancel()
	}
	
	var watcher: DispatchSourceFileSystemObject? = nil
	
	func watchForChanges(_ url: URL) throws {
		let fh = try FileHandle(forReadingFrom: url)
		watcher = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fh.fileDescriptor, eventMask: .write)
		watcher!.setCancelHandler {
			try? fh.close()
		}
		watcher!.setEventHandler { [unowned self] in
			do {
				try self.web.load(fromFile: url)
			} catch {
				self.watcher?.cancel()
			}
		}
		watcher!.resume()
	}
	
	// MARK: - Main Menu
	
	@IBAction func openInEditor(_ sender: NSMenuItem) {
		let appURL: URL
		if let url = sender.representedObject as? URL {
			UserDefaults.standard.set(url, forKey: "defaultApp")
			appURL = url
		} else if let url = UserDefaults.standard.url(forKey: "defaultApp") {
			appURL = url
		} else {
			return
		}
		NSWorkspace.shared.open([fileURL!], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration())
	}
}

