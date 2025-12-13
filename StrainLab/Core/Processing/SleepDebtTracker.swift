import Foundation
import StrainLabKit

/// Tracks accumulated sleep debt over time
public struct SleepDebtTracker: Sendable {

    public init() {}

    // MARK: - Sleep Debt Calculation

    /// Calculate current sleep debt based on recent sleep history
    public func calculateSleepDebt(
        sleepScores: [SleepScore],
        targetSleepMinutes: Double
    ) -> SleepDebt {
        guard !sleepScores.isEmpty else {
            return SleepDebt(
                totalDebtMinutes: 0,
                weeklyDebtMinutes: 0,
                trend: .stable,
                severity: .none,
                recommendation: "Start tracking to monitor sleep debt"
            )
        }

        // Calculate debt from last 7 days
        let last7Days = Array(sleepScores.suffix(7))
        let weeklyDebt = calculateWeeklyDebt(
            sleepScores: last7Days,
            targetMinutes: targetSleepMinutes
        )

        // Calculate rolling debt (decays over time)
        let rollingDebt = calculateRollingDebt(
            sleepScores: sleepScores,
            targetMinutes: targetSleepMinutes
        )

        // Determine trend
        let trend = calculateDebtTrend(sleepScores: last7Days, targetMinutes: targetSleepMinutes)

        // Determine severity
        let severity = determineSeverity(debtMinutes: rollingDebt)

        // Generate recommendation
        let recommendation = generateRecommendation(
            severity: severity,
            trend: trend,
            debtMinutes: rollingDebt
        )

        return SleepDebt(
            totalDebtMinutes: rollingDebt,
            weeklyDebtMinutes: weeklyDebt,
            trend: trend,
            severity: severity,
            recommendation: recommendation
        )
    }

    // MARK: - Debt Calculations

    private func calculateWeeklyDebt(
        sleepScores: [SleepScore],
        targetMinutes: Double
    ) -> Double {
        var debt = 0.0
        for score in sleepScores {
            let actualSleep = score.components.totalSleepMinutes
            let deficit = targetMinutes - actualSleep
            if deficit > 0 {
                debt += deficit
            }
        }
        return debt
    }

    private func calculateRollingDebt(
        sleepScores: [SleepScore],
        targetMinutes: Double
    ) -> Double {
        // Use exponential decay — older debt matters less
        // Debt decays by ~50% per week
        let decayFactor = 0.9 // Daily decay
        var rollingDebt = 0.0

        // Process most recent first (reversed)
        let reversed = sleepScores.reversed()
        var dayIndex = 0

        for score in reversed {
            let actualSleep = score.components.totalSleepMinutes
            let deficit = targetMinutes - actualSleep

            // Apply decay based on age
            let weight = pow(decayFactor, Double(dayIndex))

            if deficit > 0 {
                rollingDebt += deficit * weight
            } else {
                // Surplus sleep can reduce debt (but not below zero)
                rollingDebt = max(0, rollingDebt + deficit * weight * 0.5)
            }

            dayIndex += 1
            if dayIndex >= 14 { break } // Only look back 2 weeks
        }

        return rollingDebt
    }

    private func calculateDebtTrend(
        sleepScores: [SleepScore],
        targetMinutes: Double
    ) -> SleepDebt.Trend {
        guard sleepScores.count >= 3 else { return .stable }

        let deficits = sleepScores.map { targetMinutes - $0.components.totalSleepMinutes }

        // Simple linear regression
        let n = Double(deficits.count)
        let indices = Array(0..<deficits.count).map { Double($0) }

        let sumX = indices.reduce(0, +)
        let sumY = deficits.reduce(0, +)
        let sumXY = zip(indices, deficits).map { $0 * $1 }.reduce(0, +)
        let sumXX = indices.map { $0 * $0 }.reduce(0, +)

        let denominator = n * sumXX - sumX * sumX
        guard denominator != 0 else { return .stable }

        let slope = (n * sumXY - sumX * sumY) / denominator

        // Slope interpretation (minutes per day)
        if slope > 10 {
            return .increasing
        } else if slope < -10 {
            return .decreasing
        } else {
            return .stable
        }
    }

    // MARK: - Severity & Recommendations

    private func determineSeverity(debtMinutes: Double) -> SleepDebt.Severity {
        let debtHours = debtMinutes / 60

        switch debtHours {
        case ..<1: return .none
        case 1..<3: return .mild
        case 3..<6: return .moderate
        case 6..<10: return .significant
        default: return .severe
        }
    }

    private func generateRecommendation(
        severity: SleepDebt.Severity,
        trend: SleepDebt.Trend,
        debtMinutes: Double
    ) -> String {
        let debtHours = debtMinutes / 60

        switch (severity, trend) {
        case (.none, _):
            return "Your sleep is on track"

        case (.mild, .decreasing):
            return "You're catching up — keep it going"

        case (.mild, _):
            return "Try adding 15-30 min to tonight's sleep"

        case (.moderate, .decreasing):
            return "Good progress on reducing sleep debt"

        case (.moderate, .increasing):
            return "Sleep debt is building — prioritize rest"

        case (.moderate, .stable):
            return "Consider an earlier bedtime this week"

        case (.significant, _), (.severe, _):
            let extraHoursNeeded = min(2, debtHours / 3)
            return String(format: "Add %.0fh of sleep over the next few nights", extraHoursNeeded)
        }
    }
}

// MARK: - Supporting Types

public struct SleepDebt: Sendable, Equatable {
    public let totalDebtMinutes: Double
    public let weeklyDebtMinutes: Double
    public let trend: Trend
    public let severity: Severity
    public let recommendation: String

    public var formattedDebt: String {
        let hours = Int(totalDebtMinutes / 60)
        let minutes = Int(totalDebtMinutes.truncatingRemainder(dividingBy: 60))

        if hours == 0 {
            return "\(minutes)m"
        } else if minutes == 0 {
            return "\(hours)h"
        } else {
            return "\(hours)h \(minutes)m"
        }
    }

    public enum Trend: String, Sendable {
        case increasing = "Increasing"
        case stable = "Stable"
        case decreasing = "Decreasing"

        public var displayName: String { rawValue }

        public var icon: String {
            switch self {
            case .increasing: return "arrow.up"
            case .stable: return "arrow.right"
            case .decreasing: return "arrow.down"
            }
        }
    }

    public enum Severity: String, Sendable {
        case none = "None"
        case mild = "Mild"
        case moderate = "Moderate"
        case significant = "Significant"
        case severe = "Severe"

        public var displayName: String { rawValue }
    }
}
