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
		DragDropToOpenOverlay.onView(web.view)
	}
	
	func windowDidResize(_ notification: Notification) {
		persistWindowSize(notification.object as! NSWindow)
	}
	
	override nonisolated func read(from url: URL, ofType typeName: String) throws {
		try MainActor.assumeIsolated {
			try _reload(url)
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
	
	@IBAction func reloadDocument(_ sender: NSMenuItem) {
		if let url = self.fileURL ?? web.url {
			try? _reload(url)
		}
	}
	
	
	// MARK: - File change watcher
	
	var watcher: FileWatcher? = nil // auto-closed on deinit
	
	private func _reload(_ url: URL) throws {
		try web.load(fromFile: url) // if url unchanged, only reload
		watcher = try? FileWatcher(url) { [unowned self] in
			try? self.web.reload()
		}
	}
}


/// - Most editors will trigger the `.write` event.
/// - VIM triggers the `.rename` event and replaces the old file with a new one -> thus the need for `rebuild()`.
/// - Xcode triggers the `.delete` event and calls `Document.read()` again (which creates a new watcher).
class FileWatcher {
	private let url: URL
	private let closure: () -> Void
	private var watcher: DispatchSourceFileSystemObject
	private var prevTs = Date().timeIntervalSince1970
	private var errCount = 0
	
	init(_ url: URL, closure: @escaping () -> Void) throws {
		self.url = url
		self.closure = closure
		self.watcher = try Self.makeHandler(url)
		self.watcher.setEventHandler(handler: self.onTrigger)
	}
	
	deinit {
		watcher.cancel()
	}
	
	static func makeHandler(_ url: URL) throws -> DispatchSourceFileSystemObject {
		let fh = try FileHandle(forReadingFrom: url)
		let handler = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fh.fileDescriptor, eventMask: [.write, .rename, .delete], queue: .main)
		handler.setCancelHandler { try? fh.close() }
		handler.activate()
		return handler
	}
	
	private func rebuild() {
		do {
			watcher = try Self.makeHandler(url)
			watcher.setEventHandler(handler: self.onTrigger)
			errCount = 0
			self.closure()
		} catch {
			errCount += 1
			if errCount > 20 {
				return
			}
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
				self.rebuild()
			}
		}
	}
	
	private func onTrigger() {
		if watcher.data.contains(.rename) {
			watcher.cancel()
			rebuild()
		} else if watcher.data.contains(.delete) {
			watcher.cancel()
		} else {
			let newTs = Date().timeIntervalSince1970
			if newTs - prevTs > 0.2 {
				prevTs = newTs
				self.closure()
			}
		}
	}
}


// MARK: - Drag-drop open files

class DragDropToOpenOverlay: NSView {
	static func onView(_ view: NSView) {
		let v = DragDropToOpenOverlay(frame: view.bounds)
		v.autoresizingMask = [.width, .height]
		v.registerForDraggedTypes([.fileURL])
		view.addSubview(v)
	}
	
	override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
		return .generic
	}
	
	override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
		if let files = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] {
			NSWorkspace.shared.open(files, withApplicationAt: Bundle.main.bundleURL, configuration: NSWorkspace.OpenConfiguration())
			return true
		}
		return false
	}
}
