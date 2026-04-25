import Foundation

struct BinanceService: MarketService {

    private let baseURL = "https://api.binance.com/api/v3"

    func fetchTicker(pair: TradingPair) async throws -> TickerData {
        let symbol = pair.binanceSymbol
        let url = URL(string: "\(baseURL)/ticker/24hr?symbol=\(symbol)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        guard let lastPrice = json["lastPrice"] as? String,
              let highPrice = json["highPrice"] as? String,
              let lowPrice  = json["lowPrice"]  as? String
        else { throw ServiceError.parse("Binance ticker") }

        return TickerData(
            price:   Double(lastPrice) ?? 0,
            high24h: Double(highPrice) ?? 0,
            low24h:  Double(lowPrice)  ?? 0
        )
    }

    func fetchOHLCV(pair: TradingPair, interval: Int, count: Int) async throws -> [OHLCV] {
        let symbol = pair.binanceSymbol
        let intervalStr = binanceInterval(minutes: interval)
        let limit = min(count, 1000)
        let url = URL(string: "\(baseURL)/klines?symbol=\(symbol)&interval=\(intervalStr)&limit=\(limit)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let rows = try JSONSerialization.jsonObject(with: data) as! [[Any]]

        // Binance: [openTime, open, high, low, close, volume, closeTime, ...]
        // L'ultima barra può essere incompleta (close time nel futuro) — escludiamola
        return rows.dropLast().compactMap { row -> OHLCV? in
            guard row.count >= 6,
                  let t  = row[0] as? Int,
                  let o  = Double("\(row[1])"),
                  let h  = Double("\(row[2])"),
                  let l  = Double("\(row[3])"),
                  let c  = Double("\(row[4])"),
                  let v  = Double("\(row[5])")
            else { return nil }
            // Binance usa ms
            return OHLCV(time: t / 1000, open: o, high: h, low: l, close: c, volume: v)
        }
    }

    private func binanceInterval(minutes: Int) -> String {
        switch minutes {
        case 15:   return "15m"
        case 60:   return "1h"
        case 240:  return "4h"
        case 1440: return "1d"
        default:   return "\(minutes)m"
        }
    }
}
