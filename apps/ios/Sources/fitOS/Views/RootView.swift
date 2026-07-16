import SwiftUI

struct RootView: View {
    @EnvironmentObject var state: AppState

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
                MainTabView()
            }
        }
        .task { await state.bootstrap() }
    }
}
