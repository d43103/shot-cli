import ArgumentParser
import Foundation

struct CaptureResult {
    let data: Data
    let app: String?
    let title: String?
}

enum CaptureCommand {
    static func run(
        window: Bool,
        full: Bool,
        apps: [String],
        rect: String?,
        file: Bool,
        output: String?,
        clipboard: Bool,
        json: Bool
    ) throws {
        var results: [CaptureResult] = []

        if !apps.isEmpty {
            for appName in apps {
                let windows = WindowManager.findWindows(app: appName)
                guard let target = windows.first else {
                    suggestSimilarApps(query: appName)
                    throw ExitCode(2)
                }

                let data = try Capturer.capture(mode: .app(
                    windowID: target.id,
                    bounds: (x: target.x, y: target.y, w: target.w, h: target.h)
                ))
                results.append(CaptureResult(data: data, app: target.app, title: target.title))
            }
        } else {
            let mode: CaptureMode
            if window {
                mode = .window
            } else if full {
                mode = .fullScreen
            } else if let rect = rect {
                mode = try parseRect(rect)
            } else {
                mode = .interactive
            }

            let data = try Capturer.capture(mode: mode)
            results.append(CaptureResult(data: data, app: nil, title: nil))
        }

        try handleOutput(results: results, file: file, output: output, clipboard: clipboard, json: json)
    }

    private static func parseRect(_ str: String) throws -> CaptureMode {
        let parts = str.split(separator: ",").compactMap { Int($0) }
        guard parts.count == 4 else {
            throw ValidationError("--rect requires format: x,y,w,h (e.g., 0,25,1440,875)")
        }
        return .rect(x: parts[0], y: parts[1], w: parts[2], h: parts[3])
    }

    private static func handleOutput(
        results: [CaptureResult],
        file: Bool,
        output: String?,
        clipboard: Bool,
        json: Bool
    ) throws {
        if json {
            try printJSON(results: results)
        } else {
            for result in results {
                print(OutputHandler.toBase64(result.data))
            }
        }

        if file {
            for result in results {
                let path: String? = results.count == 1 ? output : nil
                let saved = try OutputHandler.saveToFile(result.data, path: path)
                FileHandle.standardError.write("Saved: \(saved)\n".data(using: .utf8)!)
            }
        }

        if clipboard, let last = results.last {
            OutputHandler.copyToClipboard(last.data)
            FileHandle.standardError.write("Copied to clipboard\n".data(using: .utf8)!)
        }
    }

    private static func printJSON(results: [CaptureResult]) throws {
        struct JSONResult: Encodable {
            let index: Int
            let app: String?
            let title: String?
            let base64: String
        }

        let items = results.enumerated().map { i, r in
            JSONResult(
                index: i,
                app: r.app,
                title: r.title,
                base64: OutputHandler.toBase64(r.data)
            )
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(items)
        print(String(data: data, encoding: .utf8)!)
    }

    private static func suggestSimilarApps(query: String) {
        let all = WindowManager.listWindows()
        let queryPrefix = String(query.lowercased().prefix(3))
        let suggestions = Array(Set(all.map(\.app)))
            .filter { $0.lowercased().contains(queryPrefix) }
            .prefix(5)

        FileHandle.standardError.write("Error: No window found for '\(query)'\n".data(using: .utf8)!)
        if !suggestions.isEmpty {
            FileHandle.standardError.write("Did you mean: \(suggestions.joined(separator: ", "))?\n".data(using: .utf8)!)
        }
    }
}
