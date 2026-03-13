# shot-cli Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** AI 디버깅용 macOS CLI 스크린샷 도구 — `screencapture` 래퍼 + 윈도우 탐색 API

**Architecture:** Swift CLI가 `screencapture` 명령어를 래핑하여 인터랙티브/프로그래매틱 캡처를 제공. 윈도우 정보는 `CGWindowListCopyWindowInfo`로 조회. 출력은 base64 기본 + 파일/클립보드 옵션.

**Tech Stack:** Swift 5.9+, Swift Package Manager, swift-argument-parser (~> 1.3), CoreGraphics, AppKit

**Spec:** `docs/superpowers/specs/2026-03-13-shot-cli-design.md`

---

## File Map

| File | Responsibility |
|------|---------------|
| `Package.swift` | SPM 프로젝트 설정, 의존성 선언 |
| `Sources/shot/Shot.swift` | @main 진입점, ArgumentParser root command |
| `Sources/shot/Models/WindowInfo.swift` | 윈도우 정보 모델 (Codable) |
| `Sources/shot/Core/WindowManager.swift` | CGWindowList 래핑, 앱 이름 매칭 |
| `Sources/shot/Core/Capturer.swift` | screencapture 프로세스 실행 |
| `Sources/shot/Core/OutputHandler.swift` | base64 / 파일 / 클립보드 출력 |
| `Sources/shot/Commands/ListCommand.swift` | `--list` 윈도우 목록 JSON 출력 |
| `Sources/shot/Commands/CaptureCommand.swift` | 캡처 실행 (영역/윈도우/전체/앱/좌표) |
| `Tests/ShotTests/WindowManagerTests.swift` | WindowManager 테스트 |
| `Tests/ShotTests/CapturerTests.swift` | Capturer 테스트 |
| `Tests/ShotTests/OutputHandlerTests.swift` | OutputHandler 테스트 |

---

## Chunk 1: Project Scaffold & Models

### Task 1: Initialize Swift Package

**Files:**
- Create: `Package.swift`

- [ ] **Step 0: Create .gitignore**

Create `.gitignore`:

```
.build/
.swiftpm/
*.xcodeproj
*.xcworkspace
DerivedData/
```

- [ ] **Step 1: Create Package.swift**

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "shot",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "shot",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/shot"
        ),
        .testTarget(
            name: "ShotTests",
            dependencies: ["shot"],
            path: "Tests/ShotTests"
        ),
    ]
)
```

- [ ] **Step 2: Create minimal main entry point**

Create `Sources/shot/Shot.swift`:

```swift
import ArgumentParser

@main
struct Shot: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "macOS screenshot CLI for AI debugging workflows",
        version: "0.1.0"
    )

    mutating func run() throws {
        print("shot: not yet implemented")
    }
}
```

- [ ] **Step 3: Verify build**

Run: `swift build 2>&1 | tail -5`
Expected: `Build complete!`

- [ ] **Step 4: Verify run**

Run: `swift run shot --help 2>&1 | tail -10`
Expected: Help text with "macOS screenshot CLI for AI debugging workflows"

- [ ] **Step 5: Commit**

```bash
git add .gitignore Package.swift Sources/shot/Shot.swift
git commit -m "feat: initialize swift package with argument-parser"
```

---

### Task 2: WindowInfo Model

**Files:**
- Create: `Sources/shot/Models/WindowInfo.swift`
- Create: `Tests/ShotTests/WindowInfoTests.swift`

- [ ] **Step 1: Write failing test**

Create `Tests/ShotTests/WindowInfoTests.swift`:

```swift
import XCTest
@testable import shot

final class WindowInfoTests: XCTestCase {
    func testJsonEncoding() throws {
        let info = WindowInfo(app: "Safari", title: "GitHub", id: 1234, x: 0, y: 25, w: 1440, h: 875)
        let data = try JSONEncoder().encode(info)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["app"] as? String, "Safari")
        XCTAssertEqual(json["id"] as? Int, 1234)
        XCTAssertEqual(json["w"] as? Int, 1440)
    }

    func testJsonDecoding() throws {
        let json = """
        {"app":"Terminal","title":"zsh","id":5678,"x":100,"y":200,"w":800,"h":600}
        """
        let info = try JSONDecoder().decode(WindowInfo.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(info.app, "Terminal")
        XCTAssertEqual(info.id, 5678)
        XCTAssertEqual(info.h, 600)
    }

    func testJsonRoundTrip() throws {
        let original = WindowInfo(app: "Code", title: "main.swift", id: 99, x: 0, y: 0, w: 1920, h: 1080)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WindowInfo.self, from: data)

        XCTAssertEqual(original, decoded)
    }

    func testDecodingInvalidJsonThrows() {
        let badJson = """
        {"app":"Safari"}
        """
        XCTAssertThrowsError(
            try JSONDecoder().decode(WindowInfo.self, from: badJson.data(using: .utf8)!)
        )
    }

    func testBoundaryValues() throws {
        let info = WindowInfo(app: "", title: "", id: 0, x: 0, y: 0, w: 0, h: 0)
        let data = try JSONEncoder().encode(info)
        let decoded = try JSONDecoder().decode(WindowInfo.self, from: data)

        XCTAssertEqual(decoded.app, "")
        XCTAssertEqual(decoded.w, 0)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter WindowInfoTests 2>&1 | tail -10`
Expected: FAIL — `WindowInfo` not found

- [ ] **Step 3: Implement WindowInfo**

Create `Sources/shot/Models/WindowInfo.swift`:

```swift
import Foundation

struct WindowInfo: Codable, Equatable {
    let app: String
    let title: String
    let id: Int
    let x: Int
    let y: Int
    let w: Int
    let h: Int
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter WindowInfoTests 2>&1 | tail -10`
Expected: `Test Suite 'WindowInfoTests' passed`

- [ ] **Step 5: Commit**

```bash
git add Sources/shot/Models/WindowInfo.swift Tests/ShotTests/WindowInfoTests.swift
git commit -m "feat: add WindowInfo model with Codable support"
```

---

## Chunk 2: Core Modules

### Task 3: WindowManager

**Files:**
- Create: `Sources/shot/Core/WindowManager.swift`
- Create: `Tests/ShotTests/WindowManagerTests.swift`

- [ ] **Step 1: Write failing tests**

Create `Tests/ShotTests/WindowManagerTests.swift`:

```swift
import XCTest
@testable import shot

final class WindowManagerTests: XCTestCase {
    func testListWindowsDoesNotCrash() throws {
        let windows = WindowManager.listWindows()
        // Verify each window has valid structure
        for window in windows {
            XCTAssertFalse(window.app.isEmpty, "App name should not be empty")
            XCTAssertGreaterThan(window.id, 0, "Window ID should be positive")
        }
    }

    func testFindWindowsEmptyQuery() throws {
        // Empty string matches all windows (contains-based)
        let all = WindowManager.listWindows()
        let found = WindowManager.findWindows(app: "")
        XCTAssertEqual(found.count, all.count, "Empty query should match all windows")
    }

    func testFindWindowsCaseInsensitive() throws {
        let windows = WindowManager.listWindows()
        guard !windows.isEmpty else {
            throw XCTSkip("No windows available (Screen Recording permission may be missing)")
        }

        let firstApp = windows[0].app
        let found = WindowManager.findWindows(app: firstApp.lowercased())
        XCTAssertFalse(found.isEmpty, "Case-insensitive search should find '\(firstApp)'")
    }

    func testFindWindowsAppNotFound() throws {
        let found = WindowManager.findWindows(app: "ThisAppDoesNotExist12345")
        XCTAssertTrue(found.isEmpty, "Non-existent app should return empty array")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter WindowManagerTests 2>&1 | tail -10`
Expected: FAIL — `WindowManager` not found

- [ ] **Step 3: Implement WindowManager**

Create `Sources/shot/Core/WindowManager.swift`:

```swift
import CoreGraphics
import Foundation

enum WindowManager {
    static func listWindows() -> [WindowInfo] {
        guard let windowList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return []
        }

        return windowList.compactMap { dict -> WindowInfo? in
            guard let app = dict[kCGWindowOwnerName as String] as? String,
                  let id = dict[kCGWindowNumber as String] as? Int,
                  let bounds = dict[kCGWindowBounds as String] as? [String: Any],
                  let x = bounds["X"] as? Int,
                  let y = bounds["Y"] as? Int,
                  let w = bounds["Width"] as? Int,
                  let h = bounds["Height"] as? Int,
                  w > 0, h > 0
            else { return nil }

            let title = dict[kCGWindowName as String] as? String ?? ""
            return WindowInfo(app: app, title: title, id: id, x: x, y: y, w: w, h: h)
        }
    }

    /// Find windows by app name (case-insensitive, contains-based).
    /// Results are in front-to-back order (CGWindowList default), so .first is the frontmost window.
    static func findWindows(app: String) -> [WindowInfo] {
        let query = app.lowercased()
        return listWindows().filter {
            $0.app.lowercased().contains(query)
        }
    }

    static func checkPermission() -> Bool {
        let windows = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] ?? []

        // If we get window names, we have permission
        return windows.contains { dict in
            dict[kCGWindowName as String] as? String != nil
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter WindowManagerTests 2>&1 | tail -10`
Expected: PASS (or skip if no permission)

- [ ] **Step 5: Commit**

```bash
git add Sources/shot/Core/WindowManager.swift Tests/ShotTests/WindowManagerTests.swift
git commit -m "feat: add WindowManager with CGWindowList wrapping"
```

---

### Task 4: Capturer

**Files:**
- Create: `Sources/shot/Core/Capturer.swift`
- Create: `Tests/ShotTests/CapturerTests.swift`

- [ ] **Step 1: Write failing tests**

Create `Tests/ShotTests/CapturerTests.swift`:

```swift
import XCTest
@testable import shot

final class CapturerTests: XCTestCase {
    func testFullScreenCapture() throws {
        let result = try Capturer.capture(mode: .fullScreen)
        XCTAssertFalse(result.isEmpty, "Capture should return non-empty data")
        // PNG magic bytes: 89 50 4E 47
        XCTAssertEqual(result.prefix(4), Data([0x89, 0x50, 0x4E, 0x47]), "Should be valid PNG")
    }

    func testCaptureByRectangle() throws {
        let result = try Capturer.capture(mode: .rect(x: 0, y: 0, w: 100, h: 100))
        XCTAssertFalse(result.isEmpty, "Rect capture should return non-empty data")
    }

    func testCaptureInvalidRectThrows() throws {
        XCTAssertThrowsError(
            try Capturer.capture(mode: .rect(x: -1, y: -1, w: 0, h: 0))
        ) { error in
            XCTAssertTrue(error is CaptureError, "Should throw CaptureError")
        }
    }

    func testCaptureInvalidRectZeroWidth() throws {
        XCTAssertThrowsError(
            try Capturer.capture(mode: .rect(x: 0, y: 0, w: 0, h: 100))
        )
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter CapturerTests 2>&1 | tail -10`
Expected: FAIL — `Capturer` not found

- [ ] **Step 3: Implement Capturer**

Create `Sources/shot/Core/Capturer.swift`:

```swift
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

        let data = try Data(contentsOf: tempURL)
        if data.isEmpty {
            throw CaptureError.emptyCapture
        }

        return data
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter CapturerTests 2>&1 | tail -10`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Sources/shot/Core/Capturer.swift Tests/ShotTests/CapturerTests.swift
git commit -m "feat: add Capturer wrapping screencapture process"
```

---

### Task 5: OutputHandler

**Files:**
- Create: `Sources/shot/Core/OutputHandler.swift`
- Create: `Tests/ShotTests/OutputHandlerTests.swift`

- [ ] **Step 1: Write failing tests**

Create `Tests/ShotTests/OutputHandlerTests.swift`:

```swift
import XCTest
@testable import shot

final class OutputHandlerTests: XCTestCase {
    let testData = "hello screenshot".data(using: .utf8)!

    func testBase64Output() throws {
        let base64 = OutputHandler.toBase64(testData)
        let expected = testData.base64EncodedString()
        XCTAssertEqual(base64, expected)
    }

    func testSaveToFile() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let path = tempDir.appendingPathComponent("shot-test-\(UUID().uuidString).png")
        defer { try? FileManager.default.removeItem(at: path) }

        try OutputHandler.saveToFile(testData, path: path.path)
        let saved = try Data(contentsOf: path)
        XCTAssertEqual(saved, testData)
    }

    func testSaveToDefaultPath() throws {
        let path = try OutputHandler.saveToFile(testData, path: nil)
        defer { try? FileManager.default.removeItem(atPath: path) }

        XCTAssertTrue(path.contains("shot-"), "Default path should contain 'shot-' prefix")
        XCTAssertTrue(path.hasSuffix(".png"), "Default path should end with .png")

        let saved = try Data(contentsOf: URL(fileURLWithPath: path))
        XCTAssertEqual(saved, testData)
    }

    func testBase64RoundTrip() throws {
        let base64 = OutputHandler.toBase64(testData)
        let decoded = Data(base64Encoded: base64)
        XCTAssertEqual(decoded, testData)
    }

    func testSaveToInvalidPathThrows() {
        XCTAssertThrowsError(
            try OutputHandler.saveToFile(testData, path: "/nonexistent/dir/file.png")
        )
    }

    func testBase64EmptyData() {
        let result = OutputHandler.toBase64(Data())
        XCTAssertEqual(result, "", "Empty data should produce empty base64 string")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter OutputHandlerTests 2>&1 | tail -10`
Expected: FAIL — `OutputHandler` not found

- [ ] **Step 3: Implement OutputHandler**

Create `Sources/shot/Core/OutputHandler.swift`:

```swift
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
            targetPath = (desktop as NSString).appendingPathComponent("shot-\(timestamp).png")
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter OutputHandlerTests 2>&1 | tail -10`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Sources/shot/Core/OutputHandler.swift Tests/ShotTests/OutputHandlerTests.swift
git commit -m "feat: add OutputHandler for base64, file, and clipboard output"
```

---

## Chunk 3: Commands & Integration

### Task 6: ListCommand (--list)

**Files:**
- Create: `Sources/shot/Commands/ListCommand.swift`
- Modify: `Sources/shot/Shot.swift`

- [ ] **Step 1: Implement ListCommand**

Create `Sources/shot/Commands/ListCommand.swift`:

```swift
import ArgumentParser
import Foundation

struct ListCommand {
    static func run() throws {
        guard WindowManager.checkPermission() else {
            FileHandle.standardError.write(
                "Error: Screen Recording permission required.\n".data(using: .utf8)!
            )
            FileHandle.standardError.write(
                "Grant permission in System Settings > Privacy & Security > Screen Recording\n".data(using: .utf8)!
            )
            throw ExitCode(1)
        }

        let windows = WindowManager.listWindows()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(windows)

        print(String(data: data, encoding: .utf8)!)
    }
}
```

- [ ] **Step 2: Wire into Shot.swift**

Update `Sources/shot/Shot.swift`:

```swift
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
        if list {
            try ListCommand.run()
            return
        }

        try CaptureCommand.run(
            window: window,
            full: full,
            apps: app,
            rect: rect,
            file: file,
            output: output,
            clipboard: clipboard,
            json: json
        )
    }
}
```

- [ ] **Step 3: Create CaptureCommand stub (prevents build failure)**

Create `Sources/shot/Commands/CaptureCommand.swift` with a stub:

```swift
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
        fatalError("CaptureCommand not yet implemented")
    }
}
```

- [ ] **Step 4: Verify build**

Run: `swift build 2>&1 | tail -5`
Expected: `Build complete!`

- [ ] **Step 5: Commit**

```bash
git add Sources/shot/Commands/ListCommand.swift Sources/shot/Commands/CaptureCommand.swift Sources/shot/Shot.swift
git commit -m "feat: add --list command, CLI argument parsing, and CaptureCommand stub"
```

---

### Task 7: CaptureCommand (replace stub)

**Files:**
- Modify: `Sources/shot/Commands/CaptureCommand.swift`

- [ ] **Step 1: Replace CaptureCommand stub with full implementation**

Replace `Sources/shot/Commands/CaptureCommand.swift`:

```swift
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
            // Multi-app capture
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
            // Single capture
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

        // Output
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
        let suggestions = Array(Set(all.map(\.app)))
            .filter { $0.lowercased().contains(query.lowercased().prefix(3)) }
            .prefix(5)

        FileHandle.standardError.write("Error: No window found for '\(query)'\n".data(using: .utf8)!)
        if !suggestions.isEmpty {
            FileHandle.standardError.write("Did you mean: \(suggestions.joined(separator: ", "))?\n".data(using: .utf8)!)
        }
    }
}
```

- [ ] **Step 2: Verify full build**

Run: `swift build 2>&1 | tail -5`
Expected: `Build complete!`

- [ ] **Step 3: Manual smoke test**

Run: `swift run shot --list 2>&1 | head -20`
Expected: JSON array of windows (or permission error)

Run: `swift run shot --full 2>&1 | head -1 | cut -c1-20`
Expected: First 20 chars of base64 string (e.g., `iVBORw0KGgoAAAANSU`)

- [ ] **Step 4: Commit**

```bash
git add Sources/shot/Commands/CaptureCommand.swift
git commit -m "feat: add CaptureCommand with all capture modes and output options"
```

---

### Task 8: Exit Code Handling

**Files:**
- Modify: `Sources/shot/Shot.swift`

- [ ] **Step 1: Add exit code handling to Shot.run()**

Wrap the `run()` body in `Shot.swift` with proper exit code mapping:

```swift
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
```

- [ ] **Step 2: Verify build**

Run: `swift build 2>&1 | tail -5`
Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Sources/shot/Shot.swift
git commit -m "feat: add structured exit codes for error handling"
```

---

### Task 9: End-to-End Smoke Test & Final Verification

- [ ] **Step 1: Run full test suite**

Run: `swift test 2>&1 | tail -20`
Expected: All tests pass

- [ ] **Step 2: Build release binary**

Run: `swift build -c release 2>&1 | tail -5`
Expected: `Build complete!`

- [ ] **Step 3: Verify binary size**

Run: `ls -lh .build/release/shot | awk '{print $5}'`
Expected: Reasonable size (< 10MB)

- [ ] **Step 4: End-to-end test: --list**

Run: `.build/release/shot --list 2>&1 | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'{len(d)} windows found')"`
Expected: `N windows found` (N > 0)

- [ ] **Step 5: End-to-end test: --full**

Run: `.build/release/shot --full | head -c 20`
Expected: Start of base64 string

- [ ] **Step 6: End-to-end test: --rect**

Run: `.build/release/shot --rect 0,0,200,200 | wc -c`
Expected: Non-zero character count

- [ ] **Step 7: End-to-end test: --app**

Run: `.build/release/shot --app Finder | wc -c`
Expected: Non-zero character count (Finder is always running)

- [ ] **Step 8: Final commit**

```bash
git add -A
git commit -m "chore: verify all tests pass and release build works"
```
