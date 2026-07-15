import SwiftUI

struct ContentView: View {
    @ObservedObject private var store = AppDataStore.shared

    var body: some View {
        Group {
            if store.hasSeenOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .environmentObject(store)
        .preferredColorScheme(.dark)
        .clearHostingBackground()
        .animation(.easeInOut(duration: 0.3), value: store.hasSeenOnboarding)
    }
}

#Preview {
    ContentView()
}
