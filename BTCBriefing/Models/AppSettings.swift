import SwiftUI

// MARK: - Enums

enum DataProvider: String, CaseIterable, Codable {
    case kraken = "Kraken"
    case binance = "Binance"

    var displayName: String { rawValue }
}

enum TradingPair: String, CaseIterable, Codable {
    case btcUSD = "BTC/USD"
    case btcEUR = "BTC/EUR"

    var displayName: String { rawValue }

    // Identificatori per ogni provider
    var krakenPair: String {
        switch self {
        case .btcUSD: return "XBTUSD"
        case .btcEUR: return "XBTEUR"
        }
    }
    var krakenResultKey: String {
        switch self {
        case .btcUSD: return "XXBTZUSD"
        case .btcEUR: return "XXBTZEUR"
        }
    }
    var binanceSymbol: String {
        switch self {
        case .btcUSD: return "BTCUSDT"
        case .btcEUR: return "BTCEUR"
        }
    }
    var currencySymbol: String {
        switch self {
        case .btcUSD: return "$"
        case .btcEUR: return "€"
        }
    }
}

enum RefreshInterval: Int, CaseIterable, Codable {
    case fifteenMin = 15
    case thirtyMin = 30
    case oneHour = 60

    var displayName: String {
        switch self {
        case .fifteenMin: return "15m"
        case .thirtyMin: return "30m"
        case .oneHour: return "1h"
        }
    }
    var seconds: TimeInterval { TimeInterval(rawValue * 60) }
}

enum TerminalTheme: String, CaseIterable, Codable {
    case green = "Green"
    case amber = "Amber"
    case white = "White"

    var displayName: String { rawValue }

    var primaryColor: Color {
        switch self {
        case .green: return Color(red: 0.0, green: 0.95, blue: 0.2)
        case .amber: return Color(red: 1.0, green: 0.70, blue: 0.0)
        case .white: return Color.white
        }
    }
    var dimColor: Color {
        switch self {
        case .green: return Color(red: 0.0, green: 0.6, blue: 0.12)
        case .amber: return Color(red: 0.75, green: 0.5, blue: 0.0)
        case .white: return Color.gray
        }
    }
}

// MARK: - AppSettings (Observable, UserDefaults via App Group)

private let suiteName = "group.com.lucarocchi.BTCBriefing"
private let sharedDefaults = UserDefaults(suiteName: suiteName) ?? .standard

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var provider: DataProvider {
        didSet { sharedDefaults.set(provider.rawValue, forKey: "provider") }
    }
    @Published var pair: TradingPair {
        didSet { sharedDefaults.set(pair.rawValue, forKey: "pair") }
    }
    @Published var refreshInterval: RefreshInterval {
        didSet { sharedDefaults.set(refreshInterval.rawValue, forKey: "refreshInterval") }
    }
    @Published var theme: TerminalTheme {
        didSet { sharedDefaults.set(theme.rawValue, forKey: "theme") }
    }
    @Published var notificationsEnabled: Bool {
        didSet { sharedDefaults.set(notificationsEnabled, forKey: "notificationsEnabled") }
    }
    @Published var showFibonacci: Bool {
        didSet { sharedDefaults.set(showFibonacci, forKey: "showFibonacci") }
    }
    @Published var showCandles: Bool {
        didSet { sharedDefaults.set(showCandles, forKey: "showCandles") }
    }
    @Published var showIndicators: Bool {
        didSet { sharedDefaults.set(showIndicators, forKey: "showIndicators") }
    }
    @Published var hasCompletedOnboarding: Bool {
        didSet { sharedDefaults.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }

    private init() {
        let p = sharedDefaults.string(forKey: "provider") ?? ""
        provider = DataProvider(rawValue: p) ?? .kraken

        let pa = sharedDefaults.string(forKey: "pair") ?? ""
        pair = TradingPair(rawValue: pa) ?? .btcUSD

        let ri = sharedDefaults.integer(forKey: "refreshInterval")
        refreshInterval = RefreshInterval(rawValue: ri == 0 ? 30 : ri) ?? .thirtyMin

        let th = sharedDefaults.string(forKey: "theme") ?? ""
        theme = TerminalTheme(rawValue: th) ?? .green

        notificationsEnabled = sharedDefaults.bool(forKey: "notificationsEnabled")
        showFibonacci = sharedDefaults.object(forKey: "showFibonacci") as? Bool ?? true
        showCandles = sharedDefaults.object(forKey: "showCandles") as? Bool ?? true
        showIndicators = sharedDefaults.object(forKey: "showIndicators") as? Bool ?? true
        hasCompletedOnboarding = sharedDefaults.bool(forKey: "hasCompletedOnboarding")
    }
}
