import Foundation

// MARK: - OHLCV Raw Candle

struct OHLCV: Codable, Identifiable {
    var time: Int
    var open: Double
    var high: Double
    var low: Double
    var close: Double
    var volume: Double
    var isForming: Bool = false

    var id: Int { time }

    var changePct: Double {
        guard open != 0 else { return 0 }
        return (close - open) / open * 100
    }

    var characterization: String {
        let body = close - open
        let rng  = high - low
        guard rng != 0 else { return "doji" }
        let bodyPct = abs(body) / rng
        if bodyPct > 0.7 { return body > 0 ? "marubozu ▲" : "marubozu ▼" }
        if body > 0 { return "bull ▲" }
        if body < 0 { return "bear ▼" }
        return "doji"
    }

    var date: Date { Date(timeIntervalSince1970: TimeInterval(time)) }
}

// MARK: - Fibonacci Level

struct FibLevel: Codable, Identifiable {
    var label: String
    var price: Double
    var distancePct: Double   // (currentPrice - levelPrice) / levelPrice * 100
    var isNear: Bool          // abs(dist) < 1.5%

    var id: String { label }
    var isAbove: Bool { distancePct > 0 }
}

// MARK: - Ticker

struct TickerData {
    var price: Double
    var high24h: Double
    var low24h: Double
}

// MARK: - Complete Briefing

struct BriefingData: Codable {
    var timestamp: Date
    var price: Double
    var high24h: Double
    var low24h: Double
    var change24hPct: Double

    // Daily indicators (calcolati su candele daily live)
    var ema200: Double
    var bbUpper: Double
    var bbMid: Double
    var bbLower: Double
    var rsi1h: Double

    var bias: String

    // Candele recenti
    var candles4h: [OHLCV]
    var forming4h: OHLCV?
    var candles1h: [OHLCV]
    var forming1h: OHLCV?

    // Fibonacci
    var swingLow: Double
    var swingHigh: Double
    var fibLevels: [FibLevel]
    var nearestFib: FibLevel?

    var isCached: Bool = false

    // Campi extra per Strategy Signals (default per compatibilità con cache esistente)
    var rsiDaily: Double = 50
    var lastDailyHigh: Double = 0
    var lastDailyType: String = ""
    var ema200_4h: Double = 0
    var ema200Weekly: Double = 0
    var lastWeeklyLow: Double = 0
    var prevWeeklyClose: Double = 0
    var lastWeeklyType: String = ""

    // Helper per distanza % da EMA200 e BB
    var distFromEMA200Pct: Double {
        guard ema200 != 0 else { return 0 }
        return (price - ema200) / ema200 * 100
    }
    var distFromBBUpperPct: Double {
        guard bbUpper != 0 else { return 0 }
        return (price - bbUpper) / bbUpper * 100
    }

    var biasEmoji: String {
        if bias.contains("BULL") { return "🟢" }
        if bias.contains("BEAR") { return "🔴" }
        return "🟡"
    }
}
