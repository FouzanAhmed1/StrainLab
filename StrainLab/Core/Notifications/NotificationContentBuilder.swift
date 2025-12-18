import Foundation
import UserNotifications
import StrainLabKit

/// Builds notification content for StrainLab notifications
public struct NotificationContentBuilder: Sendable {

    public init() {}

    // MARK: - Morning Recovery

    public func buildMorningRecoveryContent(
        recoveryScore: RecoveryScore?,
        recommendation: String?
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.sound = .default

        if let score = recoveryScore {
            content.title = "Recovery: \(Int(score.score))%"
            content.subtitle = score.category.displayName

            if let rec = recommendation {
                content.body = rec
            } else {
                content.body = generateDefaultRecommendation(for: score.category)
            }
        } else {
            content.title = "Good morning!"
            content.body = "Open StrainLab to see your recovery"
        }

        content.categoryIdentifier = "MORNING_RECOVERY"
        content.threadIdentifier = "recovery"

        return content
    }

    private func generateDefaultRecommendation(for category: RecoveryScore.Category) -> String {
        switch category {
        case .optimal:
            return "Great recovery — today is a good day to push"
        case .moderate:
            return "Moderate recovery — listen to your body"
        case .poor:
            return "Low recovery — prioritize rest today"
        }
    }

    // MARK: - Weekly Summary

    public func buildWeeklySummaryContent(
        avgRecovery: Double?,
        totalStrain: Double?,
        avgSleepHours: Double?
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.sound = .default

        if let recovery = avgRecovery,
           let strain = totalStrain,
           let sleep = avgSleepHours {
            content.title = "Your Week in Review"
            content.body = buildWeeklySummaryBody(
                avgRecovery: recovery,
                totalStrain: strain,
                avgSleepHours: sleep
            )
        } else {
            content.title = "Weekly Summary"
            content.body = "Open StrainLab to see your weekly trends"
        }

        content.categoryIdentifier = "WEEKLY_SUMMARY"
        content.threadIdentifier = "weekly"

        return content
    }

    private func buildWeeklySummaryBody(
        avgRecovery: Double,
        totalStrain: Double,
        avgSleepHours: Double
    ) -> String {
        let recoveryEmoji = avgRecovery >= 67 ? "💚" : (avgRecovery >= 34 ? "💛" : "❤️")
        let sleepFormatted = String(format: "%.1f", avgSleepHours)

        return "\(recoveryEmoji) Avg Recovery: \(Int(avgRecovery))% • Total Strain: \(String(format: "%.1f", totalStrain)) • Avg Sleep: \(sleepFormatted)h"
    }

    // MARK: - Achievement Notifications (future)

    public func buildAchievementContent(
        title: String,
        message: String
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        content.categoryIdentifier = "ACHIEVEMENT"
        return content
    }

    // MARK: - Reminder Notifications (future)

    public func buildReminderContent(
        type: ReminderType
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()

        switch type {
        case .wearWatch:
            content.title = "Track Your Recovery"
            content.body = "Wear your Apple Watch to bed for accurate recovery tracking"

        case .syncData:
            content.title = "Sync Your Data"
            content.body = "Open StrainLab to sync your latest health data"

        case .checkRecovery:
            content.title = "Recovery Ready"
            content.body = "Your morning recovery score is available"
        }

        content.sound = .default
        content.categoryIdentifier = "REMINDER"
        return content
    }
}

// MARK: - Supporting Types

public enum ReminderType: String, Sendable {
    case wearWatch
    case syncData
    case checkRecovery
}
