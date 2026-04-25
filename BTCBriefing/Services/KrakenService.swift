import Foundation

struct KrakenService: MarketService {

    private let baseURL = "https://api.kraken.com/0/public"

    func fetchTicker(pair: TradingPair) async throws -> TickerData {
        let url = URL(string: "\(baseURL)/Ticker?pair=\(pair.krakenPair)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        guard let result = json["result"] as? [String: Any],
              let tick = result[pair.krakenResultKey] as? [String: Any],
              let cArr = tick["c"] as? [Any], let c0 = cArr.first as? String,
              let hArr = tick["h"] as? [Any], let h0 = hArr.first as? String,
              let lArr = tick["l"] as? [Any], let l0 = lArr.first as? String
        else { throw ServiceError.parse("Kraken ticker") }

        return TickerData(
            price:   Double(c0) ?? 0,
            high24h: Double(h0) ?? 0,
            low24h:  Double(l0) ?? 0
        )
    }

    func fetchOHLCV(pair: TradingPair, interval: Int, count: Int) async throws -> [OHLCV] {
        // Kraken restituisce max 720 barre; per daily 720 giorni è sufficiente per EMA200
        let url = URL(string: "\(baseURL)/OHLC?pair=\(pair.krakenPair)&interval=\(interval)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        guard let result = json["result"] as? [String: Any],
              let bars = result[pair.krakenResultKey] as? [[Any]]
        else { throw ServiceError.parse("Kraken OHLCV") }

        // Ultima barra è la candela in formazione — la escludiamo dalle chiuse
        let closed = bars.dropLast()
        return closed.suffix(count).compactMap { row -> OHLCV? in
            guard row.count >= 7,
                  let t = row[0] as? Int,
                  let o = Double("\(row[1])"),
                  let h = Double("\(row[2])"),
                  let l = Double("\(row[3])"),
                  let c = Double("\(row[4])"),
                  let v = Double("\(row[6])")
            else { return nil }
            return OHLCV(time: t, open: o, high: h, low: l, close: c, volume: v)
        }
    }
}
