import Foundation

enum CaptureMode {
    case interactive        // -i (region selection)
    case window             // -iw (window selection)
    case fullScreen         // (no flags)
    case app(windowID: Int, bounds: (x: Int, y: Int, w: Int, h: Int)) // -l <windowID>, fallback to -R
    case rect(x: Int, y: Int, w: Int, h: Int) // -R x,y,w,h
}

enum CaptureError: Error, CustomStringConvertible {
    case processError(String)
    case emptyCapture
    case invalidRect
    case userCancelled

    var description: String {
        switch self {
        case .processError(let msg): return "Capture failed: \(msg)"
        case .emptyCapture: return "Capture produced empty file (check Screen Recording permission)"
        case .invalidRect: return "Invalid rectangle: width and height must be positive"
        case .userCancelled: return "Capture cancelled by user"
        }
    }
}

enum Capturer {
    static func capture(mode: CaptureMode) throws -> Data {
        if case .rect(_, _, let w, let h) = mode, w <= 0 || h <= 0 {
            throw CaptureError.invalidRect
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("shot-\(UUID().uuidString).png")

        defer { try? FileManager.default.removeItem(at: tempURL) }

        switch mode {
        case .interactive:
            return try runScreencapture(["-i", tempURL.path], tempURL: tempURL, interactive: true)
        case .window:
            return try runScreencapture(["-iw", tempURL.path], tempURL: tempURL, interactive: true)
        case .fullScreen:
            return try runScreencapture([tempURL.path], tempURL: tempURL)
        case .app(let windowID, let bounds):
            // Try -l first, fallback to -R if capture fails or produces empty file
            if let data = try? runScreencapture(["-l", String(windowID), tempURL.path], tempURL: tempURL),
               !data.isEmpty {
                return data
            }
            try? FileManager.default.removeItem(at: tempURL)
            return try runScreencapture(["-R", "\(bounds.x),\(bounds.y),\(bounds.w),\(bounds.h)", tempURL.path], tempURL: tempURL)
        case .rect(let x, let y, let w, let h):
            return try runScreencapture(["-R", "\(x),\(y),\(w),\(h)", tempURL.path], tempURL: tempURL)
        }
    }

    private static func runScreencapture(_ args: [String], tempURL: URL, interactive: Bool = false) throws -> Data {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = args

        let pipe = Pipe()
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            if interactive { throw CaptureError.userCancelled }
            let stderr = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw CaptureError.processError(stderr)
        }

        guard FileManager.default.fileExists(atPath: tempURL.path) else {
            throw CaptureError.emptyCapture
        }

        let data = try Data(contentsOf: tempURL)
        if data.isEmpty {
            throw CaptureError.emptyCapture
        }

        return data
    }
}
