import Foundation

// CoinGecko free tier: ticker OK, OHLCV limitato (4h e 1d granularità)
struct CoinGeckoService: MarketService {

    private let baseURL = "https://api.coingecko.com/api/v3"

    func fetchTicker(pair: TradingPair) async throws -> TickerData {
        let vs = pair.coinGeckoVsCurrency
        let urlStr = "\(baseURL)/simple/price?ids=bitcoin&vs_currencies=\(vs)" +
                     "&include_24hr_high=true&include_24hr_low=true&include_24hr_change=true"
        let url = URL(string: urlStr)!
        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        guard let btc = json["bitcoin"] as? [String: Any],
              let price = btc[vs] as? Double
        else { throw ServiceError.parse("CoinGecko ticker") }

        // 24h high/low non disponibili nel free tier senza API key
        let high = btc["\(vs)_24h_high"] as? Double ?? price
        let low  = btc["\(vs)_24h_low"]  as? Double ?? price

        return TickerData(price: price, high24h: high, low24h: low)
    }

    // CoinGecko free: OHLCV disponibile per daily e 4h tramite /coins/bitcoin/ohlc
    // Non supporta 15m o 1h senza API key → fallback a Kraken per questi intervalli
    func fetchOHLCV(pair: TradingPair, interval: Int, count: Int) async throws -> [OHLCV] {
        switch interval {
        case 1440:
            return try await fetchDailyOHLCV(pair: pair, count: count)
        case 240:
            return try await fetchDailyOHLCV(pair: pair, count: count) // 4h non disponibile libero, approssimato
        default:
            // Per 15m e 1h usiamo Kraken come fallback
            return try await KrakenService().fetchOHLCV(pair: pair, interval: interval, count: count)
        }
    }

    private func fetchDailyOHLCV(pair: TradingPair, count: Int) async throws -> [OHLCV] {
        let vs = pair.coinGeckoVsCurrency
        // days=90 → granularità 4h; days=365 → daily
        let days = count > 90 ? 365 : 90
        let url = URL(string: "\(baseURL)/coins/bitcoin/ohlc?vs_currency=\(vs)&days=\(days)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let rows = try JSONSerialization.jsonObject(with: data) as! [[Double]]

        // CoinGecko OHLC: [timestamp_ms, open, high, low, close]
        return rows.suffix(count).map { row in
            OHLCV(
                time:   Int(row[0]) / 1000,
                open:   row[1],
                high:   row[2],
                low:    row[3],
                close:  row[4],
                volume: 0
            )
        }
    }
}
