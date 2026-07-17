import Foundation
import UserNotifications
import UIKit
import SwiftUI

// MARK: - Models

enum ReminderKind: String, CaseIterable, Identifiable, Codable {
    case morningLog
    case breakfast
    case lunch
    case dinner
    case gym
    case rest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .morningLog: return "Start your day"
        case .breakfast: return "Breakfast time"
        case .lunch: return "Lunch time"
        case .dinner: return "Dinner time"
        case .gym: return "Gym time"
        case .rest: return "Rest & recover"
        }
    }

    var body: String {
        switch self {
        case .morningLog:
            return "Open fitOS and log weight, meals, or plan today's workout."
        case .breakfast:
            return "Eat on time — log breakfast to stay on your calorie target."
        case .lunch:
            return "Lunch break — log your meal so Progress stays accurate."
        case .dinner:
            return "Dinner time — fuel up and log it in fitOS."
        case .gym:
            return "Time to train — open fitOS and crush today's workout."
        case .rest:
            return "Recovery matters — rest, sleep, and stay hydrated."
        }
    }

    var systemImage: String {
        switch self {
        case .morningLog: return "sun.horizon.fill"
        case .breakfast: return "cup.and.saucer.fill"
        case .lunch: return "fork.knife"
        case .dinner: return "moon.stars.fill"
        case .gym: return "dumbbell.fill"
        case .rest: return "bed.double.fill"
        }
    }

    /// Default hour / minute (24h, local time).
    var defaultTime: (hour: Int, minute: Int) {
        switch self {
        case .morningLog: return (5, 0)
        case .breakfast: return (8, 0)
        case .lunch: return (13, 0)
        case .dinner: return (20, 0)
        case .gym: return (16, 30)
        case .rest: return (21, 30)
        }
    }
}

struct ReminderConfig: Codable, Equatable {
    var enabled: Bool
    var hour: Int
    var minute: Int

    static func defaultConfig(for kind: ReminderKind) -> ReminderConfig {
        let t = kind.defaultTime
        return ReminderConfig(enabled: true, hour: t.hour, minute: t.minute)
    }

    /// Calendar components for a daily local trigger.
    func dateComponents(calendar: Calendar = .current) -> DateComponents {
        var c = DateComponents()
        c.calendar = calendar
        c.timeZone = calendar.timeZone
        c.hour = hour
        c.minute = minute
        c.second = 0
        return c
    }

    func asDate(calendar: Calendar = .current) -> Date {
        var c = calendar.dateComponents([.year, .month, .day], from: Date())
        c.hour = hour
        c.minute = minute
        c.second = 0
        return calendar.date(from: c) ?? Date()
    }

    mutating func setFrom(date: Date, calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        hour = parts.hour ?? hour
        minute = parts.minute ?? minute
    }

    func timeLabel(locale: Locale = .current) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: asDate())
    }
}

struct NotificationSettings: Codable, Equatable {
    var masterEnabled: Bool
    var reminders: [String: ReminderConfig]

    static var `default`: NotificationSettings {
        var map: [String: ReminderConfig] = [:]
        for k in ReminderKind.allCases {
            map[k.rawValue] = .defaultConfig(for: k)
        }
        // Master ON by default — first open will request permission.
        return NotificationSettings(masterEnabled: true, reminders: map)
    }

    func config(for kind: ReminderKind) -> ReminderConfig {
        reminders[kind.rawValue] ?? .defaultConfig(for: kind)
    }

    mutating func set(_ config: ReminderConfig, for kind: ReminderKind) {
        reminders[kind.rawValue] = config
    }
}

// MARK: - App delegate (show banners while app is open)

/// Without this, iOS suppresses banners when fitOS is in the foreground — looks "broken".
final class NotificationAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        return true
    }

    // Show banner + sound even when fitOS is open.critical for testing.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}

// MARK: - Manager

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    private static let storageKey = "fitos.notificationSettings"
    private let center = UNUserNotificationCenter.current()
    private var isApplying = false

    @Published private(set) var settings: NotificationSettings
    @Published private(set) var authStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var pendingCount: Int = 0
    @Published private(set) var statusLine: String = "Checking…"
    @Published var lastError: String?
    @Published var lastInfo: String?

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode(NotificationSettings.self, from: data) {
            settings = decoded
        } else {
            settings = .default
        }
    }

    var isAuthorized: Bool {
        authStatus == .authorized || authStatus == .provisional || authStatus == .ephemeral
    }

    var authLabel: String {
        switch authStatus {
        case .notDetermined: return "Not asked yet"
        case .denied: return "Denied — open iOS Settings"
        case .authorized: return "Allowed"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }

    // MARK: - Bootstrap

    /// Call on every cold start. Requests permission if master is on and not decided yet.
    func bootstrap() async {
        await refreshAuthStatus()
        if settings.masterEnabled {
            if authStatus == .notDetermined {
                _ = await requestPermission()
            } else if isAuthorized {
                await reschedule(reason: "app launch")
            } else {
                statusLine = "Notifications denied. Enable in Settings → fitOS → Notifications."
                pendingCount = 0
            }
        } else {
            center.removeAllPendingNotificationRequests()
            pendingCount = 0
            statusLine = "Reminders off"
        }
    }

    // MARK: - Permission

    func refreshAuthStatus() async {
        let s = await center.notificationSettings()
        authStatus = s.authorizationStatus
    }

    @discardableResult
    func requestPermission() async -> Bool {
        do {
            let ok = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthStatus()
            if ok || isAuthorized {
                await reschedule(reason: "permission granted")
                Haptics.success()
                lastInfo = "Notifications allowed. Daily reminders are scheduled."
                return true
            } else {
                lastError = "Permission denied. Enable Notifications for fitOS in the iOS Settings app."
                statusLine = "Denied"
                Haptics.error()
                return false
            }
        } catch {
            lastError = error.localizedDescription
            Haptics.error()
            return false
        }
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Schedule

    func reschedule(reason: String = "") async {
        await refreshAuthStatus()
        center.removeAllPendingNotificationRequests()

        guard settings.masterEnabled else {
            pendingCount = 0
            statusLine = "Reminders off"
            return
        }
        guard isAuthorized else {
            pendingCount = 0
            statusLine = authStatus == .denied
                ? "Blocked in iOS Settings"
                : "Need permission"
            return
        }

        var scheduled = 0
        var errors: [String] = []

        for kind in ReminderKind.allCases {
            let cfg = settings.config(for: kind)
            guard cfg.enabled else { continue }

            let content = UNMutableNotificationContent()
            content.title = "fitOS · \(kind.title)"
            content.body = kind.body
            content.sound = .default
            content.categoryIdentifier = "fitos.reminder"
            content.threadIdentifier = "fitos.reminders"

            let comps = cfg.dateComponents()
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)

            // Validate trigger
            if let next = trigger.nextTriggerDate() {
                _ = next
            }

            let req = UNNotificationRequest(
                identifier: "fitos.reminder.\(kind.rawValue)",
                content: content,
                trigger: trigger
            )
            do {
                try await center.add(req)
                scheduled += 1
            } catch {
                errors.append("\(kind.rawValue): \(error.localizedDescription)")
            }
        }

        await refreshPendingCount()
        if let err = errors.first {
            lastError = err
        }
        let suffix = reason.isEmpty ? "" : " (\(reason))"
        statusLine = "\(scheduled) daily reminder\(scheduled == 1 ? "" : "s") scheduled\(suffix)"
        if scheduled > 0 {
            lastError = nil
        }
    }

    func refreshPendingCount() async {
        let pending = await center.pendingNotificationRequests()
        pendingCount = pending.filter { $0.identifier.hasPrefix("fitos.") }.count
    }

    // MARK: - Test (proves pipeline works in ~5s)

    /// Fires a real local notification in `seconds` — works with app open or backgrounded.
    func sendTestNotification(in seconds: TimeInterval = 5) async {
        await refreshAuthStatus()
        if authStatus == .notDetermined {
            let ok = await requestPermission()
            guard ok else { return }
        }
        guard isAuthorized else {
            lastError = "Allow notifications first (or enable them in iOS Settings → fitOS)."
            Haptics.error()
            return
        }

        let id = "fitos.test.\(Int(Date().timeIntervalSince1970))"
        let content = UNMutableNotificationContent()
        content.title = "fitOS · Test notification"
        content.body = "It works! Your daily meal/gym reminders use the same system."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(seconds, 1), repeats: false)
        let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        do {
            try await center.add(req)
            lastInfo = "Test notification in \(Int(seconds))s — keep the phone unlocked. Banner shows even inside fitOS."
            lastError = nil
            Haptics.success()
            await refreshPendingCount()
        } catch {
            lastError = "Test failed: \(error.localizedDescription)"
            Haptics.error()
        }
    }

    // MARK: - Mutators

    func updateSettings(_ mutate: (inout NotificationSettings) -> Void) {
        var s = settings
        mutate(&s)
        guard s != settings else { return }
        settings = s
        persist()
        Task { await reschedule(reason: "settings changed") }
    }

    func setMaster(_ on: Bool) {
        updateSettings { $0.masterEnabled = on }
        if on {
            Task {
                if !isAuthorized { _ = await requestPermission() }
                Haptics.success()
            }
        } else {
            center.removeAllPendingNotificationRequests()
            pendingCount = 0
            statusLine = "Reminders off"
            Haptics.soft()
        }
    }

    func setEnabled(_ on: Bool, for kind: ReminderKind) {
        updateSettings { s in
            var c = s.config(for: kind)
            c.enabled = on
            s.set(c, for: kind)
        }
        Haptics.selection()
    }

    func setTime(_ date: Date, for kind: ReminderKind) {
        updateSettings { s in
            var c = s.config(for: kind)
            c.setFrom(date: date)
            s.set(c, for: kind)
        }
        Haptics.soft()
    }

    func resetDefaults() {
        settings = .default
        persist()
        Haptics.success()
        Task {
            if !isAuthorized { _ = await requestPermission() }
            await reschedule(reason: "reset defaults")
            lastInfo = "Defaults restored and rescheduled."
        }
    }

    // MARK: - Persist

    private func persist() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
