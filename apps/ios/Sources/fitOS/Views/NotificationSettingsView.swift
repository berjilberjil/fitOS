import SwiftUI

/// Profile → Reminders: permission, test, schedule, status.
struct NotificationSettingsView: View {
    @ObservedObject private var manager = NotificationManager.shared
    @State private var testing = false

    var body: some View {
        Form {
            // MARK: Status + permission
            Section {
                HStack {
                    Text("Permission")
                    Spacer()
                    Text(manager.authLabel)
                        .foregroundStyle(manager.isAuthorized ? Palette.ok : Palette.warn)
                        .font(.system(size: 13, weight: .semibold))
                }
                HStack {
                    Text("Scheduled")
                    Spacer()
                    Text("\(manager.pendingCount)")
                        .foregroundStyle(Palette.muted)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                Text(manager.statusLine)
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.faint)

                if manager.authStatus == .denied {
                    Button {
                        manager.openSystemSettings()
                    } label: {
                        Label("Open iOS Settings", systemImage: "gear")
                            .foregroundStyle(Palette.red)
                    }
                } else if !manager.isAuthorized {
                    Button {
                        Task { _ = await manager.requestPermission() }
                    } label: {
                        Label("Allow notifications", systemImage: "bell.badge.fill")
                            .foregroundStyle(Palette.red)
                    }
                }
            } header: {
                Text("Status")
            } footer: {
                Text("Daily reminders need iOS permission. If denied once, you must re-enable them in the Settings app.")
            }

            // MARK: Master
            Section {
                Toggle("Daily reminders", isOn: Binding(
                    get: { manager.settings.masterEnabled },
                    set: { manager.setMaster($0) }
                ))
                .tint(Palette.red)
            } footer: {
                Text("When on, fitOS schedules local alarms for meals, gym, logging, and rest — every day at your times.")
            }

            // MARK: Instant test
            Section {
                Button {
                    testing = true
                    Task {
                        await manager.sendTestNotification(in: 5)
                        testing = false
                        // Refresh count after test is queued
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        await manager.refreshPendingCount()
                    }
                } label: {
                    HStack {
                        Label(
                            testing ? "Scheduling…" : "Send test in 5 seconds",
                            systemImage: "bell.and.waves.left.and.right"
                        )
                        .foregroundStyle(Palette.red)
                        .fontWeight(.semibold)
                        Spacer()
                        if testing { ProgressView().tint(Palette.red) }
                    }
                }
                .disabled(testing)
            } header: {
                Text("Prove it works")
            } footer: {
                Text("Tap this, wait ~5 seconds with the phone unlocked. You should see a fitOS banner (works even while the app is open).")
            }

            // MARK: Schedule
            if manager.settings.masterEnabled {
                Section("Schedule") {
                    ForEach(ReminderKind.allCases) { kind in
                        reminderRow(kind)
                    }
                }

                Section {
                    Button {
                        Task {
                            await manager.reschedule(reason: "manual refresh")
                            Haptics.success()
                        }
                    } label: {
                        Text("Reschedule all now")
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(Palette.red)
                    }
                    Button {
                        manager.resetDefaults()
                    } label: {
                        Text("Reset times to defaults")
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(Palette.muted)
                    }
                } footer: {
                    Text("Defaults: Log 5:00 · Breakfast 8:00 · Lunch 13:00 · Gym 16:30 · Dinner 20:00 · Rest 21:30")
                }
            }

            if let info = manager.lastInfo {
                Section {
                    Text(info)
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.ok)
                }
            }
            if let err = manager.lastError {
                Section {
                    Text(err)
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.warn)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.bg)
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await manager.bootstrap()
            await manager.refreshPendingCount()
        }
    }

    @ViewBuilder
    private func reminderRow(_ kind: ReminderKind) -> some View {
        let cfg = manager.settings.config(for: kind)
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: Binding(
                get: { cfg.enabled },
                set: { manager.setEnabled($0, for: kind) }
            )) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(kind.title)
                                .font(.system(size: 15, weight: .semibold))
                            Spacer()
                            if cfg.enabled {
                                Text(cfg.timeLabel())
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Palette.red)
                            }
                        }
                        Text(kind.body)
                            .font(.system(size: 11))
                            .foregroundStyle(Palette.faint)
                            .lineLimit(2)
                    }
                } icon: {
                    Image(systemName: kind.systemImage)
                        .foregroundStyle(Palette.red)
                        .frame(width: 22)
                }
            }
            .tint(Palette.red)

            if cfg.enabled {
                DatePicker(
                    "Time",
                    selection: Binding(
                        get: { cfg.asDate() },
                        set: { manager.setTime($0, for: kind) }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.vertical, 4)
    }
}
