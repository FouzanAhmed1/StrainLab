import Foundation
import StrainLabKit

/// Calculates sleep consistency metrics from sleep data
public struct SleepConsistencyCalculator: Sendable {

    public init() {}

    // MARK: - Consistency Score

    /// Calculate overall sleep consistency score (0-100)
    public func calculateConsistencyScore(sleepScores: [SleepScore]) -> SleepConsistency {
        guard sleepScores.count >= 3 else {
            return SleepConsistency(
                score: 0,
                timingVariability: 0,
                durationVariability: 0,
                rating: .insufficient,
                insight: "Need at least 3 nights of data"
            )
        }

        // Calculate timing consistency (bedtime/wake time variance)
        let timingScore = calculateTimingConsistency(sleepScores: sleepScores)

        // Calculate duration consistency
        let durationScore = calculateDurationConsistency(sleepScores: sleepScores)

        // Weighted combination (timing slightly more important)
        let overallScore = timingScore * 0.55 + durationScore * 0.45

        let rating = determineRating(score: overallScore)
        let insight = generateInsight(
            timingScore: timingScore,
            durationScore: durationScore,
            rating: rating
        )

        return SleepConsistency(
            score: overallScore,
            timingVariability: 100 - timingScore,
            durationVariability: 100 - durationScore,
            rating: rating,
            insight: insight
        )
    }

    // MARK: - Timing Analysis

    private func calculateTimingConsistency(sleepScores: [SleepScore]) -> Double {
        let bedtimes = sleepScores.compactMap { extractMinutesFromMidnight(date: $0.sleepStart) }
        let waketimes = sleepScores.compactMap { extractMinutesFromMidnight(date: $0.sleepEnd) }

        guard !bedtimes.isEmpty && !waketimes.isEmpty else { return 0 }

        let bedtimeCV = calculateCircularCV(minutes: bedtimes)
        let waketimeCV = calculateCircularCV(minutes: waketimes)

        // Convert CV to score (lower variance = higher score)
        // CV of 30 min = 100, CV of 120 min = 0
        let bedtimeScore = max(0, min(100, 100 - (bedtimeCV - 30) * (100.0 / 90.0)))
        let waketimeScore = max(0, min(100, 100 - (waketimeCV - 30) * (100.0 / 90.0)))

        return (bedtimeScore + waketimeScore) / 2
    }

    private func extractMinutesFromMidnight(date: Date?) -> Double? {
        guard let date = date else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        guard let hour = components.hour, let minute = components.minute else { return nil }

        var minutes = Double(hour * 60 + minute)
        // Normalize for bedtimes after midnight (0-5am becomes 24:00-29:00)
        if hour < 6 {
            minutes += 24 * 60
        }
        return minutes
    }

    private func calculateCircularCV(minutes: [Double]) -> Double {
        guard !minutes.isEmpty else { return 0 }

        let mean = minutes.reduce(0, +) / Double(minutes.count)
        let squaredDiffs = minutes.map { pow($0 - mean, 2) }
        let variance = squaredDiffs.reduce(0, +) / Double(minutes.count)

        return sqrt(variance) // Return standard deviation in minutes
    }

    // MARK: - Duration Analysis

    private func calculateDurationConsistency(sleepScores: [SleepScore]) -> Double {
        let durations = sleepScores.map { $0.components.totalSleepMinutes }

        guard !durations.isEmpty else { return 0 }

        let mean = durations.reduce(0, +) / Double(durations.count)
        guard mean > 0 else { return 0 }

        let squaredDiffs = durations.map { pow($0 - mean, 2) }
        let variance = squaredDiffs.reduce(0, +) / Double(durations.count)
        let stdDev = sqrt(variance)

        // CV as percentage
        let cv = (stdDev / mean) * 100

        // Convert to score (CV of 5% = 100, CV of 30% = 0)
        return max(0, min(100, 100 - (cv - 5) * (100.0 / 25.0)))
    }

    // MARK: - Rating & Insights

    private func determineRating(score: Double) -> SleepConsistency.Rating {
        switch score {
        case 80...100: return .excellent
        case 60..<80: return .good
        case 40..<60: return .fair
        case 20..<40: return .poor
        default: return .insufficient
        }
    }

    private func generateInsight(
        timingScore: Double,
        durationScore: Double,
        rating: SleepConsistency.Rating
    ) -> String {
        switch rating {
        case .excellent:
            return "Your sleep schedule is very consistent"
        case .good:
            if timingScore < durationScore {
                return "Try to keep more regular bed and wake times"
            } else {
                return "Your timing is good — work on consistent duration"
            }
        case .fair:
            return "More consistent sleep would improve recovery"
        case .poor:
            return "Irregular sleep is affecting your recovery"
        case .insufficient:
            return "Keep tracking to build your sleep profile"
        }
    }
}

// MARK: - Supporting Types

public struct SleepConsistency: Sendable, Equatable {
    public let score: Double // 0-100
    public let timingVariability: Double // lower is better
    public let durationVariability: Double // lower is better
    public let rating: Rating
    public let insight: String

    public enum Rating: String, Sendable {
        case excellent = "Excellent"
        case good = "Good"
        case fair = "Fair"
        case poor = "Poor"
        case insufficient = "Insufficient Data"

        public var displayName: String { rawValue }
    }
}
