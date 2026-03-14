import ArgumentParser
import Foundation

@main
struct Shot: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "macOS screenshot CLI for AI debugging workflows",
        version: "0.1.0"
    )

    // Capture mode (mutually exclusive)
    @Flag(name: .long, help: "List all windows as JSON")
    var list = false

    @Flag(name: .long, help: "Select window by clicking")
    var window = false

    @Flag(name: .long, help: "Capture full screen")
    var full = false

    @Option(name: .long, help: "Capture window by app name (repeatable)")
    var app: [String] = []

    @Option(name: .long, help: "Capture rectangle region (x,y,w,h)")
    var rect: String?

    // Image processing
    @Flag(name: .long, help: "Keep original Retina resolution (skip 1x downscale)")
    var retina = false

    @Option(name: .long, help: "Max pixel size for longest edge (default: 1568, 0 = no limit)")
    var maxSize: Int = 1568

    // Output options
    @Flag(name: .long, help: "Save to file")
    var file = false

    @Option(name: .shortAndLong, help: "Output file path (implies --file)")
    var output: String?

    @Flag(name: .long, help: "Copy to clipboard")
    var clipboard = false

    @Flag(name: .long, help: "Output as JSON array")
    var json = false

    mutating func validate() throws {
        // --list is exclusive
        if list {
            guard !window && !full && app.isEmpty && rect == nil && !file && output == nil && !clipboard && !json else {
                throw ValidationError("--list cannot be combined with other flags")
            }
        }

        // Capture modes are mutually exclusive
        let modeCount = [window, full, !app.isEmpty, rect != nil].filter { $0 }.count
        if modeCount > 1 {
            throw ValidationError("--window, --full, --app, and --rect are mutually exclusive")
        }

        // -o implies --file
        if output != nil { file = true }
    }

    mutating func run() throws {
        do {
            if list {
                try ListCommand.run()
                return
            }

            try CaptureCommand.run(
                window: window,
                full: full,
                apps: app,
                rect: rect,
                retina: retina,
                maxSize: maxSize,
                file: file,
                output: output,
                clipboard: clipboard,
                json: json
            )
        } catch let error as CaptureError {
            FileHandle.standardError.write("Error: \(error.description)\n".data(using: .utf8)!)
            switch error {
            case .emptyCapture: throw ExitCode(3)
            case .processError: throw ExitCode(3)
            case .invalidRect: throw ExitCode(3)
            case .userCancelled: throw ExitCode(130)
            }
        }
    }
}
