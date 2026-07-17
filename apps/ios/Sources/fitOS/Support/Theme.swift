import SwiftUI
import UIKit

// MARK: - Theme preference (light / dark / system)

enum ThemeMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

/// App-wide appearance preference. Persisted in UserDefaults (device-local).
@MainActor
final class ThemeManager: ObservableObject {
    private static let key = "fitos.themeMode"

    @Published var mode: ThemeMode {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: Self.key) }
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: Self.key),
           let m = ThemeMode(rawValue: raw) {
            mode = m
        } else {
            mode = .system
        }
    }

    /// nil = follow system (preferredColorScheme semantics).
    var preferredColorScheme: ColorScheme? {
        switch mode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Palette (adaptive light + dark)

/// fitOS design language — mirrors apps/web/src/app.css.
/// Adaptive surfaces: pure black (dark) / soft white (light), single red accent.
enum Palette {
    static let bg = Color(uiColor: .fitDynamic(dark: 0x000000, light: 0xF4F4F5))
    static let surface = Color(uiColor: .fitDynamic(dark: 0x0C0C0E, light: 0xFFFFFF))
    static let surface2 = Color(uiColor: .fitDynamic(dark: 0x141416, light: 0xEBEBED))
    static let elevated = Color(uiColor: .fitDynamic(dark: 0x1D1D21, light: 0xE0E0E4))
    static let text = Color(uiColor: .fitDynamic(dark: 0xF4F4F5, light: 0x111114))
    static let muted = Color(uiColor: .fitDynamic(dark: 0xA0A0A6, light: 0x5C5C64))
    static let faint = Color(uiColor: .fitDynamic(dark: 0x6B6B72, light: 0x8A8A92))
    static let border = Color(uiColor: UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.07)
            : UIColor.black.withAlphaComponent(0.08)
    })
    static let borderStrong = Color(uiColor: UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.13)
            : UIColor.black.withAlphaComponent(0.14)
    })

    static let red = Color(hex: 0xEE2E24)
    static let redBright = Color(uiColor: .fitDynamic(dark: 0xFF6A5F, light: 0xD42018))
    static let redSoft = Color(uiColor: UIColor { tc in
        UIColor(hex: 0xEE2E24).withAlphaComponent(tc.userInterfaceStyle == .dark ? 0.15 : 0.12)
    })
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

extension UIColor {
    convenience init(hex: UInt, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }

    static func fitDynamic(dark: UInt, light: UInt) -> UIColor {
        UIColor { tc in
            UIColor(hex: tc.userInterfaceStyle == .dark ? dark : light)
        }
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
