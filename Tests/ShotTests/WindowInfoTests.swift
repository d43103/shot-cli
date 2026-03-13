import XCTest
@testable import shot_cli

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
