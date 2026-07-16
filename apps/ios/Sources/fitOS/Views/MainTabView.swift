import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "flame.fill") }
            FoodView()
                .tabItem { Label("Food", systemImage: "fork.knife") }
            WorkoutView()
                .tabItem { Label("Workout", systemImage: "dumbbell.fill") }
            ProgressScreen()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .tint(Palette.red)
        .toolbarBackground(Palette.surface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }
}
