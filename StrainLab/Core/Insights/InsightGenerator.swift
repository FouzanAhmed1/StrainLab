import Foundation
import StrainLabKit

/// Generates natural language daily insights based on recovery, strain, and sleep data
public actor InsightGenerator {

    public init() {}

    /// Generate a daily insight combining all available metrics
    public func generateInsight(
        recovery: RecoveryScore?,
        strain: StrainScore?,
        sleep: SleepScore?,
        previousDayStrain: StrainScore?
    ) -> DailyInsight {
        // No data scenario
        guard recovery != nil || sleep != nil else {
            return .noData
        }

        var factors: [DailyInsight.Factor] = []
        var positiveSignals = 0
        var negativeSignals = 0

        // Analyze HRV
        if let recovery = recovery {
            let hrvFactor = analyzeHRV(recovery: recovery)
            factors.append(hrvFactor)
            updateSignalCounts(status: hrvFactor.status, positive: &positiveSignals, negative: &negativeSignals)

            // Analyze RHR
            let rhrFactor = analyzeRHR(recovery: recovery)
            factors.append(rhrFactor)
            updateSignalCounts(status: rhrFactor.status, positive: &positiveSignals, negative: &negativeSignals)
        }

        // Analyze Sleep
        if let sleep = sleep {
            let sleepFactor = analyzeSleep(sleep: sleep)
            factors.append(sleepFactor)
            updateSignalCounts(status: sleepFactor.status, positive: &positiveSignals, negative: &negativeSignals)
        }

        // Analyze previous day strain
        if let previousStrain = previousDayStrain {
            let strainFactor = analyzePreviousStrain(strain: previousStrain)
            factors.append(strainFactor)
            updateSignalCounts(status: strainFactor.status, positive: &positiveSignals, negative: &negativeSignals)
        }

        // Determine confidence
        let confidence = determineConfidence(
            hasRecovery: recovery != nil,
            hasSleep: sleep != nil,
            factors: factors
        )

        // Generate headline and recommendation
        let (headline, recommendation) = generateText(
            recovery: recovery,
            sleep: sleep,
            strain: strain,
            previousStrain: previousDayStrain,
            positiveSignals: positiveSignals,
            negativeSignals: negativeSignals
        )

        return DailyInsight(
            headline: headline,
            recommendation: recommendation,
            confidence: confidence,
            factors: factors
        )
    }

    // MARK: - Factor Analysis

    private func analyzeHRV(recovery: RecoveryScore) -> DailyInsight.Factor {
        let deviation = recovery.components.hrvDeviation

        if deviation > 10 {
            return DailyInsight.Factor(
                type: .hrv,
                status: .positive,
                description: "HRV is \(Int(deviation))% above your baseline"
            )
        } else if deviation < -10 {
            return DailyInsight.Factor(
                type: .hrv,
                status: .negative,
                description: "HRV is \(Int(abs(deviation)))% below your baseline"
            )
        } else {
            return DailyInsight.Factor(
                type: .hrv,
                status: .neutral,
                description: "HRV is within normal range"
            )
        }
    }

    private func analyzeRHR(recovery: RecoveryScore) -> DailyInsight.Factor {
        let deviation = recovery.components.rhrDeviation

        if deviation < -5 {
            return DailyInsight.Factor(
                type: .restingHeartRate,
                status: .positive,
                description: "Resting HR is lower than usual"
            )
        } else if deviation > 8 {
            return DailyInsight.Factor(
                type: .restingHeartRate,
                status: .negative,
                description: "Resting HR is elevated"
            )
        } else {
            return DailyInsight.Factor(
                type: .restingHeartRate,
                status: .neutral,
                description: "Resting HR is normal"
            )
        }
    }

    private func analyzeSleep(sleep: SleepScore) -> DailyInsight.Factor {
        let score = sleep.score

        if score >= 80 {
            return DailyInsight.Factor(
                type: .sleep,
                status: .positive,
                description: "Sleep was excellent (\(sleep.components.formattedDuration))"
            )
        } else if score >= 60 {
            return DailyInsight.Factor(
                type: .sleep,
                status: .neutral,
                description: "Sleep was adequate (\(sleep.components.formattedDuration))"
            )
        } else {
            return DailyInsight.Factor(
                type: .sleep,
                status: .negative,
                description: "Sleep was insufficient (\(sleep.components.formattedDuration))"
            )
        }
    }

    private func analyzePreviousStrain(strain: StrainScore) -> DailyInsight.Factor {
        if strain.score >= 15 {
            return DailyInsight.Factor(
                type: .strain,
                status: .negative,
                description: "High strain yesterday (\(String(format: "%.1f", strain.score)))"
            )
        } else if strain.score >= 10 {
            return DailyInsight.Factor(
                type: .strain,
                status: .neutral,
                description: "Moderate strain yesterday"
            )
        } else {
            return DailyInsight.Factor(
                type: .strain,
                status: .positive,
                description: "Light strain yesterday — well rested"
            )
        }
    }

    // MARK: - Text Generation

    private func generateText(
        recovery: RecoveryScore?,
        sleep: SleepScore?,
        strain: StrainScore?,
        previousStrain: StrainScore?,
        positiveSignals: Int,
        negativeSignals: Int
    ) -> (headline: String, recommendation: String) {

        guard let recovery = recovery else {
            if let sleep = sleep {
                if sleep.score >= 70 {
                    return ("Sleep was solid last night", "Recovery data will be available soon")
                } else {
                    return ("Sleep could have been better", "Try to prioritize rest today")
                }
            }
            return ("Collecting your data", "Wear your Apple Watch to track metrics")
        }

        // Build headline based on dominant signals
        let headline: String
        let recommendation: String

        switch recovery.category {
        case .optimal:
            if let sleep = sleep, sleep.score >= 75 {
                headline = "HRV is strong and sleep was solid"
            } else {
                headline = "Your body is well recovered"
            }

            if previousStrain?.score ?? 0 < 12 {
                recommendation = "Today is a good day to push harder"
            } else {
                recommendation = "Great recovery — you're ready for whatever today brings"
            }

        case .moderate:
            if negativeSignals > positiveSignals {
                headline = "Mixed signals today"
                recommendation = "Listen to your body during activity"
            } else {
                headline = "Recovery is moderate"
                recommendation = "A balanced training day would work well"
            }

        case .poor:
            if let sleep = sleep, sleep.score < 60 {
                headline = "Sleep was short and recovery is low"
            } else {
                headline = "Your body needs more recovery time"
            }

            if previousStrain?.score ?? 0 >= 15 {
                recommendation = "Consider rest or light activity — yesterday was demanding"
            } else {
                recommendation = "Prioritize recovery today"
            }
        }

        return (headline, recommendation)
    }

    // MARK: - Helpers

    private func updateSignalCounts(status: DailyInsight.Factor.Status, positive: inout Int, negative: inout Int) {
        switch status {
        case .positive:
            positive += 1
        case .negative:
            negative += 1
        case .neutral:
            break
        }
    }

    private func determineConfidence(
        hasRecovery: Bool,
        hasSleep: Bool,
        factors: [DailyInsight.Factor]
    ) -> DailyInsight.Confidence {
        if hasRecovery && hasSleep && factors.count >= 3 {
            return .high
        } else if hasRecovery || (hasSleep && factors.count >= 2) {
            return .moderate
        } else {
            return .low
        }
    }
}
