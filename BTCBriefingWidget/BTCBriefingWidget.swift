import WidgetKit
import SwiftUI

// MARK: - Entry

struct BTCWidgetEntry: TimelineEntry {
    let date: Date
    let briefing: BriefingData?
}

// MARK: - Provider

struct BTCWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> BTCWidgetEntry {
        BTCWidgetEntry(date: Date(), briefing: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (BTCWidgetEntry) -> Void) {
        completion(BTCWidgetEntry(date: Date(), briefing: HistoryManager.loadLast()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BTCWidgetEntry>) -> Void) {
        var cached = HistoryManager.loadLast()
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!

        // Fetch ticker live per avere il prezzo aggiornato
        guard let url = URL(string: "https://api.kraken.com/0/public/Ticker?pair=XBTUSD") else {
            let timeline = Timeline(entries: [BTCWidgetEntry(date: Date(), briefing: cached)],
                                    policy: .after(next))
            completion(timeline)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let result = (json["result"] as? [String: Any])?.values.first as? [String: Any],
               let lastArr = result["c"] as? [String],
               let price = Double(lastArr[0]) {
                cached?.price = price
            }
            let entry = BTCWidgetEntry(date: Date(), briefing: cached)
            let timeline = Timeline(entries: [entry], policy: .after(next))
            completion(timeline)
        }.resume()
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: BTCWidgetEntry
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            Color.black
            if let b = entry.briefing {
                VStack(alignment: .leading, spacing: 4) {
                    Text("₿ BTC")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color(red: 0.97, green: 0.58, blue: 0.10))

                    Spacer()

                    Text("$\(formatNum(b.price, 0))")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)

                    Text(b.biasEmoji + " " + shortBias(b.bias))
                        .font(.system(size: 13, design: .monospaced))

                    Text(String(format: "%+.1f%%", b.change24hPct))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(b.change24hPct >= 0 ? .green : .red)
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            } else {
                Text("₿ --")
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: BTCWidgetEntry

    var body: some View {
        ZStack {
            Color.black
            if let b = entry.briefing {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("₿ BTC/USD")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(Color(red: 0.97, green: 0.58, blue: 0.10))
                        Spacer()
                        Text(formatTime(b.timestamp))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.gray)
                    }

                    HStack(alignment: .bottom, spacing: 8) {
                        Text("$\(formatNum(b.price, 0))")
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        Text(String(format: "%+.1f%%", b.change24hPct))
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(b.change24hPct >= 0 ? .green : .red)
                            .padding(.bottom, 2)
                    }

                    Divider().background(Color.gray.opacity(0.3))

                    HStack(spacing: 16) {
                        statItem("EMA200", "$\(formatNum(b.ema200, 0))", b.price > b.ema200 ? .green : .red)
                        statItem("BB↑", "$\(formatNum(b.bbUpper, 0))", .gray)
                        statItem("RSI", String(format: "%.0f", b.rsi1h), rsiColor(b.rsi1h))
                        Spacer()
                        Text(b.bias)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            } else {
                Text("₿ Loading...")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
    }

    private func statItem(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 9, design: .monospaced)).foregroundColor(.gray)
            Text(value).font(.system(size: 11, design: .monospaced)).foregroundColor(color)
        }
    }
}

// MARK: - Large Widget

struct LargeWidgetView: View {
    let entry: BTCWidgetEntry

    var body: some View {
        ZStack {
            Color.black
            if let b = entry.briefing {
                VStack(alignment: .leading, spacing: 4) {
                    // Header
                    HStack {
                        Text("₿ BTC BRIEFING")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 0.97, green: 0.58, blue: 0.10))
                        Spacer()
                        Text(formatTime(b.timestamp))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.gray)
                    }

                    Divider().background(Color.gray.opacity(0.3))

                    // Prezzo
                    HStack(alignment: .bottom, spacing: 8) {
                        Text("$\(formatNum(b.price, 1))")
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        Text(String(format: "%+.2f%%", b.change24hPct))
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(b.change24hPct >= 0 ? .green : .red)
                            .padding(.bottom, 4)
                    }

                    // Bias
                    Text(b.bias)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))

                    Divider().background(Color.gray.opacity(0.3))

                    // Indicatori
                    largeLine("EMA200", "$\(formatNum(b.ema200, 0))", b.price > b.ema200 ? .green : .red)
                    largeLine("BB ↑  ", "$\(formatNum(b.bbUpper, 0))", .gray)
                    largeLine("BB mid", "$\(formatNum(b.bbMid, 0))", .gray)
                    largeLine("BB ↓  ", "$\(formatNum(b.bbLower, 0))", .gray)
                    largeLine("RSI 1H", String(format: "%.1f", b.rsi1h), rsiColor(b.rsi1h))

                    // Fib vicino
                    if let near = b.nearestFib {
                        Divider().background(Color.gray.opacity(0.3))
                        Text("⚡ Fib \(near.label) @ $\(formatNum(near.price, 0))")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.yellow)
                    }

                    Spacer()
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            } else {
                Text("₿ Loading...")
                    .foregroundColor(.gray)
            }
        }
    }

    private func largeLine(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.gray)
                .frame(width: 60, alignment: .leading)
            Text(value)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(color)
        }
    }
}

// MARK: - Widget Definition

struct BTCBriefingWidget: Widget {
    let kind = "BTCBriefingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BTCWidgetProvider()) { entry in
            BTCWidgetEntryView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("BTC Briefing")
        .description("Real-time Bitcoin market data")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct BTCWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: BTCWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:  SmallWidgetView(entry: entry)
        case .systemMedium: MediumWidgetView(entry: entry)
        case .systemLarge:  LargeWidgetView(entry: entry)
        default:            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Helpers

private func formatNum(_ n: Double, _ dec: Int) -> String {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.minimumFractionDigits = dec
    f.maximumFractionDigits = dec
    f.groupingSeparator = ","
    return f.string(from: NSNumber(value: n)) ?? "\(n)"
}

private func formatTime(_ d: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "HH:mm"
    f.timeZone = TimeZone(identifier: "UTC")
    return f.string(from: d)
}

private func shortBias(_ bias: String) -> String {
    if bias.contains("BULL") { return "BULL" }
    if bias.contains("BEAR") { return "BEAR" }
    return "NEUTRO"
}

private func rsiColor(_ rsi: Double) -> Color {
    if rsi > 70 { return .red }
    if rsi < 30 { return .green }
    return Color(red: 0.0, green: 0.95, blue: 0.2)
}
