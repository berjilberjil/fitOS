import SwiftUI
import UserNotifications

@main
struct fitOSApp: App {
    @UIApplicationDelegateAdaptor(NotificationAppDelegate.self) private var appDelegate
    @StateObject private var state = AppState()
    @StateObject private var theme = ThemeManager()
    @ObservedObject private var notifications = NotificationManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(state)
                .environmentObject(theme)
                .environmentObject(notifications)
                .preferredColorScheme(theme.preferredColorScheme)
                .tint(Palette.red)
                .task {
                    // Ask permission + schedule daily reminders every launch.
                    await NotificationManager.shared.bootstrap()
                }
        }
    }
}
