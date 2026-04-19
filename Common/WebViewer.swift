import WebKit

func bundleFile(filename: String, ext: String) throws -> String {
	if let appSupport = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
		let override = appSupport.appendingPathComponent(filename + "." + ext)
		if FileManager.default.fileExists(atPath: override.path) {
			return try String(contentsOfFile: override.path, encoding: .utf8)
		}
	}
	// else, load bundle file
	let path = Bundle.main.path(forResource: filename, ofType: ext)
	return try String(contentsOfFile: path!, encoding: .utf8)
}

class WebViewer: NSViewController {
	// sure, we could use `WKWebView`, but that requires the `com.apple.security.network.client` entitlement
	let web = WebView()
	
	override func viewDidLoad() {
		self.web.frame = self.view.bounds
		self.web.autoresizingMask = [.width, .height]
		self.web.drawsBackground = false
		self.view.addSubview(self.web)
	}
	
	func load(html: String) {
		self.web.mainFrame.loadHTMLString(html, baseURL: nil)  // WebView
		//self.view.loadHTMLString(html, baseURL: nil)  // WKWebView
	}
	
	func load(fromFile: URL) throws {
		let jsonFile = try String(contentsOf: fromFile, encoding: .utf8)
		self.load(html: """
<!DOCTYPE html>
<html>
<head>
 <meta content="text/html; charset=utf-8" http-equiv="Content-Type" />
 <style>\(try bundleFile(filename: "style", ext: "css"))</style>
 <script>\(try bundleFile(filename: "script", ext: "js"))</script>
</head>
<body onload="init()">
 <script id="json" type="application/json">\(jsonFile)</script>
</body>
</html>
""")
	}
}
