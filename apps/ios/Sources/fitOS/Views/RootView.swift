import SwiftUI

struct RootView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.scenePhase) private var scenePhase
    @State private var unlocked = false

    var body: some View {
        ZStack {
            Palette.bg.ignoresSafeArea()
            switch state.phase {
            case .loading:
                VStack(spacing: 14) {
                    Text("fitOS")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.text)
                    ProgressView().tint(Palette.red)
                }
            case .loggedOut:
                LoginView()
            case .loggedIn:
                if BiometricLock.isEnabled && !unlocked {
                    LockView { await tryUnlock() }
                } else {
                    MainTabView()
                }
            }
        }
        .task { await state.bootstrap() }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background { unlocked = false }
        }
    }

    private func tryUnlock() async {
        unlocked = await BiometricLock.authenticate()
    }
}

/// Full-screen biometric lock shown when the Face ID lock is enabled.
struct LockView: View {
    let unlock: () async -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "lock.fill").font(.system(size: 46)).foregroundStyle(Palette.red)
            Text("fitOS is locked").font(.system(size: 20, weight: .bold)).foregroundStyle(Palette.text)
            Button { Task { await unlock() } } label: {
                Text("Unlock with \(BiometricLock.biometryName)")
                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                    .padding(.horizontal, 22).padding(.vertical, 13)
                    .background(Palette.red).clipShape(Capsule())
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.bg.ignoresSafeArea())
        .task { await unlock() }
    }
}
