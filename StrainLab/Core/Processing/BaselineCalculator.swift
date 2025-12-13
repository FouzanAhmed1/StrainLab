import Foundation
import StrainLabKit

public struct BaselineCalculator: BaselineCalculating, Sendable {

    public init() {}

    /// Calculate rolling average over specified number of days
    /// Takes the most recent N values for the calculation
    public func calculateRollingAverage(values: [Double], days: Int) -> Double {
        guard !values.isEmpty else { return 0 }

        let count = min(values.count, days)
        let recentValues = Array(values.suffix(count))
        return recentValues.reduce(0, +) / Double(count)
    }

    /// Detect and remove outliers using IQR method
    /// Returns values with outliers removed
    /// threshold: multiplier for IQR (1.5 is standard, 3.0 is extreme)
    public func detectOutliers(values: [Double], threshold: Double = 1.5) -> [Double] {
        guard values.count >= 4 else { return values }

        let sorted = values.sorted()
        let q1Index = sorted.count / 4
        let q3Index = (sorted.count * 3) / 4

        let q1 = sorted[q1Index]
        let q3 = sorted[q3Index]
        let iqr = q3 - q1

        let lowerBound = q1 - (threshold * iqr)
        let upperBound = q3 + (threshold * iqr)

        return values.filter { $0 >= lowerBound && $0 <= upperBound }
    }

    /// Apply moving average smoothing
    /// windowSize: number of points to average (should be odd for centering)
    public func smoothValues(values: [Double], windowSize: Int = 3) -> [Double] {
        guard values.count >= windowSize && windowSize > 0 else { return values }

        var smoothed: [Double] = []
        let halfWindow = windowSize / 2

        for i in 0..<values.count {
            let start = max(0, i - halfWindow)
            let end = min(values.count, i + halfWindow + 1)
            let window = Array(values[start..<end])
            smoothed.append(window.reduce(0, +) / Double(window.count))
        }

        return smoothed
    }

    /// Calculate personalized sleep need based on historical correlation
    /// between sleep duration and recovery scores
    public func calculateSleepNeed(
        sleepDurations: [Double],
        recoveryScores: [Double]
    ) -> Double {
        let defaultSleepNeed = 450.0

        guard sleepDurations.count >= 7,
              sleepDurations.count == recoveryScores.count else {
            return defaultSleepNeed
        }

        let goodRecoveryIndices = recoveryScores.indices.filter { recoveryScores[$0] >= 67 }

        guard !goodRecoveryIndices.isEmpty else {
            return defaultSleepNeed
        }

        let goodSleepDurations = goodRecoveryIndices.map { sleepDurations[$0] }
        let avgGoodSleep = goodSleepDurations.reduce(0, +) / Double(goodSleepDurations.count)

        return min(max(avgGoodSleep, 360), 600)
    }

    /// Calculate coefficient of variation for baseline stability assessment
    /// Lower CV indicates more stable baseline
    public func calculateCoefficientOfVariation(values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }

        let mean = values.reduce(0, +) / Double(values.count)
        guard mean > 0 else { return 0 }

        let squaredDiffs = values.map { pow($0 - mean, 2) }
        let variance = squaredDiffs.reduce(0, +) / Double(values.count)
        let stdDev = sqrt(variance)

        return (stdDev / mean) * 100
    }

    /// Calculate trend direction (positive = improving, negative = declining)
    /// Uses simple linear regression slope
    public func calculateTrend(values: [Double]) -> Double {
        guard values.count >= 2 else { return 0 }

        let n = Double(values.count)
        let indices = Array(0..<values.count).map { Double($0) }

        let sumX = indices.reduce(0, +)
        let sumY = values.reduce(0, +)
        let sumXY = zip(indices, values).map { $0 * $1 }.reduce(0, +)
        let sumXX = indices.map { $0 * $0 }.reduce(0, +)

        let slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX)
        return slope
    }

    /// Determine if baseline is reliable (enough data, low variance)
    public func isBaselineReliable(
        values: [Double],
        minimumDays: Int = 7,
        maxCoefficientOfVariation: Double = 30
    ) -> Bool {
        guard values.count >= minimumDays else { return false }

        let cv = calculateCoefficientOfVariation(values)
        return cv <= maxCoefficientOfVariation
    }
}
