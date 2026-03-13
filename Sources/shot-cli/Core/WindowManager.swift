import CoreGraphics
import Foundation

enum WindowManager {
    /// List all on-screen windows.
    /// Results are in front-to-back order (CGWindowList default).
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
                  let boundsDict = dict[kCGWindowBounds as String] as? [String: Any]
            else { return nil }

            // CGWindowList returns bounds as CGFloat (NSNumber), cast via NSNumber
            guard let x = (boundsDict["X"] as? NSNumber)?.intValue,
                  let y = (boundsDict["Y"] as? NSNumber)?.intValue,
                  let w = (boundsDict["Width"] as? NSNumber)?.intValue,
                  let h = (boundsDict["Height"] as? NSNumber)?.intValue,
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

        return windows.contains { dict in
            dict[kCGWindowName as String] as? String != nil
        }
    }
}
