import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var engine: BriefingEngine

    private var rowBg: Color { Color(white: 0.10) }
    private var headerColor: Color { settings.theme.dimColor }
    private var fg: Color { settings.theme.primaryColor }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                List {
                    // MARK: Provider
                    darkSection(header: NSLocalizedString("settings.provider", comment: "")) {
                        segmentRow(selection: $settings.provider, cases: DataProvider.allCases, label: \.displayName)
                    }

                    // MARK: Coppia
                    darkSection(header: NSLocalizedString("settings.pair", comment: "")) {
                        segmentRow(selection: $settings.pair, cases: TradingPair.allCases, label: \.displayName)
                    }

                    // MARK: Intervallo refresh
                    darkSection(header: NSLocalizedString("settings.interval", comment: "")) {
                        segmentRow(selection: $settings.refreshInterval, cases: RefreshInterval.allCases, label: \.displayName)
                    }

                    // MARK: Tema terminale
                    darkSection(header: NSLocalizedString("settings.theme", comment: "")) {
                        segmentRow(selection: $settings.theme, cases: TerminalTheme.allCases, label: \.displayName)

                        // Anteprima
                        HStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(settings.theme.primaryColor)
                                .frame(width: 20, height: 20)
                            Text("█▓░ Preview")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(settings.theme.primaryColor)
                        }
                        .listRowBackground(rowBg)
                    }

                    // MARK: Sezioni visibili
                    darkSection(header: NSLocalizedString("settings.sections", comment: "")) {
                        darkToggle(NSLocalizedString("section.indicators", comment: ""), isOn: $settings.showIndicators)
                        darkToggle(NSLocalizedString("section.candles", comment: ""),    isOn: $settings.showCandles)
                        darkToggle(NSLocalizedString("section.fibonacci", comment: ""),  isOn: $settings.showFibonacci)
                    }

                    // MARK: Notifiche
                    darkSection(header: NSLocalizedString("settings.notifications", comment: "")) {
                        darkToggle(NSLocalizedString("settings.notif.enabled", comment: ""), isOn: $settings.notificationsEnabled)
                            .onChange(of: settings.notificationsEnabled) { _, enabled in
                                if enabled { NotificationManager.shared.requestAuthorization() }
                            }
                    }

                    // MARK: Aggiorna ora
                    Section {
                        Button(action: {
                            Task { await engine.refresh(settings: settings) }
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text(NSLocalizedString("briefing.refresh.now", comment: ""))
                            }
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(fg)
                            .frame(maxWidth: .infinity)
                        }
                        .listRowBackground(rowBg)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color.black)
            }
            .navigationTitle(NSLocalizedString("settings.title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color(white: 0.06), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func darkSection<Content: View>(header: String, @ViewBuilder content: () -> Content) -> some View {
        Section(header:
            Text(header)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(headerColor)
                .textCase(nil)
        ) {
            content()
        }
    }

    @ViewBuilder
    private func segmentRow<T: Hashable & CaseIterable>(
        selection: Binding<T>,
        cases: T.AllCases,
        label: KeyPath<T, String>
    ) -> some View where T.AllCases: RandomAccessCollection {
        Picker("", selection: selection) {
            ForEach(Array(cases), id: \.self) { item in
                Text(item[keyPath: label]).tag(item)
            }
        }
        .pickerStyle(.segmented)
        .listRowBackground(rowBg)
    }

    @ViewBuilder
    private func darkToggle(_ label: String, isOn: Binding<Bool>) -> some View {
        Toggle(label, isOn: isOn)
            .font(.system(size: 14, design: .monospaced))
            .foregroundColor(fg)
            .tint(fg)
            .listRowBackground(rowBg)
    }
}
