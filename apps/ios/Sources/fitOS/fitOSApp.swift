import SwiftUI

@main
struct fitOSApp: App {
    @StateObject private var state = AppState()
    @StateObject private var theme = ThemeManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(state)
                .environmentObject(theme)
                .preferredColorScheme(theme.preferredColorScheme)
                .tint(Palette.red)
        }
    }
}
