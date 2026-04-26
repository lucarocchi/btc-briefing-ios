import SwiftUI

// MARK: - Stato del segnale

enum SignalState {
    case neutro, watch, segnale, lontano

    var label: String {
        switch self {
        case .neutro:  return "NEUTRO"
        case .watch:   return "WATCH ⚠️"
        case .segnale: return "SEGNALE ✅"
        case .lontano: return "LONTANO"
        }
    }

    var color: Color {
        switch self {
        case .neutro:  return .gray
        case .watch:   return .yellow
        case .segnale: return .green
        case .lontano: return .gray
        }
    }
}

// MARK: - Segnale singolo

struct StrategySignal: Identifiable {
    let id: String          // "S01"…"S05"
    let name: String        // "BB SHORT"
    let direction: String   // "SHORT" / "LONG" / "—"
    let metric: String      // stringa metrica formattata
    let state: SignalState
}

// MARK: - Calcolo segnali dalle BriefingData

enum Strategies {

    static func compute(from b: BriefingData, sym: String) -> [StrategySignal] {
        var out = [StrategySignal]()

        // S01 — BB Upper SHORT (daily)
        // Segnale: RSI(14)daily > 70 AND lastDailyHigh > BBupper AND candela != bear
        let rsiD    = b.rsiDaily
        let distBBU = b.distFromBBUpperPct
        let isBearD = b.lastDailyType.contains("▼")

        let s01: SignalState
        if rsiD > 70 && b.lastDailyHigh > b.bbUpper && !isBearD {
            s01 = .segnale
        } else if rsiD > 65 || distBBU > -3 {
            s01 = .watch
        } else {
            s01 = .neutro
        }
        out.append(StrategySignal(
            id: "S01", name: "BB SHORT", direction: "SHORT",
            metric: "RSI \(fmt1(rsiD))  BBU \(fmtP(distBBU))",
            state: s01
        ))

        // S02 — EMA200 Proximity LONG (daily)
        // Segnale: close <= EMA200 AND close >= EMA200 * 0.98
        let distEMA = b.distFromEMA200Pct
        let s02: SignalState
        if distEMA <= 0 && distEMA >= -2 {
            s02 = .segnale
        } else if distEMA > 0 && distEMA <= 5 {
            s02 = .watch
        } else {
            s02 = .lontano
        }
        out.append(StrategySignal(
            id: "S02", name: "EMA LONG", direction: "LONG",
            metric: "EMA200 \(fmtP(distEMA))",
            state: s02
        ))

        // S03 — EMA200 Limit 4H
        // Segnale: |close4H - EMA200_4H| / EMA200_4H <= 5%
        let dist4h = b.ema200_4h > 0
            ? (b.price - b.ema200_4h) / b.ema200_4h * 100
            : 0
        let s03: SignalState
        if b.ema200_4h == 0 {
            s03 = .neutro
        } else if abs(dist4h) <= 1 {
            s03 = .segnale
        } else if abs(dist4h) <= 5 {
            s03 = .watch
        } else {
            s03 = .neutro
        }
        out.append(StrategySignal(
            id: "S03", name: "4H EMA", direction: "LONG",
            metric: b.ema200_4h > 0 ? "EMA200 4H \(fmtP(dist4h))" : "—",
            state: s03
        ))

        // S04 — EMA200 Weekly LONG
        // Segnale: lowWeekly tocca EMA200W AND prevClose > EMA200W AND !bear
        let s04: SignalState
        let distW: Double
        if b.ema200Weekly > 0 {
            distW = (b.lastWeeklyLow - b.ema200Weekly) / b.ema200Weekly * 100
            let isBearW = b.lastWeeklyType.contains("▼")
            if distW <= 0 && distW >= -2 && b.prevWeeklyClose > b.ema200Weekly && !isBearW {
                s04 = .segnale
            } else if abs(distW) <= 3 {
                s04 = .watch
            } else {
                s04 = .neutro
            }
        } else {
            distW = 0
            s04 = .neutro
        }
        out.append(StrategySignal(
            id: "S04", name: "Weekly", direction: "LONG",
            metric: b.ema200Weekly > 0 ? "EMA200W \(fmtP(distW))" : "—",
            state: s04
        ))

        return out
    }

    private static func fmt1(_ v: Double) -> String { String(format: "%.1f", v) }
    private static func fmtP(_ v: Double) -> String { String(format: "%+.1f%%", v) }
    private static func fmtN(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        f.groupingSeparator = ","
        return f.string(from: NSNumber(value: v)) ?? "\(Int(v))"
    }
}
