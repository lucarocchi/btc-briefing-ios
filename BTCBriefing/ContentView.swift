import SwiftUI

struct ContentView: View {
    @ObservedObject var settings: AppSettings
    @StateObject private var engine = BriefingEngine()
    @StateObject private var history = HistoryManager.shared

    var body: some View {
        TabView {
            BriefingView(engine: engine, settings: settings)
                .tabItem {
                    Label(NSLocalizedString("tab.briefing", comment: ""), systemImage: "terminal")
                }

            HistoryView(history: history, settings: settings)
                .tabItem {
                    Label(NSLocalizedString("tab.history", comment: ""), systemImage: "clock.arrow.circlepath")
                }

            SettingsView(settings: settings, engine: engine)
                .tabItem {
                    Label(NSLocalizedString("tab.settings", comment: ""), systemImage: "gearshape")
                }

            SignalsView(engine: engine, settings: settings)
                .tabItem {
                    Label(NSLocalizedString("tab.signals", comment: ""), systemImage: "chart.xyaxis.line")
                }

            AboutView(settings: settings)
                .tabItem {
                    Label(NSLocalizedString("tab.about", comment: ""), systemImage: "info.circle")
                }
        }
        // Forza dark mode per tutta l'app: tab bar, navigation bar e content
        // restano coerenti indipendentemente dalle impostazioni del device
        .preferredColorScheme(.dark)
        .tint(settings.theme.primaryColor)
        .onAppear {
            engine.startAutoRefresh(settings: settings)
        }
        .onChange(of: settings.refreshInterval) {
            engine.startAutoRefresh(settings: settings)
        }
        .onChange(of: settings.provider) {
            Task { await engine.refresh(settings: settings) }
        }
        .onChange(of: settings.pair) {
            Task { await engine.refresh(settings: settings) }
        }
    }
}
