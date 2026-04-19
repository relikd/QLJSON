import Cocoa
import Quartz

class PreviewViewController: WebViewer, QLPreviewingController {
	func preparePreviewOfFile(at url: URL) async throws {
		try load(fromFile: url)
	}
}
