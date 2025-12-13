import Foundation
import StrainLabKit

/// Lightweight recovery calculator for Apple Watch
/// Simplified version of iOS RecoveryScoreCalculator for offline use
public struct WatchRecoveryCalculator: Sendable {

    // Weights match iOS implementation
    private let hrvWeight: Double = 0.50
    private let rhrWeight: Double = 0.30
    private let sleepWeight: Double = 0.20

    public init() {}

    /// Calculate recovery score from Watch-collected data
    /// Returns nil if insufficient data
    public func calculate(
        overnightHRV: [HRVSample],
        restingHeartRate: Double?,
        sleepDurationMinutes: Double?,
        baseline: UserBaseline
    ) -> RecoveryScore? {
        // Need at least HRV data to calculate
        guard !overnightHRV.isEmpty else { return nil }

        // Get average overnight HRV (SDNN)
        let avgHRV = overnightHRV.map { $0.sdnnMilliseconds }.average()

        // Calculate HRV deviation from baseline
        let hrvDeviation = ((avgHRV - baseline.hrvBaseline7Day) / baseline.hrvBaseline7Day) * 100

        // Calculate HRV component (normalized to 0-100)
        // -25% deviation = 0, +25% deviation = 100
        let hrvScore = normalizeDeviation(hrvDeviation, range: 25)

        // Calculate RHR component (inverted: lower is better)
        let rhrScore: Double
        let rhrDeviation: Double
        if let rhr = restingHeartRate {
            rhrDeviation = ((rhr - baseline.rhrBaseline7Day) / baseline.rhrBaseline7Day) * 100
            // +15% deviation = 0, -15% deviation = 100
            rhrScore = 100 - normalizeDeviation(rhrDeviation, range: 15)
        } else {
            rhrDeviation = 0
            rhrScore = 50 // Neutral if no RHR data
        }

        // Calculate sleep component
        let sleepScore: Double
        if let sleepMinutes = sleepDurationMinutes {
            let sleepNeed = baseline.sleepNeedMinutes
            let sleepRatio = sleepMinutes / sleepNeed
            // 95-110% of sleep need = 100, falls off linearly
            if sleepRatio >= 0.95 && sleepRatio <= 1.1 {
                sleepScore = 100
            } else if sleepRatio < 0.95 {
                sleepScore = max(0, sleepRatio / 0.95 * 100)
            } else {
                sleepScore = max(70, 100 - (sleepRatio - 1.1) * 100)
            }
        } else {
            sleepScore = 50 // Neutral if no sleep data
        }

        // Calculate weighted total
        let totalScore = (hrvScore * hrvWeight) + (rhrScore * rhrWeight) + (sleepScore * sleepWeight)
        let clampedScore = min(100, max(0, totalScore))

        // Determine category
        let category: RecoveryScore.Category
        if clampedScore >= 67 {
            category = .optimal
        } else if clampedScore >= 34 {
            category = .moderate
        } else {
            category = .poor
        }

        return RecoveryScore(
            score: clampedScore,
            category: category,
            date: Date(),
            components: RecoveryScore.Components(
                hrvDeviation: hrvDeviation,
                rhrDeviation: rhrDeviation,
                sleepQuality: sleepScore,
                currentHRV: avgHRV,
                currentRHR: restingHeartRate ?? baseline.rhrBaseline7Day,
                baselineHRV: baseline.hrvBaseline7Day,
                baselineRHR: baseline.rhrBaseline7Day
            )
        )
    }

    /// Normalizes a deviation percentage to 0-100 scale
    /// deviation: actual deviation percentage (can be negative or positive)
    /// range: the deviation range that maps to 0-100 (e.g., 25 means -25% to +25%)
    private func normalizeDeviation(_ deviation: Double, range: Double) -> Double {
        // Map deviation from [-range, +range] to [0, 100]
        let normalized = ((deviation + range) / (range * 2)) * 100
        return min(100, max(0, normalized))
    }
}

// MARK: - Array Extension

private extension Array where Element == Double {
    func average() -> Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}
