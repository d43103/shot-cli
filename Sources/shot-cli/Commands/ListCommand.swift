import ArgumentParser
import Foundation

enum ListCommand {
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
