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
