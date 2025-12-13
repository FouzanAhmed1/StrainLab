import Foundation
import StrainLabKit

/// Calculates recommended strain ranges based on recovery and training history
public struct StrainGuidanceCalculator: Sendable {

    public init() {}

    // MARK: - Strain Guidance

    /// Calculate recommended strain range for today based on recovery and history
    public func calculateGuidance(
        recoveryScore: RecoveryScore?,
        recentStrainScores: [StrainScore],
        trainingIntensity: TrainingIntensity
    ) -> StrainGuidance {
        guard let recovery = recoveryScore else {
            return StrainGuidance(
                recommendedRange: 8...12,
                weeklyLoadStatus: .unknown,
                rationale: "Waiting for recovery data"
            )
        }

        // Calculate base recommended range from recovery
        let baseRange = calculateBaseRange(recovery: recovery)

        // Adjust based on training intensity preference
        let adjustedRange = adjustForIntensity(range: baseRange, intensity: trainingIntensity)

        // Analyze weekly load status
        let loadStatus = analyzeWeeklyLoad(
            recentStrains: recentStrainScores,
            recovery: recovery,
            intensity: trainingIntensity
        )

        // Generate rationale
        let rationale = generateRationale(
            recovery: recovery,
            loadStatus: loadStatus,
            range: adjustedRange
        )

        return StrainGuidance(
            recommendedRange: adjustedRange,
            weeklyLoadStatus: loadStatus,
            rationale: rationale
        )
    }

    // MARK: - Range Calculation

    private func calculateBaseRange(recovery: RecoveryScore) -> ClosedRange<Double> {
        switch recovery.category {
        case .optimal:
            // High recovery: can push hard
            return 14...18
        case .moderate:
            // Moderate recovery: balanced effort
            return 10...14
        case .poor:
            // Low recovery: prioritize rest
            return 4...8
        }
    }

    private func adjustForIntensity(
        range: ClosedRange<Double>,
        intensity: TrainingIntensity
    ) -> ClosedRange<Double> {
        let adjustment: Double
        switch intensity {
        case .light:
            adjustment = -2
        case .moderate:
            adjustment = 0
        case .intense:
            adjustment = 2
        case .veryIntense:
            adjustment = 3
        }

        let newLower = max(0, range.lowerBound + adjustment)
        let newUpper = min(21, range.upperBound + adjustment)
        return newLower...newUpper
    }

    // MARK: - Weekly Load Analysis

    private func analyzeWeeklyLoad(
        recentStrains: [StrainScore],
        recovery: RecoveryScore,
        intensity: TrainingIntensity
    ) -> WeeklyLoadStatus {
        guard recentStrains.count >= 3 else {
            return .unknown
        }

        // Calculate 7-day strain total
        let last7Days = Array(recentStrains.suffix(7))
        let totalStrain = last7Days.reduce(0.0) { $0 + $1.score }
        let avgDailyStrain = totalStrain / Double(last7Days.count)

        // Target daily strain based on intensity
        let targetDailyStrain: Double
        switch intensity {
        case .light: targetDailyStrain = 8
        case .moderate: targetDailyStrain = 11
        case .intense: targetDailyStrain = 14
        case .veryIntense: targetDailyStrain = 16
        }

        // Calculate trend
        let trend = calculateStrainTrend(strains: last7Days)

        // Determine status
        let ratio = avgDailyStrain / targetDailyStrain

        if ratio < 0.7 {
            return .underLoaded
        } else if ratio > 1.3 && recovery.score < 50 {
            return .overReaching
        } else if ratio > 1.2 {
            return .peaking
        } else if trend > 0.5 && ratio > 0.9 {
            return .building
        } else if trend < -0.5 && ratio < 1.0 {
            return .deloading
        } else {
            return .optimal
        }
    }

    private func calculateStrainTrend(strains: [StrainScore]) -> Double {
        guard strains.count >= 2 else { return 0 }

        let values = strains.map { $0.score }
        let n = Double(values.count)
        let indices = Array(0..<values.count).map { Double($0) }

        let sumX = indices.reduce(0, +)
        let sumY = values.reduce(0, +)
        let sumXY = zip(indices, values).map { $0 * $1 }.reduce(0, +)
        let sumXX = indices.map { $0 * $0 }.reduce(0, +)

        let denominator = n * sumXX - sumX * sumX
        guard denominator != 0 else { return 0 }

        return (n * sumXY - sumX * sumY) / denominator
    }

    // MARK: - Rationale Generation

    private func generateRationale(
        recovery: RecoveryScore,
        loadStatus: WeeklyLoadStatus,
        range: ClosedRange<Double>
    ) -> String {
        let recoveryContext: String
        switch recovery.category {
        case .optimal:
            recoveryContext = "Your recovery is strong"
        case .moderate:
            recoveryContext = "You're moderately recovered"
        case .poor:
            recoveryContext = "Your body needs more rest"
        }

        let loadContext: String
        switch loadStatus {
        case .underLoaded:
            loadContext = "you could increase training volume"
        case .optimal:
            loadContext = "your training load is well balanced"
        case .building:
            loadContext = "you're progressively building fitness"
        case .peaking:
            loadContext = "you're training at high volume"
        case .overReaching:
            loadContext = "consider reducing intensity"
        case .deloading:
            loadContext = "you're in a recovery phase"
        case .unknown:
            loadContext = "keep training consistently"
        }

        return "\(recoveryContext) — \(loadContext)"
    }
}

// MARK: - Supporting Types

public struct StrainGuidance: Sendable, Equatable {
    public let recommendedRange: ClosedRange<Double>
    public let weeklyLoadStatus: WeeklyLoadStatus
    public let rationale: String

    public var formattedRange: String {
        "\(Int(recommendedRange.lowerBound))-\(Int(recommendedRange.upperBound))"
    }

    public var targetMidpoint: Double {
        (recommendedRange.lowerBound + recommendedRange.upperBound) / 2
    }
}

public enum WeeklyLoadStatus: String, Sendable {
    case underLoaded = "Under-loaded"
    case optimal = "Optimal"
    case building = "Building"
    case peaking = "Peaking"
    case overReaching = "Over-reaching"
    case deloading = "Deloading"
    case unknown = "Analyzing"

    public var displayName: String { rawValue }

    public var description: String {
        switch self {
        case .underLoaded:
            return "Training volume is below target"
        case .optimal:
            return "Training load is well balanced"
        case .building:
            return "Progressively increasing load"
        case .peaking:
            return "High training volume phase"
        case .overReaching:
            return "Consider reducing intensity"
        case .deloading:
            return "Recovery-focused phase"
        case .unknown:
            return "Building training history"
        }
    }
}
