import XCTest
@testable import shot

final class CapturerTests: XCTestCase {
    func testFullScreenCapture() throws {
        do {
            let result = try Capturer.capture(mode: .fullScreen)
            XCTAssertFalse(result.isEmpty, "Capture should return non-empty data")
            // PNG magic bytes: 89 50 4E 47
            XCTAssertEqual(result.prefix(4), Data([0x89, 0x50, 0x4E, 0x47]), "Should be valid PNG")
        } catch {
            // screencapture may fail without display access (CI, sandboxed test)
            throw XCTSkip("screencapture not available in this environment: \(error)")
        }
    }

    func testCaptureByRectangle() throws {
        do {
            let result = try Capturer.capture(mode: .rect(x: 0, y: 0, w: 100, h: 100))
            XCTAssertFalse(result.isEmpty, "Rect capture should return non-empty data")
        } catch {
            throw XCTSkip("screencapture not available in this environment: \(error)")
        }
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
