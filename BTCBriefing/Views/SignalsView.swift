import SwiftUI

// MARK: - SignalsView

struct SignalsView: View {
    @ObservedObject var engine: BriefingEngine
    @ObservedObject var settings: AppSettings

    @State private var visibleLines: [SLine] = []
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

                            if engine.isLoading || isRevealing {
                                Text("█")
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(theme.primaryColor)
                                    .opacity(cursorVisible ? 1 : 0)
                                    .id("cursor")
                            } else if !visibleLines.isEmpty {
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
                }

                footerBar
            }
        }
        .onAppear {
            startCursorBlink()
            if let b = engine.briefing {
                visibleLines = buildLines(from: b)
            }
        }
        .onDisappear {
            cursorTimer?.invalidate()
            revealTask?.cancel()
        }
        .onChange(of: engine.briefing?.timestamp) {
            if let b = engine.briefing { startReveal(briefing: b) }
        }
        .onChange(of: engine.isLoading) {
            if engine.isLoading {
                revealTask?.cancel()
                visibleLines = [SLine(text: NSLocalizedString("briefing.loading", comment: ""),
                                     color: theme.primaryColor)]
            }
        }
    }

    // MARK: - Reveal

    private func startReveal(briefing: BriefingData) {
        revealTask?.cancel()
        let lines = buildLines(from: briefing)
        visibleLines = []
        isRevealing = true
        revealTask = Task {
            for line in lines {
                guard !Task.isCancelled else { break }
                let l = line
                await MainActor.run { visibleLines.append(l) }
                try? await Task.sleep(nanoseconds: 18_000_000)
            }
            await MainActor.run { isRevealing = false }
        }
    }

    // MARK: - Build lines

    private func buildLines(from b: BriefingData) -> [SLine] {
        let sym     = settings.pair.currencySymbol
        let signals = Strategies.compute(from: b, sym: sym)
        var lines   = [SLine]()

        func add(_ text: String, _ color: Color, bold: Bool = false) {
            lines.append(SLine(text: text, color: color, bold: bold))
        }
        func sep() {
            lines.append(SLine(text: "", color: theme.dimColor, isSeparator: true))
        }

        sep()
        add("  STRATEGY SIGNALS — \(fmtDate(b.timestamp))", theme.primaryColor, bold: true)
        sep()
        add("", theme.primaryColor)

        for signal in signals {
            // Header riga: "  S01 BB SHORT   (SHORT)"
            let header = "  \(pad(signal.id, 4))\(pad(signal.name, 12))(\(signal.direction))"
            add(header, theme.dimColor)

            // Metrica + stato
            let metricPad = pad(signal.metric, 32)
            let row = "  \(metricPad)→ \(signal.state.label)"
            add(row, signal.state.color, bold: signal.state == .segnale)

            add("", theme.primaryColor)
        }

        // Legenda
        sep()
        add("  NEUTRO  nessuna condizione attiva", theme.dimColor)
        add("  WATCH   vicino al trigger (< 5%)", .yellow)
        add("  SEGNALE condizioni soddisfatte", .green)
        add("  LONTANO fuori zona trigger",       theme.dimColor)
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
            Text("btc-briefing — signals")
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

    // MARK: - Formatters

    private func pad(_ s: String, _ len: Int) -> String {
        s.padding(toLength: len, withPad: " ", startingAt: 0)
    }
    private func fmtDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.string(from: d) + " UTC"
    }
    private func fmtCountdown(_ t: TimeInterval) -> String {
        String(format: "%02d:%02d", Int(t) / 60, Int(t) % 60)
    }
}

// MARK: - Riga locale (evita conflitti con TermLine in BriefingView)

private struct SLine: Identifiable {
    let id = UUID()
    let text: String
    let color: Color
    var bold: Bool = false
    var isSeparator: Bool = false
}
