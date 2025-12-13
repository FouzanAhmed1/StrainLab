import Foundation
import StrainLabKit

/// Assesses the quality and completeness of health data for accurate scoring
public struct DataQualityAssessor: Sendable {

    public init() {}

    // MARK: - Quality Assessment

    /// Comprehensive assessment of data quality for a given date range
    public func assessQuality(
        hrvSamples: [Double],
        rhrSamples: [Double],
        sleepDuration: TimeInterval?,
        activityMinutes: Double,
        daysCovered: Int
    ) -> DataQuality {
        var warnings: [String] = []

        // Assess HRV data
        let hrvQuality = assessHRVQuality(samples: hrvSamples)
        if hrvQuality < 0.5 {
            warnings.append("Limited HRV data available")
        }

        // Assess RHR data
        let rhrQuality = assessRHRQuality(samples: rhrSamples)
        if rhrQuality < 0.5 {
            warnings.append("Limited heart rate data")
        }

        // Assess sleep data
        let sleepQuality = assessSleepQuality(duration: sleepDuration)
        if sleepQuality < 0.5 {
            warnings.append("No sleep data from last night")
        }

        // Assess baseline maturity
        let baselineMaturity = assessBaselineMaturity(daysCovered: daysCovered)
        if baselineMaturity < 0.5 {
            warnings.append("Still calibrating your baseline")
        }

        // Calculate overall confidence
        let weights = DataQualityWeights()
        let overallConfidence = (
            hrvQuality * weights.hrv +
            rhrQuality * weights.rhr +
            sleepQuality * weights.sleep +
            baselineMaturity * weights.baseline
        )

        return DataQuality(
            hrvDataAvailable: !hrvSamples.isEmpty,
            hrvSampleCount: hrvSamples.count,
            rhrDataAvailable: !rhrSamples.isEmpty,
            rhrSampleCount: rhrSamples.count,
            sleepDataAvailable: sleepDuration != nil,
            activityDataAvailable: activityMinutes > 0,
            baselineMaturity: baselineMaturity,
            overallConfidence: overallConfidence,
            warnings: warnings
        )
    }

    /// Quick check if we have minimum data for scoring
    public func hasMinimumData(
        hrvSamples: [Double],
        sleepDuration: TimeInterval?
    ) -> Bool {
        // Need at least one of: HRV data or sleep data
        return !hrvSamples.isEmpty || sleepDuration != nil
    }

    // MARK: - Individual Assessments

    private func assessHRVQuality(samples: [Double]) -> Double {
        // No samples = 0 quality
        guard !samples.isEmpty else { return 0 }

        // Ideal: 3+ overnight samples
        // Good: 2 samples
        // Minimal: 1 sample
        switch samples.count {
        case 0: return 0
        case 1: return 0.4
        case 2: return 0.7
        default: return 1.0
        }
    }

    private func assessRHRQuality(samples: [Double]) -> Double {
        guard !samples.isEmpty else { return 0 }

        // RHR should have multiple readings throughout night
        switch samples.count {
        case 0: return 0
        case 1...5: return 0.5
        case 6...20: return 0.8
        default: return 1.0
        }
    }

    private func assessSleepQuality(duration: TimeInterval?) -> Double {
        guard let duration = duration else { return 0 }

        // Sleep should be at least 3 hours to be meaningful
        let hours = duration / 3600
        if hours < 3 { return 0.3 }
        if hours < 5 { return 0.6 }
        return 1.0
    }

    private func assessBaselineMaturity(daysCovered: Int) -> Double {
        // Baseline reliability increases with more data
        switch daysCovered {
        case 0...2: return 0.2   // Very early
        case 3...6: return 0.4   // Calibrating
        case 7...13: return 0.7  // Initial baseline
        case 14...27: return 0.9 // Good baseline
        default: return 1.0      // Mature baseline
        }
    }

    // MARK: - Baseline Maturity Status

    /// Get user-friendly status of baseline calibration
    public func getBaselineStatus(daysCovered: Int) -> BaselineStatus {
        switch daysCovered {
        case 0...2:
            return BaselineStatus(
                phase: .initial,
                message: "Getting to know you",
                progress: Double(daysCovered) / 7.0
            )
        case 3...6:
            return BaselineStatus(
                phase: .calibrating,
                message: "Calibrating your baseline",
                progress: Double(daysCovered) / 7.0
            )
        case 7...13:
            return BaselineStatus(
                phase: .established,
                message: "Baseline established",
                progress: min(1.0, Double(daysCovered) / 14.0)
            )
        case 14...27:
            return BaselineStatus(
                phase: .refined,
                message: "Baseline refined",
                progress: min(1.0, Double(daysCovered) / 28.0)
            )
        default:
            return BaselineStatus(
                phase: .mature,
                message: "Personalized baseline",
                progress: 1.0
            )
        }
    }
}

// MARK: - Supporting Types

public struct DataQuality: Sendable, Equatable {
    public let hrvDataAvailable: Bool
    public let hrvSampleCount: Int
    public let rhrDataAvailable: Bool
    public let rhrSampleCount: Int
    public let sleepDataAvailable: Bool
    public let activityDataAvailable: Bool
    public let baselineMaturity: Double // 0-1
    public let overallConfidence: Double // 0-1
    public let warnings: [String]

    public var confidenceLevel: ConfidenceLevel {
        switch overallConfidence {
        case 0.8...1.0: return .high
        case 0.5..<0.8: return .moderate
        default: return .low
        }
    }

    public enum ConfidenceLevel: String, Sendable {
        case high = "High confidence"
        case moderate = "Moderate confidence"
        case low = "Limited data"
    }
}

public struct BaselineStatus: Sendable, Equatable {
    public let phase: Phase
    public let message: String
    public let progress: Double // 0-1

    public enum Phase: String, Sendable {
        case initial = "Initial"
        case calibrating = "Calibrating"
        case established = "Established"
        case refined = "Refined"
        case mature = "Personalized"
    }
}

private struct DataQualityWeights {
    let hrv: Double = 0.35
    let rhr: Double = 0.20
    let sleep: Double = 0.25
    let baseline: Double = 0.20
}
