import SwiftUI

struct AboutView: View {
    @ObservedObject var settings: AppSettings
    @State private var copied = false

    private let btcAddress = "bc1qxfpsdm9urjnvrzza4n3wyautp9jxd4mjcp7uwr"
    private var theme: TerminalTheme { settings.theme }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        // MARK: App info
                        block(header: nil) {
                            HStack {
                                Text("₿")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(Color(red: 0.97, green: 0.58, blue: 0.10))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("BTC Briefing")
                                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                    Text("v1.0  •  iOS 17+")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(theme.dimColor)
                                }
                            }
                            .padding(.bottom, 4)
                        }

                        divider()

                        // MARK: Disclaimer
                        block(header: NSLocalizedString("about.disclaimer.header", comment: "")) {
                            Text(NSLocalizedString("about.disclaimer.text", comment: ""))
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(theme.dimColor)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        divider()

                        // MARK: Data sources
                        block(header: NSLocalizedString("about.sources.header", comment: "")) {
                            sourceRow("Kraken",    "api.kraken.com  (default)")
                            sourceRow("Binance",   "api.binance.com")
                            sourceRow("CoinGecko", "api.coingecko.com")
                            Text(NSLocalizedString("about.sources.note", comment: ""))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(theme.dimColor.opacity(0.6))
                                .padding(.top, 6)
                        }

                        divider()

                        // MARK: Support development (BTC — discreto)
                        block(header: NSLocalizedString("about.support.header", comment: "")) {
                            Text(NSLocalizedString("about.support.text", comment: ""))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(theme.dimColor)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.bottom, 12)

                            // Indirizzo
                            Text(btcAddress)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(theme.dimColor)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.bottom, 8)

                            // Copia
                            Button(action: copyAddress) {
                                HStack(spacing: 6) {
                                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                    Text(copied
                                         ? NSLocalizedString("about.copied", comment: "")
                                         : NSLocalizedString("about.copy", comment: ""))
                                }
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(copied ? .green : theme.primaryColor)
                            }
                            .animation(.easeInOut(duration: 0.2), value: copied)
                        }

                        divider()

                        // MARK: Footer
                        Text("© 2025 • Open source • Public APIs only")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(theme.dimColor.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 16)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .navigationTitle(NSLocalizedString("tab.about", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func block(header: String?, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let header {
                Text(header)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(theme.dimColor)
                    .kerning(1.5)
            }
            content()
        }
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private func divider() -> some View {
        Rectangle()
            .fill(theme.dimColor.opacity(0.3))
            .frame(maxWidth: .infinity)
            .frame(height: 1)
    }

    @ViewBuilder
    private func sourceRow(_ name: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Text(name.padding(toLength: 12, withPad: " ", startingAt: 0))
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(theme.primaryColor)
            Text(detail)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(theme.dimColor)
        }
    }

    private func copyAddress() {
        UIPasteboard.general.string = btcAddress
        withAnimation { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { copied = false }
        }
    }

}
