import Cocoa

class Document: NSDocument, NSWindowDelegate {
	let web = WebViewer()
	
	override var isInViewingMode: Bool {true}
	override nonisolated class var autosavesInPlace: Bool {true}
	
	override func makeWindowControllers() {
		let window = NSWindow(contentViewController: web)
		addWindowController(NSWindowController(window: window))
		let w = UserDefaults.standard.integer(forKey: "winSizeW")
		let h = UserDefaults.standard.integer(forKey: "winSizeH")
		window.setContentSize(NSSize(width: w > 0 ? w : 800, height: h > 0 ? h : 600))
		window.makeKeyAndOrderFront(nil)
		window.delegate = self
	}
	
	func windowDidResize(_ notification: Notification) {
		let sz = (notification.object as! NSWindow).frame.size
		UserDefaults.standard.set(Int(sz.width), forKey: "winSizeW")
		UserDefaults.standard.set(Int(sz.height), forKey: "winSizeH")
	}
	
	override nonisolated func read(from url: URL, ofType typeName: String) throws {
		try MainActor.assumeIsolated {
			try web.load(fromFile: url)
			try watchForChanges(url)
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
}

