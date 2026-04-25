import SwiftUI

// MARK: - Riga terminale

private struct TermLine: Identifiable {
    let id = UUID()
    let text: String
    let color: Color
    var bold: Bool = false
    var isSeparator: Bool = false
}

// MARK: - BriefingView

struct BriefingView: View {
    @ObservedObject var engine: BriefingEngine
    @ObservedObject var settings: AppSettings

    @State private var visibleLines: [TermLine] = []
    @State private var isRevealing = false
    @State private var cursorVisible = true
    @State private var cursorTimer: Timer?
    @State private var revealTask: Task<Void, Never>?

    private var theme: TerminalTheme { settings.theme }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            // Righe rivelate finora
                            ForEach(visibleLines) { line in
                                if line.isSeparator {
                                    Rectangle()
                                        .fill(line.color)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 1)
                                        .padding(.vertical, 3)
                                } else {
                                    Text(line.text.isEmpty ? " " : line.text)
                                        .font(.system(size: 13,
                                                      weight: line.bold ? .semibold : .regular,
                                                      design: .monospaced))
                                        .foregroundColor(line.text.isEmpty ? .clear : line.color)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }

                            // Cursore lampeggiante — visibile durante loading e reveal
                            if engine.isLoading || isRevealing {
                                Text("█")
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(theme.primaryColor)
                                    .opacity(cursorVisible ? 1 : 0)
                                    .id("cursor")
                            } else if !visibleLines.isEmpty {
                                // Cursore fisso a fine output
                                Text("█")
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(theme.primaryColor)
                                    .opacity(cursorVisible ? 0.6 : 0)
                                    .id("cursorIdle")
                            }

                            Color.clear.frame(height: 8).id("bottom")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .onChange(of: visibleLines.count) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                    .onChange(of: engine.isLoading) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }

                footerBar
            }
        }
        .onAppear {
            startCursorBlink()
            if engine.briefing == nil && !engine.isLoading {
                Task { await engine.refresh(settings: settings) }
            } else if let b = engine.briefing {
                // Mostra subito il briefing in cache senza animazione
                visibleLines = buildLines(from: b)
            }
        }
        .onDisappear {
            cursorTimer?.invalidate()
            revealTask?.cancel()
        }
        .onChange(of: engine.briefing?.timestamp) {
            if let b = engine.briefing {
                startReveal(briefing: b)
            }
        }
        .onChange(of: engine.isLoading) {
            if engine.isLoading {
                // Pulisce schermo e mostra messaggio di caricamento
                revealTask?.cancel()
                visibleLines = [
                    TermLine(text: NSLocalizedString("briefing.loading", comment: ""),
                             color: theme.primaryColor)
                ]
            }
        }
    }

    // MARK: - Reveal animato (riscrittura riga per riga)

    private func startReveal(briefing: BriefingData) {
        revealTask?.cancel()
        let lines = buildLines(from: briefing)

        // Pulisce schermo prima di riscrivere
        visibleLines = []
        isRevealing = true

        revealTask = Task {
            for line in lines {
                guard !Task.isCancelled else { break }
                let l = line
                await MainActor.run { visibleLines.append(l) }
                try? await Task.sleep(nanoseconds: 18_000_000) // ~55 righe/sec
            }
            await MainActor.run { isRevealing = false }
        }
    }

    // MARK: - Costruisce l'array di righe dal briefing

    private func buildLines(from b: BriefingData) -> [TermLine] {
        let sym = settings.pair.currencySymbol
        var lines = [TermLine]()

        func add(_ text: String, _ color: Color, bold: Bool = false) {
            lines.append(TermLine(text: text, color: color, bold: bold))
        }
        func sep() {
            lines.append(TermLine(text: "", color: theme.dimColor, isSeparator: true))
        }

        // Header
        if b.isCached {
            add("  " + NSLocalizedString("briefing.cached", comment: ""), .orange, bold: true)
        }
        sep()
        add("  MARKET BRIEFING — \(fmtDate(b.timestamp))", theme.primaryColor, bold: true)
        sep()
        add("", theme.primaryColor)
        add("  BTC/\(settings.pair == .btcUSD ? "USD" : "EUR") : \(sym)\(fmtN(b.price, 1))   (\(fmtP(b.change24hPct)) oggi)",
            theme.primaryColor)
        add("  24H     : H=\(sym)\(fmtN(b.high24h, 0))  L=\(sym)\(fmtN(b.low24h, 0))",
            theme.dimColor)
        add("", theme.primaryColor)

        // Indicatori
        if settings.showIndicators {
            add("  \(NSLocalizedString("briefing.indicators.daily", comment: ""))",
                theme.primaryColor, bold: true)
            add("  EMA200  : \(sym)\(fmtN(b.ema200, 0))  (\(fmtP(b.distFromEMA200Pct)))",
                b.price > b.ema200 ? theme.primaryColor : .red)
            add("  BB upper: \(sym)\(fmtN(b.bbUpper, 0))  (\(fmtP(b.distFromBBUpperPct)))",
                theme.dimColor)
            add("  BB mid  : \(sym)\(fmtN(b.bbMid, 0))", theme.dimColor)
            add("  BB lower: \(sym)\(fmtN(b.bbLower, 0))", theme.dimColor)
            add("  RSI 1H  : \(String(format: "%.1f", b.rsi1h))", rsiColor(b.rsi1h))
            add("", theme.primaryColor)
        }

        // Bias
        add("  \(NSLocalizedString("briefing.bias", comment: ""))",
            theme.primaryColor, bold: true)
        add("  \(b.bias)", biasColor(b.bias), bold: true)
        add("", theme.primaryColor)

        // Candele
        if settings.showCandles {
            add("  \(NSLocalizedString("briefing.candles4h", comment: ""))",
                theme.primaryColor, bold: true)
            for c in b.candles4h {
                add("  \(candleLine(c, sym: sym))",
                    c.changePct >= 0 ? theme.primaryColor : .red)
            }
            if let f = b.forming4h {
                add("  \(candleLine(f, sym: sym))  ← \(NSLocalizedString("briefing.forming", comment: ""))",
                    theme.dimColor)
            }
            add("", theme.primaryColor)

            add("  \(NSLocalizedString("briefing.candles1h", comment: ""))",
                theme.primaryColor, bold: true)
            for c in b.candles1h {
                add("  \(candle1hLine(c, sym: sym))",
                    c.changePct >= 0 ? theme.primaryColor : .red)
            }
            if let f = b.forming1h {
                add("  \(candle1hLine(f, sym: sym))  ← \(NSLocalizedString("briefing.forming", comment: ""))",
                    theme.dimColor)
            }
            add("", theme.primaryColor)
        }

        // Fibonacci
        if settings.showFibonacci {
            add("  \(NSLocalizedString("briefing.fib", comment: "")) (swing \(sym)\(fmtN(b.swingLow, 0))→\(sym)\(fmtN(b.swingHigh, 0)))",
                theme.primaryColor, bold: true)
            for fib in b.fibLevels {
                let arrow  = fib.isAbove ? "▲" : "▼"
                let marker = fib.isNear  ? "  ← SEI QUI" : ""
                add("  Fib \(fib.label): \(sym)\(fmtN(fib.price, 0))  (\(fmtP(fib.distancePct)))  \(arrow)\(marker)",
                    fib.isNear ? .yellow : theme.dimColor)
            }
            if let near = b.nearestFib {
                add("", theme.primaryColor)
                add("  ⚡ Fib vicino: \(near.label) @ \(sym)\(fmtN(near.price, 0)) (dist \(fmtP(near.distancePct)))",
                    .yellow, bold: true)
            }
        }

        add("", theme.primaryColor)
        sep()
        return lines
    }

    // MARK: - Header / Footer

    private var headerBar: some View {
        HStack {
            Circle().fill(Color.red).frame(width: 12, height: 12)
            Circle().fill(Color.yellow).frame(width: 12, height: 12)
            Circle().fill(Color.green).frame(width: 12, height: 12)
            Spacer()
            Text("btc-briefing — \(settings.provider.displayName)")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)
            Spacer()
            if engine.isLoading {
                ProgressView().scaleEffect(0.6).tint(theme.primaryColor)
            } else {
                Button {
                    Task { await engine.refresh(settings: settings) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundColor(theme.dimColor)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(white: 0.08))
    }

    private var footerBar: some View {
        HStack {
            Spacer()
            if engine.nextRefreshIn > 0 {
                Text("\(NSLocalizedString("briefing.refresh", comment: "")) \(fmtCountdown(engine.nextRefreshIn))")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(theme.dimColor)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(white: 0.06))
    }

    // MARK: - Cursore

    private func startCursorBlink() {
        cursorTimer?.invalidate()
        cursorTimer = Timer.scheduledTimer(withTimeInterval: 0.55, repeats: true) { _ in
            cursorVisible.toggle()
        }
    }

    // MARK: - Colori

    private func biasColor(_ bias: String) -> Color {
        if bias.contains("BULL") { return .green }
        if bias.contains("BEAR") { return .red }
        return .yellow
    }
    private func rsiColor(_ rsi: Double) -> Color {
        if rsi > 70 { return .red }
        if rsi < 30 { return .green }
        return theme.primaryColor
    }

    // MARK: - Formatters

    private func fmtDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.string(from: d) + " UTC"
    }
    private func fmtN(_ n: Double, _ dec: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = dec
        f.maximumFractionDigits = dec
        f.groupingSeparator = ","
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }
    private func fmtP(_ p: Double) -> String { String(format: "%+.1f%%", p) }
    private func fmtCountdown(_ t: TimeInterval) -> String {
        String(format: "%02d:%02d", Int(t) / 60, Int(t) % 60)
    }
    private func candleLine(_ c: OHLCV, sym: String) -> String {
        "\(shortDate(c.date))  O=\(sym)\(fmtN(c.open,0)) H=\(sym)\(fmtN(c.high,0)) L=\(sym)\(fmtN(c.low,0)) C=\(sym)\(fmtN(c.close,0))  \(fmtP(c.changePct))  \(c.characterization)"
    }
    private func candle1hLine(_ c: OHLCV, sym: String) -> String {
        "\(shortDate(c.date))  C=\(sym)\(fmtN(c.close,0))  \(fmtP(c.changePct))  \(c.characterization)"
    }
    private func shortDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MM/dd HH:mm"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.string(from: d)
    }
}
