import SwiftUI

/// The Midnight Transit world: a deep enamel ground, porcelain type, and three
/// line inks that carry each person's share.
enum Transit {
    static let ink = Color(red: 8 / 255, green: 20 / 255, blue: 40 / 255)
    static let deep = Color(red: 5 / 255, green: 14 / 255, blue: 28 / 255)
    static let panel = Color(red: 15 / 255, green: 33 / 255, blue: 58 / 255)
    static let hairline = Color(red: 35 / 255, green: 57 / 255, blue: 90 / 255)
    static let porcelain = Color(red: 244 / 255, green: 247 / 255, blue: 251 / 255)
    static let secondary = Color(red: 151 / 255, green: 169 / 255, blue: 188 / 255)
    static let tertiary = Color(red: 122 / 255, green: 142 / 255, blue: 166 / 255)

    static let imran = Color(red: 224 / 255, green: 58 / 255, blue: 47 / 255)
    static let bambang = Color(red: 240 / 255, green: 165 / 255, blue: 0 / 255)
    static let danii = Color(red: 47 / 255, green: 111 / 255, blue: 208 / 255)

    static func line(_ index: Int) -> Color {
        switch index {
        case 0: imran
        case 1: bambang
        default: danii
        }
    }

    static var ground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 11 / 255, green: 29 / 255, blue: 56 / 255),
                deep,
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
