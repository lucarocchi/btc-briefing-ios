import Foundation
import SwiftUI
import WidgetKit

@MainActor
class BriefingEngine: ObservableObject {
    @Published var briefing: BriefingData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var nextRefreshIn: TimeInterval = 0

    private var refreshTask: Task<Void, Never>?
    private var countdownTask: Task<Void, Never>?

    // Avvia il loop di refresh automatico
    func startAutoRefresh(settings: AppSettings) {
        stopAutoRefresh()
        refreshTask = Task {
            while !Task.isCancelled {
                await refresh(settings: settings)
                let interval = settings.refreshInterval.seconds
                nextRefreshIn = interval
                startCountdown(from: interval)
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        countdownTask?.cancel()
        refreshTask = nil
        countdownTask = nil
    }

    func refresh(settings: AppSettings) async {
        isLoading = true
        errorMessage = nil
        do {
            let data = try await fetchAndCompute(settings: settings)
            briefing = data
            HistoryManager.shared.save(data)
            WidgetCenter.shared.reloadAllTimelines()
            NotificationManager.shared.handleNewBriefing(data, settings: settings)
        } catch {
            errorMessage = error.localizedDescription
            // Mostra l'ultimo briefing in cache se disponibile
            if briefing == nil {
                briefing = HistoryManager.loadLast()
            }
        }
        isLoading = false
    }

    private func fetchAndCompute(settings: AppSettings) async throws -> BriefingData {
        let svc = settings.provider.makeService()
        let pair = settings.pair

        // Fetch parallelo di ticker e tutte le barre OHLCV
        async let ticker = svc.fetchTicker(pair: pair)
        async let bars15m = svc.fetchOHLCV(pair: pair, interval: 15,   count: 500)
        async let bars1h  = svc.fetchOHLCV(pair: pair, interval: 60,   count: 250)
        async let bars4h  = svc.fetchOHLCV(pair: pair, interval: 240,  count: 220) // 220 per EMA200 4H
        async let bars1d  = svc.fetchOHLCV(pair: pair, interval: 1440, count: 720) // 720 per aggregazione weekly

        let (tick, b15m, b1h, b4h, b1d) = try await (ticker, bars15m, bars1h, bars4h, bars1d)

        return Indicators.compute(
            price:   tick.price,
            high24h: tick.high24h,
            low24h:  tick.low24h,
            bars15m: b15m,
            bars1h:  b1h,
            bars4h:  b4h,
            bars1d:  b1d
        )
    }

    private func startCountdown(from interval: TimeInterval) {
        countdownTask?.cancel()
        countdownTask = Task {
            var remaining = interval
            while remaining > 0 && !Task.isCancelled {
                nextRefreshIn = remaining
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                remaining -= 1
            }
        }
    }
}
