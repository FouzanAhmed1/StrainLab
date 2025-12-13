import Foundation
import StrainLabKit

public struct BaselineCalculator: BaselineCalculating, Sendable {

    public init() {}

    // MARK: - Adaptive Baseline Calculation

    /// Calculate adaptive baseline using weighted multi-window approach
    /// Recent data is weighted more heavily than older data
    public func calculateAdaptiveBaseline(values: [Double]) -> AdaptiveBaseline {
        guard !values.isEmpty else {
            return AdaptiveBaseline(value: 0, confidence: 0, phase: .initial)
        }

        let daysAvailable = values.count
        let phase = determineBaselinePhase(daysAvailable: daysAvailable)

        switch phase {
        case .initial:
            // Days 1-6: Simple average of available data
            let avg = values.reduce(0, +) / Double(values.count)
            let confidence = Double(daysAvailable) / 7.0
            return AdaptiveBaseline(value: avg, confidence: confidence, phase: phase)

        case .calibrating:
            // Days 7-13: 7-day weighted average
            let baseline = calculateWeightedAverage(values: Array(values.suffix(7)))
            let confidence = 0.5 + (Double(daysAvailable - 7) / 14.0)
            return AdaptiveBaseline(value: baseline, confidence: min(confidence, 0.7), phase: phase)

        case .established:
            // Days 14-27: Blend of 7-day and 14-day with recent bias
            let recent7 = calculateWeightedAverage(values: Array(values.suffix(7)))
            let recent14 = calculateWeightedAverage(values: Array(values.suffix(14)))
            let blended = recent7 * 0.6 + recent14 * 0.4
            let confidence = 0.7 + (Double(daysAvailable - 14) / 56.0)
            return AdaptiveBaseline(value: blended, confidence: min(confidence, 0.85), phase: phase)

        case .refined, .mature:
            // Days 28+: Full multi-window weighted baseline
            let recent7 = calculateWeightedAverage(values: Array(values.suffix(7)))
            let recent14 = calculateWeightedAverage(values: Array(values.suffix(14)))
            let recent28 = calculateWeightedAverage(values: Array(values.suffix(28)))
            // Weight: 50% recent week, 30% 2-week, 20% 4-week
            let blended = recent7 * 0.5 + recent14 * 0.3 + recent28 * 0.2
            return AdaptiveBaseline(value: blended, confidence: 0.95, phase: .mature)
        }
    }

    /// Calculate weighted average with exponential decay (recent = higher weight)
    public func calculateWeightedAverage(values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }

        // Exponential decay: most recent value has highest weight
        let decayFactor = 0.9
        var weights: [Double] = []
        var weight = 1.0

        for _ in 0..<values.count {
            weights.insert(weight, at: 0)
            weight *= decayFactor
        }

        let totalWeight = weights.reduce(0, +)
        let weightedSum = zip(values, weights).map { $0 * $1 }.reduce(0, +)

        return weightedSum / totalWeight
    }

    private func determineBaselinePhase(daysAvailable: Int) -> BaselinePhase {
        switch daysAvailable {
        case 0...6: return .initial
        case 7...13: return .calibrating
        case 14...27: return .established
        case 28...59: return .refined
        default: return .mature
        }
    }

    // MARK: - Simple Rolling Average (legacy support)

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

        let cv = calculateCoefficientOfVariation(values: values)
        return cv <= maxCoefficientOfVariation
    }
}

// MARK: - Supporting Types

public struct AdaptiveBaseline: Sendable, Equatable {
    public let value: Double
    public let confidence: Double // 0-1
    public let phase: BaselinePhase

    public var isReliable: Bool {
        confidence >= 0.7
    }
}

public enum BaselinePhase: String, Sendable {
    case initial = "Getting started"
    case calibrating = "Calibrating"
    case established = "Established"
    case refined = "Refined"
    case mature = "Personalized"

    public var displayName: String { rawValue }
}
