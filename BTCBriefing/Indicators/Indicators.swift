import Foundation

// Tutti i calcoli tecnici — logica identica al Python market_briefing.py

enum Indicators {

    // MARK: - EMA (k = 2/(span+1), seeded from first value)
    static func ema(_ values: [Double], span: Int) -> Double {
        guard !values.isEmpty else { return 0 }
        let k = 2.0 / Double(span + 1)
        var e = values[0]
        for v in values.dropFirst() {
            e = v * k + e * (1 - k)
        }
        return e
    }

    // MARK: - RSI con Wilder smoothing (identico al Python)
    static func rsi(_ closes: [Double], period: Int = 14) -> Double {
        guard closes.count > period else { return 50 }

        var deltas = [Double]()
        for i in 1..<closes.count {
            deltas.append(closes[i] - closes[i - 1])
        }
        let gains  = deltas.map { max($0, 0.0) }
        let losses = deltas.map { max(-$0, 0.0) }

        // Seed con SMA degli ultimi `period` valori
        let lastGains  = Array(gains.suffix(period))
        let lastLosses = Array(losses.suffix(period))
        var ag = lastGains.reduce(0, +) / Double(period)
        var al = lastLosses.reduce(0, +) / Double(period)

        // Wilder smoothing sugli ultimi period-1 (come il Python)
        let smoothGains  = Array(gains.suffix(period - 1))
        let smoothLosses = Array(losses.suffix(period - 1))
        for (g, l) in zip(smoothGains, smoothLosses) {
            ag = (ag * Double(period - 1) + g) / Double(period)
            al = (al * Double(period - 1) + l) / Double(period)
        }

        guard al != 0 else { return 100 }
        return 100 - 100 / (1 + ag / al)
    }

    // MARK: - Bollinger Bands (population std, ddof=0)
    static func bb(_ closes: [Double], period: Int = 20, stdMult: Double = 2.0)
        -> (lower: Double, mid: Double, upper: Double)
    {
        let last = Array(closes.suffix(period))
        guard last.count == period else {
            let mid = closes.last ?? 0
            return (mid, mid, mid)
        }
        let mid = last.reduce(0, +) / Double(period)
        let variance = last.map { ($0 - mid) * ($0 - mid) }.reduce(0, +) / Double(period)
        let std = variance.squareRoot()
        return (mid - stdMult * std, mid, mid + stdMult * std)
    }

    // MARK: - Classificazione candela
    static func candleChar(o: Double, h: Double, l: Double, c: Double) -> String {
        let body = c - o
        let rng  = h - l
        guard rng != 0 else { return "doji" }
        let bodyPct = abs(body) / rng
        if bodyPct > 0.7 { return body > 0 ? "marubozu ▲" : "marubozu ▼" }
        if body > 0 { return "bull ▲" }
        if body < 0 { return "bear ▼" }
        return "doji"
    }

    // MARK: - Livelli Fibonacci (swing high → low)
    static func fibLevels(swingLow: Double, swingHigh: Double) -> [(label: String, price: Double)] {
        let rng = swingHigh - swingLow
        return [
            ("23.6%", swingHigh - rng * 0.236),
            ("38.2%", swingHigh - rng * 0.382),
            ("50.0%", swingHigh - rng * 0.500),
            ("61.8%", swingHigh - rng * 0.618),
            ("78.6%", swingHigh - rng * 0.786),
        ]
    }

    // MARK: - Aggregazione daily → weekly (calendario ISO, lun-dom)
    static func aggregateWeekly(_ bars: [OHLCV]) -> [OHLCV] {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = TimeZone(identifier: "UTC")!

        var groups: [Int: [OHLCV]] = [:]
        var order:  [Int] = []

        for bar in bars {
            let c   = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: bar.date)
            let key = (c.yearForWeekOfYear ?? 0) * 100 + (c.weekOfYear ?? 0)
            if groups[key] == nil { order.append(key); groups[key] = [] }
            groups[key]!.append(bar)
        }

        // Escludi l'ultima settimana se non ancora chiusa (meno di 5 giorni trading)
        let completeOrder = order.dropLast()

        return completeOrder.compactMap { key -> OHLCV? in
            guard let g = groups[key], !g.isEmpty,
                  let first = g.first, let last = g.last else { return nil }
            return OHLCV(
                time: first.time,
                open: first.open,
                high: g.map { $0.high }.max()!,
                low:  g.map { $0.low  }.min()!,
                close: last.close,
                volume: g.reduce(0) { $0 + $1.volume }
            )
        }
    }

    // MARK: - Candela in formazione (aggrega 15m + prezzo live)
    static func buildFormingCandle(
        bars15m: [OHLCV],
        periodSeconds: Int,
        nowTs: Int,
        livePrice: Double
    ) -> OHLCV? {
        let periodStart = (nowTs / periodSeconds) * periodSeconds
        var bars = bars15m.filter { $0.time >= periodStart }

        let live = OHLCV(
            time: nowTs, open: livePrice, high: livePrice,
            low: livePrice, close: livePrice, volume: 0
        )
        bars.append(live)

        guard let first = bars.first else { return nil }
        return OHLCV(
            time: periodStart,
            open: first.open,
            high: bars.map { $0.high }.max()!,
            low:  bars.map { $0.low  }.min()!,
            close: livePrice,
            volume: bars.dropLast().reduce(0) { $0 + $1.volume },
            isForming: true
        )
    }

    // MARK: - Bias label (corrisponde a Python bias_label())
    static func biasLabel(
        price: Double, ema200: Double,
        bbl: Double, bbm: Double, bbu: Double,
        rsiVal: Double
    ) -> String {
        var score = 0
        if price > ema200  { score += 2 }
        if price > bbm     { score += 1 }
        if price > bbu     { score += 1 }
        if rsiVal > 60     { score += 1 }
        if rsiVal > 70     { score += 1 }
        if rsiVal < 40     { score -= 1 }
        if price < bbl     { score -= 1 }
        if price < bbm     { score -= 1 }
        if price < ema200  { score -= 2 }
        if score >= 3      { return "BULL 🟢" }
        if score <= -3     { return "BEAR 🔴" }
        return "NEUTRO 🟡"
    }

    // MARK: - Compute completo (orchestrato da BriefingEngine)
    static func compute(
        price: Double, high24h: Double, low24h: Double,
        bars15m: [OHLCV], bars1h: [OHLCV], bars4h: [OHLCV], bars1d: [OHLCV]
    ) -> BriefingData {
        let nowTs = Int(Date().timeIntervalSince1970)

        // Candele in formazione
        let forming1h = buildFormingCandle(bars15m: bars15m, periodSeconds: 3600,  nowTs: nowTs, livePrice: price)
        let forming4h = buildFormingCandle(bars15m: bars15m, periodSeconds: 14400, nowTs: nowTs, livePrice: price)
        let forming1d = buildFormingCandle(bars15m: bars15m, periodSeconds: 86400, nowTs: nowTs, livePrice: price)

        // Serie closes
        var closes1d = bars1d.map { $0.close }
        if let f = forming1d { closes1d.append(f.close) }

        var closes1h = bars1h.map { $0.close }
        if let f = forming1h { closes1h.append(f.close) }

        // Indicatori
        let ema200         = ema(closes1d, span: 200)
        let (bbl, bbm, bbu) = bb(closes1d, period: 20)
        let rsi14          = rsi(Array(closes1h.suffix(50)), period: 14)

        // Fibonacci: swing low/high degli ultimi 30 daily
        let recent30 = Array(bars1d.suffix(30))
        let swLow    = recent30.map { $0.low  }.min() ?? price
        let swHigh   = recent30.map { $0.high }.max() ?? price
        let rawFibs  = fibLevels(swingLow: swLow, swingHigh: swHigh)

        let fibs: [FibLevel] = rawFibs.map { (label, lvl) in
            let dist = lvl != 0 ? (price - lvl) / lvl * 100 : 0
            return FibLevel(label: label, price: lvl, distancePct: dist, isNear: abs(dist) < 1.5)
        }.sorted { $0.price > $1.price }

        let nearFib = fibs.filter { $0.isNear }.sorted { abs($0.distancePct) < abs($1.distancePct) }.first

        let bias = biasLabel(price: price, ema200: ema200, bbl: bbl, bbm: bbm, bbu: bbu, rsiVal: rsi14)

        // Variazione 24h (open dell'ultima daily chiusa)
        let open24h   = bars1d.last?.open ?? price
        let change24h = open24h != 0 ? (price - open24h) / open24h * 100 : 0

        // MARK: - Campi extra per Strategy Signals

        // S01: RSI su daily closes, high e tipo dell'ultima candela daily
        let rsiDaily    = rsi(Array(closes1d.suffix(50)), period: 14)
        let lastD       = bars1d.last
        let lastDHigh   = lastD?.high ?? 0
        let lastDType   = lastD.map { candleChar(o: $0.open, h: $0.high, l: $0.low, c: $0.close) } ?? ""

        // S03: EMA200 su close delle 4H
        let ema200_4h = ema(bars4h.map { $0.close }, span: 200)

        // S04: EMA200 su barre weekly aggregate
        let weeklyBars     = aggregateWeekly(bars1d)
        let weeklyCloses   = weeklyBars.map { $0.close }
        let ema200Weekly   = ema(weeklyCloses, span: 200)
        let lastWeekly     = weeklyBars.last
        let prevWeekly     = weeklyBars.dropLast().last
        let lastWLow       = lastWeekly?.low ?? 0
        let prevWClose     = prevWeekly?.close ?? 0
        let lastWType      = lastWeekly.map { candleChar(o: $0.open, h: $0.high, l: $0.low, c: $0.close) } ?? ""

        return BriefingData(
            timestamp: Date(),
            price: price,
            high24h: high24h,
            low24h: low24h,
            change24hPct: change24h,
            ema200: ema200,
            bbUpper: bbu,
            bbMid: bbm,
            bbLower: bbl,
            rsi1h: rsi14,
            bias: bias,
            candles4h: Array(bars4h.suffix(2)),
            forming4h: forming4h,
            candles1h: Array(bars1h.suffix(3)),
            forming1h: forming1h,
            swingLow: swLow,
            swingHigh: swHigh,
            fibLevels: fibs,
            nearestFib: nearFib,
            rsiDaily: rsiDaily,
            lastDailyHigh: lastDHigh,
            lastDailyType: lastDType,
            ema200_4h: ema200_4h,
            ema200Weekly: ema200Weekly,
            lastWeeklyLow: lastWLow,
            prevWeeklyClose: prevWClose,
            lastWeeklyType: lastWType
        )
    }
}
