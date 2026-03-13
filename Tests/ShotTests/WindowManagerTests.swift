import XCTest
@testable import shot_cli

final class WindowManagerTests: XCTestCase {
    func testListWindowsDoesNotCrash() throws {
        let windows = WindowManager.listWindows()
        for window in windows {
            XCTAssertFalse(window.app.isEmpty, "App name should not be empty")
            XCTAssertGreaterThan(window.id, 0, "Window ID should be positive")
        }
    }

    func testFindWindowsEmptyQueryReturnsEmpty() throws {
        // In Swift, "hello".contains("") returns false
        // So empty query returns no results — this is expected behavior
        let found = WindowManager.findWindows(app: "")
        XCTAssertTrue(found.isEmpty, "Empty query should return empty (Swift contains behavior)")
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
