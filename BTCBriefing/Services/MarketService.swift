import Foundation

// MARK: - Protocol

protocol MarketService {
    func fetchTicker(pair: TradingPair) async throws -> TickerData
    func fetchOHLCV(pair: TradingPair, interval: Int, count: Int) async throws -> [OHLCV]
}

// MARK: - Errori

enum ServiceError: LocalizedError {
    case parse(String)
    case network(String)
    case noData

    var errorDescription: String? {
        switch self {
        case .parse(let ctx):   return "Parse error: \(ctx)"
        case .network(let msg): return "Network error: \(msg)"
        case .noData:           return "No data available"
        }
    }
}

// MARK: - Factory

extension DataProvider {
    func makeService() -> any MarketService {
        switch self {
        case .kraken:  return KrakenService()
        case .binance: return BinanceService()
        }
    }
}
