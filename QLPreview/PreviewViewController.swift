import Cocoa
import Quartz
import WebKit

class PreviewViewController: NSViewController, QLPreviewingController {
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
	
	func preparePreviewOfFile(at url: URL) async throws {
		let jsonFile = try String(contentsOf: url, encoding: .utf8)
		let html = """
<!DOCTYPE html>
<html>
<head>
 <meta content="text/html; charset=utf-8" http-equiv="Content-Type" />
 <style>\(try self.bundleFile(filename: "style", ext: "css"))</style>
 <script>\(try self.bundleFile(filename: "script", ext: "js"))</script>
</head>
<body onload="init()">
 <script id="json" type="application/json">\(jsonFile)</script>
</body>
</html>
"""
		
		// sure, we could use `WKWebView`, but that requires the `com.apple.security.network.client` entitlement
		//let web = WKWebView(frame: self.view.bounds)
		let web = WebView(frame: self.view.bounds)
		web.autoresizingMask = [.width, .height]
		self.view.addSubview(web)
		web.mainFrame.loadHTMLString(html, baseURL: nil)  // WebView
		//web.loadHTMLString(html, baseURL: nil)  // WKWebView
	}
}
