import Foundation
import UserNotifications
import WatchKit
import StrainLabKit

/// Manages local notifications for Apple Watch
/// Handles morning recovery summaries and weekly digest notifications
public final class WatchNotificationManager: NSObject, @unchecked Sendable {

    public static let shared = WatchNotificationManager()

    private let dataStore = WatchDataStore.shared
    private let center = UNUserNotificationCenter.current()

    // MARK: - Notification Identifiers

    private enum NotificationID {
        static let morningRecovery = "com.strainlab.watch.morning"
        static let weeklySummary = "com.strainlab.watch.weekly"
    }

    // MARK: - User Defaults Keys

    private enum Keys {
        static let lastMorningNotification = "watch.notification.lastMorning"
        static let lastWeeklyNotification = "watch.notification.lastWeekly"
        static let notificationsEnabled = "watch.notification.enabled"
        static let morningNotificationHour = "watch.notification.morningHour"
    }

    // MARK: - Initialization

    private override init() {
        super.init()
    }

    // MARK: - Authorization

    /// Request notification authorization
    public func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            let granted = try await center.requestAuthorization(options: options)

            if granted {
                print("WatchNotificationManager: Notification authorization granted")
            } else {
                print("WatchNotificationManager: Notification authorization denied")
            }

            return granted
        } catch {
            print("WatchNotificationManager: Authorization error: \(error)")
            return false
        }
    }

    /// Check current authorization status
    public func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Notification Settings

    /// Enable or disable notifications
    public func setNotificationsEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Keys.notificationsEnabled)

        if !enabled {
            cancelAllNotifications()
        }
    }

    /// Check if notifications are enabled
    public func areNotificationsEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: Keys.notificationsEnabled)
    }

    /// Set preferred morning notification hour (default: 7 AM)
    public func setMorningNotificationHour(_ hour: Int) {
        UserDefaults.standard.set(hour, forKey: Keys.morningNotificationHour)
    }

    /// Get preferred morning notification hour
    public func getMorningNotificationHour() -> Int {
        let hour = UserDefaults.standard.integer(forKey: Keys.morningNotificationHour)
        return hour > 0 ? hour : 7 // Default to 7 AM
    }

    // MARK: - Scheduled Notification Check

    /// Check and send notifications if appropriate
    /// Called from background refresh
    public func checkAndSendScheduledNotifications() async {
        guard areNotificationsEnabled() else { return }

        await checkMorningNotification()
        await checkWeeklyNotification()
    }

    // MARK: - Morning Recovery Notification

    private func checkMorningNotification() async {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)

        // Only send between 6-9 AM
        guard hour >= 6 && hour <= 9 else { return }

        // Check if we already sent one today
        if let lastSent = UserDefaults.standard.object(forKey: Keys.lastMorningNotification) as? Date {
            if calendar.isDate(lastSent, inSameDayAs: now) {
                return // Already sent today
            }
        }

        // Get current recovery score
        guard let recovery = dataStore.getRecoveryScore() else { return }

        // Send the notification
        await sendMorningNotification(recovery: recovery)

        // Mark as sent
        UserDefaults.standard.set(now, forKey: Keys.lastMorningNotification)
    }

    private func sendMorningNotification(recovery: RecoveryScore) async {
        let content = UNMutableNotificationContent()
        content.title = "Good Morning"
        content.body = buildMorningMessage(recovery: recovery)
        content.sound = .default
        content.categoryIdentifier = "MORNING_RECOVERY"

        let request = UNNotificationRequest(
            identifier: NotificationID.morningRecovery,
            content: content,
            trigger: nil // Deliver immediately
        )

        do {
            try await center.add(request)
            print("WatchNotificationManager: Morning notification sent")
        } catch {
            print("WatchNotificationManager: Failed to send morning notification: \(error)")
        }
    }

    private func buildMorningMessage(recovery: RecoveryScore) -> String {
        let percentage = Int(recovery.score)

        switch recovery.category {
        case .optimal:
            return "\(percentage)% recovered. Ready to push today!"
        case .moderate:
            return "\(percentage)% recovered. Consider a moderate effort today."
        case .poor:
            return "\(percentage)% recovered. Focus on rest and recovery today."
        }
    }

    // MARK: - Weekly Summary Notification

    private func checkWeeklyNotification() async {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let hour = calendar.component(.hour, from: now)

        // Only send on Sunday around 9 AM
        guard weekday == 1 && hour >= 9 && hour <= 11 else { return }

        // Check if we already sent this week
        if let lastSent = UserDefaults.standard.object(forKey: Keys.lastWeeklyNotification) as? Date {
            let daysSinceLast = calendar.dateComponents([.day], from: lastSent, to: now).day ?? 0
            if daysSinceLast < 6 {
                return // Too soon
            }
        }

        // Send the notification
        await sendWeeklyNotification()

        // Mark as sent
        UserDefaults.standard.set(now, forKey: Keys.lastWeeklyNotification)
    }

    private func sendWeeklyNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "Weekly Summary Ready"
        content.body = buildWeeklySummary()
        content.sound = .default
        content.categoryIdentifier = "WEEKLY_SUMMARY"

        let request = UNNotificationRequest(
            identifier: NotificationID.weeklySummary,
            content: content,
            trigger: nil
        )

        do {
            try await center.add(request)
            print("WatchNotificationManager: Weekly notification sent")
        } catch {
            print("WatchNotificationManager: Failed to send weekly notification: \(error)")
        }
    }

    private func buildWeeklySummary() -> String {
        let recoveryHistory = dataStore.getRecoveryHistory()
        let strainHistory = dataStore.getStrainHistory()

        if recoveryHistory.isEmpty && strainHistory.isEmpty {
            return "Check your iPhone app for your weekly training insights."
        }

        let avgRecovery = recoveryHistory.isEmpty ? 0 :
            recoveryHistory.reduce(0) { $0 + $1.score } / Double(recoveryHistory.count)
        let totalStrain = strainHistory.reduce(0) { $0 + $1.score }

        return String(format: "Avg recovery: %.0f%%. Total strain: %.1f. View details on iPhone.", avgRecovery, totalStrain)
    }

    // MARK: - Manual Notifications

    /// Send an immediate notification (for testing or important events)
    public func sendImmediateNotification(
        title: String,
        body: String,
        identifier: String = UUID().uuidString
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )

        do {
            try await center.add(request)
        } catch {
            print("WatchNotificationManager: Failed to send notification: \(error)")
        }
    }

    /// Send a workout completion notification
    public func sendWorkoutCompleteNotification(
        strainAdded: Double,
        totalStrain: Double,
        duration: TimeInterval
    ) async {
        let content = UNMutableNotificationContent()
        content.title = "Workout Complete"
        content.body = String(
            format: "+%.1f strain (%.1f total). Great effort!",
            strainAdded,
            totalStrain
        )
        content.sound = .default
        content.categoryIdentifier = "WORKOUT_COMPLETE"

        let request = UNNotificationRequest(
            identifier: "com.strainlab.watch.workout.\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        do {
            try await center.add(request)
        } catch {
            print("WatchNotificationManager: Failed to send workout notification: \(error)")
        }
    }

    // MARK: - Notification Management

    /// Cancel all pending notifications
    public func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    /// Cancel a specific notification
    public func cancelNotification(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
    }
}

