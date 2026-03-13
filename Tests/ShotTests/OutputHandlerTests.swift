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
