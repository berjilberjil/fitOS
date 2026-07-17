import SwiftUI

/// Custom tab bar with spring selection animation (system TabView is hard to animate).
struct MainTabView: View {
    @State private var tab = 0
    @Namespace private var tabNS

    private let tabs: [(title: String, icon: String)] = [
        ("Today", "flame.fill"),
        ("Food", "fork.knife"),
        ("Workout", "dumbbell.fill"),
        ("Progress", "chart.line.uptrend.xyaxis"),
        ("Profile", "person.fill"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch tab {
                case 0: TodayView()
                case 1: FoodView()
                case 2: WorkoutView()
                case 3: ProgressScreen()
                default: ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(response: 0.32, dampingFraction: 0.86), value: tab)

            animatedTabBar
        }
        .background(Palette.bg.ignoresSafeArea())
        .accessibilityIdentifier("main.tabs")
    }

    private var animatedTabBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { i in
                let selected = tab == i
                Button {
                    Haptics.tap()
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        tab = i
                    }
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if selected {
                                Capsule()
                                    .fill(Palette.redSoft)
                                    .matchedGeometryEffect(id: "tabPill", in: tabNS)
                                    .frame(width: 52, height: 32)
                            }
                            Image(systemName: tabs[i].icon)
                                .font(.system(size: 18, weight: selected ? .semibold : .regular))
                                .foregroundStyle(selected ? Palette.red : Palette.faint)
                                .scaleEffect(selected ? 1.08 : 1.0)
                        }
                        .frame(height: 32)

                        Text(tabs[i].title)
                            .font(.system(size: 10, weight: selected ? .bold : .medium))
                            .foregroundStyle(selected ? Palette.red : Palette.faint)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("tab.\(tabs[i].title.lowercased())")
            }
        }
        .background(
            Palette.surface
                .overlay(alignment: .top) {
                    Rectangle().fill(Palette.border).frame(height: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
