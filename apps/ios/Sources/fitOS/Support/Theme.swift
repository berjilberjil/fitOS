import SwiftUI

/// fitOS design language — mirrors apps/web/src/app.css.
/// MyOS-derived: dense, refined, single-accent (vivid red) on pure black.
enum Palette {
    static let bg = Color(hex: 0x000000)
    static let surface = Color(hex: 0x0C0C0E)   // cards
    static let surface2 = Color(hex: 0x141416)  // inputs
    static let elevated = Color(hex: 0x1D1D21)
    static let text = Color(hex: 0xF4F4F5)
    static let muted = Color(hex: 0xA0A0A6)
    static let faint = Color(hex: 0x6B6B72)
    static let border = Color.white.opacity(0.07)
    static let borderStrong = Color.white.opacity(0.13)

    static let red = Color(hex: 0xEE2E24)       // the single accent
    static let redBright = Color(hex: 0xFF6A5F)
    static let redSoft = Color(hex: 0xEE2E24).opacity(0.15)
    static let ok = Color(hex: 0x37D399)
    static let warn = Color(hex: 0xF5B544)
    static let info = Color(hex: 0x5A9BF7)
}

enum Radius {
    static let lg: CGFloat = 22
    static let md: CGFloat = 14
    static let sm: CGFloat = 10
}

extension Color {
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

extension Text {
    /// 11px, bold, tracked, uppercase — the fitOS "eyebrow".
    func eyebrow() -> some View {
        self.font(.system(size: 11, weight: .bold))
            .tracking(1.3)
            .textCase(.uppercase)
            .foregroundStyle(Palette.faint)
    }
}
