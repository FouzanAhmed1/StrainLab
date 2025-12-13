import Foundation
import StrainLabKit

public struct RecoveryScoreCalculator: RecoveryScoreCalculating, Sendable {

    private let hrvWeight: Double = 0.50
    private let rhrWeight: Double = 0.30
    private let sleepWeight: Double = 0.20

    public init() {}

    public func calculate(
        currentHRV: Double,
        currentRHR: Double,
        hrvBaseline: Double,
        rhrBaseline: Double,
        sleepQuality: Double
    ) -> RecoveryScore {
        let hrvDeviation = calculateDeviation(current: currentHRV, baseline: hrvBaseline)
        let rhrDeviation = calculateDeviation(current: currentRHR, baseline: rhrBaseline)

        let hrvScore = normalizeHRVDeviation(hrvDeviation)
        let rhrScore = normalizeRHRDeviation(rhrDeviation)

        let weightedScore = (hrvScore * hrvWeight) +
                           (rhrScore * rhrWeight) +
                           (sleepQuality * sleepWeight)

        let finalScore = max(0, min(100, weightedScore))
        let category = RecoveryScore.Category.from(score: finalScore)

        return RecoveryScore(
            date: Date(),
            score: finalScore,
            category: category,
            components: RecoveryScore.Components(
                hrvDeviation: hrvDeviation,
                rhrDeviation: rhrDeviation,
                sleepQuality: sleepQuality,
                hrvBaseline: hrvBaseline,
                rhrBaseline: rhrBaseline,
                currentHRV: currentHRV,
                currentRHR: currentRHR
            )
        )
    }

    /// Calculate percent deviation from baseline
    private func calculateDeviation(current: Double, baseline: Double) -> Double {
        guard baseline > 0 else { return 0 }
        return ((current - baseline) / baseline) * 100
    }

    /// Normalize HRV deviation to 0-100 score
    /// Higher HRV is better, so positive deviation = higher score
    /// Range: -25% to +25% maps to 0-100
    private func normalizeHRVDeviation(_ deviation: Double) -> Double {
        let maxDeviation: Double = 25.0
        let normalized = 50 + (deviation / maxDeviation * 50)
        return max(0, min(100, normalized))
    }

    /// Normalize RHR deviation to 0-100 score
    /// Lower RHR is better, so negative deviation = higher score (inverted)
    /// Range: -15% to +15% maps to 100-0
    private func normalizeRHRDeviation(_ deviation: Double) -> Double {
        let maxDeviation: Double = 15.0
        let normalized = 50 - (deviation / maxDeviation * 50)
        return max(0, min(100, normalized))
    }

    /// Calculate recovery with additional context for explanation
    public func calculateWithContext(
        currentHRV: Double,
        currentRHR: Double,
        hrvBaseline: Double,
        rhrBaseline: Double,
        sleepQuality: Double,
        previousDayStrain: Double?
    ) -> (score: RecoveryScore, insights: [String]) {
        let score = calculate(
            currentHRV: currentHRV,
            currentRHR: currentRHR,
            hrvBaseline: hrvBaseline,
            rhrBaseline: rhrBaseline,
            sleepQuality: sleepQuality
        )

        var insights: [String] = []

        if score.components.hrvDeviation > 10 {
            insights.append("Your HRV is significantly above baseline, indicating excellent recovery.")
        } else if score.components.hrvDeviation < -10 {
            insights.append("Your HRV is below baseline. Consider lighter activity today.")
        }

        if score.components.rhrDeviation > 8 {
            insights.append("Your resting heart rate is elevated, which may indicate stress or incomplete recovery.")
        } else if score.components.rhrDeviation < -5 {
            insights.append("Your resting heart rate is lower than usual, a positive recovery sign.")
        }

        if sleepQuality < 60 {
            insights.append("Sleep quality was suboptimal. Prioritizing rest could improve tomorrow's recovery.")
        }

        if let strain = previousDayStrain, strain > 15 {
            insights.append("Yesterday was a high strain day. Give your body time to adapt.")
        }

        return (score, insights)
    }
}
