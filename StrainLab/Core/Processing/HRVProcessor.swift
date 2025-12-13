import Foundation
import StrainLabKit

public struct HRVProcessor: Sendable {

    public init() {}

    /// Calculate RMSSD from R-R intervals in milliseconds
    /// RMSSD = sqrt(mean(successive_differences^2))
    /// This is the gold standard for parasympathetic activity measurement
    public func calculateRMSSD(rrIntervals: [Double]) -> Double {
        guard rrIntervals.count > 1 else { return 0 }

        var sumSquaredDiffs: Double = 0
        for i in 1..<rrIntervals.count {
            let diff = rrIntervals[i] - rrIntervals[i - 1]
            sumSquaredDiffs += diff * diff
        }

        let meanSquaredDiff = sumSquaredDiffs / Double(rrIntervals.count - 1)
        return sqrt(meanSquaredDiff)
    }

    /// Calculate ln(RMSSD) for more linear distribution
    /// Typical range: 2.0 to 5.0 (roughly 7ms to 150ms RMSSD)
    public func calculateLnRMSSD(rrIntervals: [Double]) -> Double {
        let rmssd = calculateRMSSD(rrIntervals: rrIntervals)
        guard rmssd > 0 else { return 0 }
        return log(rmssd)
    }

    /// Calculate SDNN (Standard Deviation of NN intervals)
    /// Apple Watch provides this directly as heartRateVariabilitySDNN
    /// Reflects overall HRV including both sympathetic and parasympathetic
    public func calculateSDNN(rrIntervals: [Double]) -> Double {
        guard !rrIntervals.isEmpty else { return 0 }

        let mean = rrIntervals.reduce(0, +) / Double(rrIntervals.count)
        let squaredDiffs = rrIntervals.map { pow($0 - mean, 2) }
        let variance = squaredDiffs.reduce(0, +) / Double(rrIntervals.count)

        return sqrt(variance)
    }

    /// Convert SDNN to estimated RMSSD
    /// Rough approximation: RMSSD ≈ SDNN * 0.8 for resting measurements
    /// This is used when only SDNN is available (Apple Watch default)
    public func estimateRMSSDFromSDNN(_ sdnn: Double) -> Double {
        return sdnn * 0.8
    }

    /// Calculate pNN50 (percentage of successive intervals differing by > 50ms)
    /// Another parasympathetic marker, complements RMSSD
    public func calculatePNN50(rrIntervals: [Double]) -> Double {
        guard rrIntervals.count > 1 else { return 0 }

        var countOver50 = 0
        for i in 1..<rrIntervals.count {
            let diff = abs(rrIntervals[i] - rrIntervals[i - 1])
            if diff > 50 {
                countOver50 += 1
            }
        }

        return Double(countOver50) / Double(rrIntervals.count - 1) * 100
    }

    /// Clean R-R intervals by removing physiologically implausible values
    /// Normal R-R range: 300ms (200 bpm) to 2000ms (30 bpm)
    public func cleanRRIntervals(_ intervals: [Double]) -> [Double] {
        return intervals.filter { $0 >= 300 && $0 <= 2000 }
    }

    /// Detect and remove ectopic beats using difference threshold
    /// Ectopic beats appear as large deviations from surrounding intervals
    public func removeEctopicBeats(_ intervals: [Double], threshold: Double = 0.2) -> [Double] {
        guard intervals.count >= 3 else { return intervals }

        var cleaned: [Double] = [intervals[0]]

        for i in 1..<(intervals.count - 1) {
            let prev = intervals[i - 1]
            let current = intervals[i]
            let next = intervals[i + 1]

            let avgSurrounding = (prev + next) / 2
            let deviation = abs(current - avgSurrounding) / avgSurrounding

            if deviation < threshold {
                cleaned.append(current)
            }
        }

        cleaned.append(intervals.last!)
        return cleaned
    }
}
