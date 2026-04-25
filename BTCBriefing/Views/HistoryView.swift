import SwiftUI

struct HistoryView: View {
    @ObservedObject var history: HistoryManager
    @ObservedObject var settings: AppSettings

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                if history.entries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "terminal")
                            .font(.system(size: 48))
                            .foregroundColor(settings.theme.dimColor)
                        Text(NSLocalizedString("history.empty", comment: ""))
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(settings.theme.dimColor)
                    }
                } else {
                    List {
                        ForEach(history.entries) { entry in
                            NavigationLink(destination: HistoryDetailView(briefing: entry, settings: settings)) {
                                historyRow(entry)
                            }
                            .listRowBackground(Color(white: 0.06))
                        }
                        .onDelete { indices in
                            history.entries.remove(atOffsets: indices)
                        }
                    }
                    .listStyle(.plain)
                    .background(Color.black)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle(NSLocalizedString("history.title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !history.entries.isEmpty {
                        Button(NSLocalizedString("history.clear", comment: "")) {
                            history.clear()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
    }

    private func historyRow(_ b: BriefingData) -> some View {
        let sym = b.price > 50000 ? "$" : "€"
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(formatDate(b.timestamp))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(settings.theme.dimColor)
                Spacer()
                Text(b.biasEmoji)
                    .font(.system(size: 18))
            }
            HStack {
                Text("\(sym)\(formatNum(b.price, 1))")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(settings.theme.primaryColor)
                Text(String(format: "%+.2f%%", b.change24hPct))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(b.change24hPct >= 0 ? .green : .red)
            }
            Text("EMA200 \(sym)\(formatNum(b.ema200, 0))  RSI \(String(format: "%.1f", b.rsi1h))")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(settings.theme.dimColor)
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MM/dd HH:mm"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.string(from: d) + " UTC"
    }

    private func formatNum(_ n: Double, _ dec: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = dec
        f.maximumFractionDigits = dec
        f.groupingSeparator = ","
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}

// MARK: - Detail view (mostra il briefing completo in stile terminale)

struct HistoryDetailView: View {
    let briefing: BriefingData
    let settings: AppSettings

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                BriefingTextView(briefing: briefing, settings: settings)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .navigationTitle(formatDate(briefing.timestamp))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MM/dd HH:mm"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.string(from: d)
    }
}

// MARK: - Testo briefing riusabile (usato anche in HistoryDetailView)

struct BriefingTextView: View {
    let briefing: BriefingData
    let settings: AppSettings

    private var theme: TerminalTheme { settings.theme }
    private var sym: String { settings.pair.currencySymbol }

    var body: some View {
        let b = briefing
        let sep = String(repeating: "═", count: 56)

        VStack(alignment: .leading, spacing: 0) {
            tl(sep, dim: true)
            tl("  MARKET BRIEFING — \(fmtDate(b.timestamp))", bold: true)
            tl(sep, dim: true)
            tl("")
            tl("  BTC: \(sym)\(fmtN(b.price, 1))  (\(fmtP(b.change24hPct)))")
            tl("  24H: H=\(sym)\(fmtN(b.high24h, 0))  L=\(sym)\(fmtN(b.low24h, 0))", dim: true)
            tl("")
            tl("  EMA200 : \(sym)\(fmtN(b.ema200, 0))  (\(fmtP(b.distFromEMA200Pct)))", dim: true)
            tl("  BB  ↑  : \(sym)\(fmtN(b.bbUpper, 0))", dim: true)
            tl("  BB mid : \(sym)\(fmtN(b.bbMid, 0))", dim: true)
            tl("  BB  ↓  : \(sym)\(fmtN(b.bbLower, 0))", dim: true)
            tl("  RSI 1H : \(String(format: "%.1f", b.rsi1h))", dim: true)
            tl("")
            tl("  \(b.bias)", bold: true)
            tl(sep, dim: true)
        }
    }

    @ViewBuilder
    private func tl(_ text: String, bold: Bool = false, dim: Bool = false) -> some View {
        Text(text.isEmpty ? " " : text)
            .font(.system(size: 12, weight: bold ? .semibold : .regular, design: .monospaced))
            .foregroundColor(dim ? theme.dimColor : theme.primaryColor)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func fmtDate(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd HH:mm"; f.timeZone = TimeZone(identifier: "UTC")
        return f.string(from: d) + " UTC"
    }
    private func fmtN(_ n: Double, _ dec: Int) -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal
        f.minimumFractionDigits = dec; f.maximumFractionDigits = dec
        f.groupingSeparator = ","
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }
    private func fmtP(_ p: Double) -> String { String(format: "%+.1f%%", p) }
}

extension BriefingData: Identifiable {
    var id: Date { timestamp }
}
