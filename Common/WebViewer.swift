import WebKit

class WebViewer: NSViewController {
	// sure, we could use `WKWebView`, but that requires the `com.apple.security.network.client` entitlement
	let web = WebView()
	var url: URL? = nil
	
	override func loadView() {
		self.view = NSView(frame: NSMakeRect(0, 0, 800, 600))
	}
	
	override func viewDidLoad() {
		self.web.frame = self.view.bounds
		self.web.autoresizingMask = [.width, .height]
		self.web.drawsBackground = false
		self.view.addSubview(self.web)
	}
	
	func load(fromFile url: URL) throws {
		self.url = url
		try self.reload()
	}
	
	func reload() throws {
		guard let url else {
			return
		}
		let html = _html(try _body(url))
		self.web.mainFrame.loadHTMLString(html, baseURL: nil) // WebView
		//self.view.loadHTMLString(html, baseURL: nil) // WKWebView
	}
	
	// MARK: - Content
	
	private func _body(_ url: URL) throws -> String {
		let size = try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber
		// supports files up to 1MB (else the html+js will take too long to process)
		guard (size?.uint64Value ?? 0) < 1_000_000 else {
			return """
<body><p class="error">File too large</p></body>
"""
		}
		let scrollTo = web.mainFrame.domDocument.documentElement.scrollTop
		let jsonFile = try String(contentsOf: url, encoding: .utf8)
		return """
<body onload="init(\(scrollTo))">
<script id="json" type="application/json">\(jsonFile)</script>
</body>
"""
	}
	
	private func _html(_ body: String) -> String {
		"""
<!DOCTYPE html>
<html>
<head>
 <meta content="text/html; charset=utf-8" http-equiv="Content-Type" />
 <style>\(bundleFile(filename: "style", ext: "css"))</style>
 <script>\(bundleFile(filename: "script", ext: "js"))</script>
</head>
\(body)
</html>
"""
	}
}

// MARK: - Extensions

extension URL {
	/// Folder for user modified html templates
	static let UserModDir: URL? =
		FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
}

/// Load resource file either from user documents dir (if exists) or app bundle (default).
func bundleFile(filename: String, ext: String) -> URL {
	if let userFile = URL.UserModDir?.appendingPathComponent(filename + "." + ext, isDirectory: false),
	   FileManager.default.fileExists(atPath: userFile.path) {
		return userFile
	}
	return Bundle.main.url(forResource: filename, withExtension: ext)!
}
