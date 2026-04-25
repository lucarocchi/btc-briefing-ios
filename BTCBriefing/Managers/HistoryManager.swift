import Foundation

private let sharedDefaults = UserDefaults(suiteName: "group.com.lucarocchi.BTCBriefing") ?? .standard
private let historyKey = "briefingHistory"
private let maxHistory = 50

class HistoryManager: ObservableObject {
    static let shared = HistoryManager()

    @Published var entries: [BriefingData] = []

    private init() {
        load()
    }

    func save(_ briefing: BriefingData) {
        var updated = entries
        updated.insert(briefing, at: 0)
        if updated.count > maxHistory { updated = Array(updated.prefix(maxHistory)) }
        entries = updated
        persist()
        // Salva anche l'ultimo briefing per il widget
        if let encoded = try? JSONEncoder().encode(briefing) {
            sharedDefaults.set(encoded, forKey: "lastBriefing")
        }
    }

    func clear() {
        entries = []
        sharedDefaults.removeObject(forKey: historyKey)
    }

    private func load() {
        guard let data = sharedDefaults.data(forKey: historyKey),
              let decoded = try? JSONDecoder().decode([BriefingData].self, from: data)
        else { return }
        entries = decoded
    }

    private func persist() {
        if let encoded = try? JSONEncoder().encode(entries) {
            sharedDefaults.set(encoded, forKey: historyKey)
        }
    }

    // Legge l'ultimo briefing (usato dal widget e per cache offline)
    static func loadLast() -> BriefingData? {
        guard let data = sharedDefaults.data(forKey: "lastBriefing"),
              var decoded = try? JSONDecoder().decode(BriefingData.self, from: data)
        else { return nil }
        decoded.isCached = true
        return decoded
    }
}
