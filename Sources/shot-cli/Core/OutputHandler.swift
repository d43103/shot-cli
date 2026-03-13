import AppKit
import Foundation

enum OutputHandler {
    static func toBase64(_ data: Data) -> String {
        data.base64EncodedString()
    }

    @discardableResult
    static func saveToFile(_ data: Data, path: String?) throws -> String {
        let targetPath: String
        if let path = path {
            targetPath = (path as NSString).expandingTildeInPath
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd-HHmmss"
            let timestamp = formatter.string(from: Date())
            let desktop = (NSHomeDirectory() as NSString).appendingPathComponent("Desktop")
            targetPath = (desktop as NSString).appendingPathComponent("shot-cli-\(timestamp).png")
        }

        try data.write(to: URL(fileURLWithPath: targetPath))
        return targetPath
    }

    static func copyToClipboard(_ data: Data) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(data, forType: .png)
    }
}
