import Foundation
import UserNotifications
import StrainLabKit

/// Manages local notifications for morning recovery alerts and weekly summaries
@MainActor
public final class NotificationManager: ObservableObject {

    public static let shared = NotificationManager()

    @Published public private(set) var isAuthorized = false
    @Published public private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let notificationCenter = UNUserNotificationCenter.current()
    private let contentBuilder = NotificationContentBuilder()

    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    public func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            await checkAuthorizationStatus()
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    public func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Morning Recovery Notification

    public func scheduleMorningRecoveryNotification(
        hour: Int,
        minute: Int
    ) async {
        guard isAuthorized else { return }

        // Remove existing morning notifications
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [NotificationIdentifier.morningRecovery]
        )

        // Create trigger for daily notification
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        // Create placeholder content (will be updated when notification fires)
        let content = contentBuilder.buildMorningRecoveryContent(
            recoveryScore: nil,
            recommendation: nil
        )

        let request = UNNotificationRequest(
            identifier: NotificationIdentifier.morningRecovery,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            print("Scheduled morning recovery notification for \(hour):\(String(format: "%02d", minute))")
        } catch {
            print("Failed to schedule morning notification: \(error)")
        }
    }

    /// Update morning notification with actual recovery data
    public func updateMorningNotification(
        recovery: RecoveryScore?,
        recommendation: String?
    ) async {
        guard isAuthorized else { return }

        let content = contentBuilder.buildMorningRecoveryContent(
            recoveryScore: recovery,
            recommendation: recommendation
        )

        // Send immediate notification
        let request = UNNotificationRequest(
            identifier: NotificationIdentifier.morningRecoveryUpdate,
            content: content,
            trigger: nil
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to send morning update: \(error)")
        }
    }

    // MARK: - Weekly Summary Notification (Premium)

    public func scheduleWeeklySummaryNotification(
        dayOfWeek: Int, // 1 = Sunday, 7 = Saturday
        hour: Int,
        minute: Int
    ) async {
        guard isAuthorized else { return }

        // Remove existing weekly notifications
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [NotificationIdentifier.weeklySummary]
        )

        var dateComponents = DateComponents()
        dateComponents.weekday = dayOfWeek
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let content = contentBuilder.buildWeeklySummaryContent(
            avgRecovery: nil,
            totalStrain: nil,
            avgSleepHours: nil
        )

        let request = UNNotificationRequest(
            identifier: NotificationIdentifier.weeklySummary,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            print("Scheduled weekly summary for weekday \(dayOfWeek) at \(hour):\(String(format: "%02d", minute))")
        } catch {
            print("Failed to schedule weekly summary: \(error)")
        }
    }

    /// Send weekly summary with actual data
    public func sendWeeklySummary(
        avgRecovery: Double,
        totalStrain: Double,
        avgSleepHours: Double
    ) async {
        guard isAuthorized else { return }

        let content = contentBuilder.buildWeeklySummaryContent(
            avgRecovery: avgRecovery,
            totalStrain: totalStrain,
            avgSleepHours: avgSleepHours
        )

        let request = UNNotificationRequest(
            identifier: NotificationIdentifier.weeklySummaryUpdate,
            content: content,
            trigger: nil
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to send weekly summary: \(error)")
        }
    }

    // MARK: - Cancel Notifications

    public func cancelMorningNotifications() {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [
                NotificationIdentifier.morningRecovery,
                NotificationIdentifier.morningRecoveryUpdate
            ]
        )
    }

    public func cancelWeeklyNotifications() {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [
                NotificationIdentifier.weeklySummary,
                NotificationIdentifier.weeklySummaryUpdate
            ]
        )
    }

    public func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    // MARK: - Debug

    public func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }
}

// MARK: - Notification Identifiers

private enum NotificationIdentifier {
    static let morningRecovery = "com.strainlab.morning.recovery"
    static let morningRecoveryUpdate = "com.strainlab.morning.recovery.update"
    static let weeklySummary = "com.strainlab.weekly.summary"
    static let weeklySummaryUpdate = "com.strainlab.weekly.summary.update"
}
