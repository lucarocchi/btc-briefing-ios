import UserNotifications
import Foundation

class NotificationManager {
    static let shared = NotificationManager()
    private var lastBias: String?

    private init() {}

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // Notifica schedulata: bias + prezzo corrente
    func schedulePeriodicNotification(data: BriefingData, intervalMinutes: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["periodic"])

        let content = UNMutableNotificationContent()
        content.title = "BTC Briefing"
        content.body  = "\(data.bias) — \(formatPrice(data.price))"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(intervalMinutes * 60),
            repeats: false
        )
        let request = UNNotificationRequest(identifier: "periodic", content: content, trigger: trigger)
        center.add(request)
    }

    // Notifica cambio bias
    func checkBiasChange(data: BriefingData) {
        guard let prev = lastBias, prev != data.bias else {
            lastBias = data.bias
            return
        }
        lastBias = data.bias

        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notif.bias.title", comment: "")
        content.body  = "\(prev) → \(data.bias) @ \(formatPrice(data.price))"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request  = UNNotificationRequest(identifier: "biasChange-\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // Notifica livello Fibonacci vicino (±1.5%)
    func checkFibProximity(data: BriefingData) {
        guard let near = data.nearestFib else { return }

        let content = UNMutableNotificationContent()
        content.title = "BTC vicino a Fib \(near.label)"
        content.body  = "@ \(formatPrice(near.price)) (dist \(String(format: "%+.1f", near.distancePct))%)"
        content.sound = .default

        let id = "fib-\(near.label)"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request  = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func handleNewBriefing(_ data: BriefingData, settings: AppSettings) {
        guard settings.notificationsEnabled else { return }
        schedulePeriodicNotification(data: data, intervalMinutes: settings.refreshInterval.rawValue)
        checkBiasChange(data: data)
        checkFibProximity(data: data)
    }

    private func formatPrice(_ p: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        f.locale = Locale(identifier: "en_US")
        return "$\(f.string(from: NSNumber(value: p)) ?? "\(Int(p))")"
    }
}
