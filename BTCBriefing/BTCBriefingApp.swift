import SwiftUI

@main
struct BTCBriefingApp: App {
    @StateObject private var settings = AppSettings.shared

    init() {
        // Sopprime l'animazione "wide oval" di iOS 18 sul primo tap dei tab
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(white: 0.06, alpha: 1)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            RootView(settings: settings)
        }
    }
}

struct RootView: View {
    @ObservedObject var settings: AppSettings
    @State private var showIntro: Bool

    init(settings: AppSettings) {
        self.settings = settings
        _showIntro = State(initialValue: !settings.hasCompletedOnboarding)
    }

    var body: some View {
        if showIntro {
            IntroView(settings: settings) {
                withAnimation(.easeInOut(duration: 0.4)) { showIntro = false }
            }
        } else {
            ContentView(settings: settings)
        }
    }
}
