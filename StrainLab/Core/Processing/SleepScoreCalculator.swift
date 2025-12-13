import Foundation
import StrainLabKit

public struct SleepScoreCalculator: SleepScoreCalculating, Sendable {

    private let durationWeight: Double = 0.40
    private let efficiencyWeight: Double = 0.35
    private let stageWeight: Double = 0.25

    public init() {}

    public func calculate(session: SleepSession, sleepNeedMinutes: Double) -> SleepScore {
        let totalMinutes = session.totalDurationMinutes
        let efficiency = session.sleepEfficiency

        let durationScore = calculateDurationScore(actual: totalMinutes, need: sleepNeedMinutes)
        let efficiencyScore = calculateEfficiencyScore(efficiency: efficiency)
        let (deepMinutes, remMinutes, stageScore) = calculateStageScore(session: session)

        let finalScore = (durationScore * durationWeight) +
                        (efficiencyScore * efficiencyWeight) +
                        (stageScore * stageWeight)

        return SleepScore(
            date: Date(),
            score: max(0, min(100, finalScore)),
            components: SleepScore.Components(
                durationScore: durationScore,
                efficiencyScore: efficiencyScore,
                stageScore: stageScore,
                totalDurationMinutes: totalMinutes,
                sleepNeedMinutes: sleepNeedMinutes,
                efficiency: efficiency,
                deepSleepMinutes: deepMinutes,
                remSleepMinutes: remMinutes
            )
        )
    }

    /// Calculate duration score based on meeting sleep need
    /// Optimal: 95-110% of need = 100
    /// Under: linear decrease
    /// Over: slight penalty for significant oversleeping
    private func calculateDurationScore(actual: Double, need: Double) -> Double {
        guard need > 0 else { return 50 }

        let ratio = actual / need

        if ratio >= 0.95 && ratio <= 1.1 {
            return 100.0
        } else if ratio < 0.95 {
            return max(0, (ratio / 0.95) * 100)
        } else {
            return max(70, 100 - ((ratio - 1.1) * 50))
        }
    }

    /// Calculate efficiency score
    /// 90%+ efficiency = 100
    /// Linear scaling below 90%
    private func calculateEfficiencyScore(efficiency: Double) -> Double {
        if efficiency >= 0.9 {
            return 100.0
        }
        return (efficiency / 0.9) * 100
    }

    /// Calculate sleep stage quality score
    /// Based on ideal proportions: ~20% deep, ~25% REM
    private func calculateStageScore(session: SleepSession) -> (deep: Double, rem: Double, score: Double) {
        let deepMinutes = session.deepSleepMinutes
        let remMinutes = session.remSleepMinutes
        let totalSleepMinutes = session.totalDurationMinutes - session.stages
            .filter { $0.type == .awake || $0.type == .inBed }
            .reduce(0.0) { $0 + $1.durationMinutes }

        guard totalSleepMinutes > 0 else {
            return (0, 0, 50.0)
        }

        let deepPercent = deepMinutes / totalSleepMinutes
        let remPercent = remMinutes / totalSleepMinutes

        let idealDeep = 0.20
        let idealREM = 0.25

        let deepScore = 100 - (abs(deepPercent - idealDeep) * 200)
        let remScore = 100 - (abs(remPercent - idealREM) * 200)

        let stageScore = (max(0, deepScore) + max(0, remScore)) / 2

        return (deepMinutes, remMinutes, stageScore)
    }

    /// Calculate sleep quality score (simplified, for recovery calculation)
    public func calculateSleepQuality(session: SleepSession, sleepNeedMinutes: Double) -> Double {
        let score = calculate(session: session, sleepNeedMinutes: sleepNeedMinutes)
        return score.score
    }

    /// Generate sleep insights for transparency layer
    public func generateInsights(session: SleepSession, sleepNeedMinutes: Double) -> [String] {
        var insights: [String] = []

        let durationPercent = (session.totalDurationMinutes / sleepNeedMinutes) * 100

        if durationPercent >= 100 {
            insights.append("You met your sleep goal of \(formatMinutes(sleepNeedMinutes)).")
        } else {
            let deficit = sleepNeedMinutes - session.totalDurationMinutes
            insights.append("You were \(Int(deficit)) minutes short of your sleep goal.")
        }

        let efficiency = session.sleepEfficiency * 100
        if efficiency >= 90 {
            insights.append("Excellent sleep efficiency at \(Int(efficiency))%.")
        } else if efficiency >= 80 {
            insights.append("Good sleep efficiency at \(Int(efficiency))%.")
        } else {
            insights.append("Sleep efficiency was \(Int(efficiency))%. Try to maintain a consistent sleep schedule.")
        }

        let deepMinutes = session.deepSleepMinutes
        let remMinutes = session.remSleepMinutes

        if deepMinutes >= 60 {
            insights.append("Good deep sleep of \(formatMinutes(deepMinutes)) for physical recovery.")
        } else if deepMinutes >= 30 {
            insights.append("Moderate deep sleep. Physical recovery may be incomplete.")
        }

        if remMinutes >= 90 {
            insights.append("Strong REM sleep of \(formatMinutes(remMinutes)) for cognitive recovery.")
        } else if remMinutes >= 60 {
            insights.append("Adequate REM sleep for mental restoration.")
        }

        return insights
    }

    private func formatMinutes(_ minutes: Double) -> String {
        let hours = Int(minutes / 60)
        let mins = Int(minutes.truncatingRemainder(dividingBy: 60))
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins) minutes"
    }
}
