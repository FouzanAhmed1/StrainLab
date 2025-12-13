import Foundation
import StrainLabKit

/// Generates short insights optimized for Apple Watch display
/// Max ~40 characters for main insight, ~20 for complications
public struct WatchInsightGenerator: Sendable {

    public init() {}

    /// Generate a short insight headline for the Watch main screen
    /// Target: ~40 characters max
    public func generateShortInsight(recovery: RecoveryScore?) -> String {
        guard let recovery = recovery else {
            return "Sync for recovery data"
        }

        switch recovery.category {
        case .optimal:
            return generateOptimalInsight(recovery: recovery)
        case .moderate:
            return generateModerateInsight(recovery: recovery)
        case .poor:
            return generatePoorInsight(recovery: recovery)
        }
    }

    /// Generate a very short insight for complications
    /// Target: ~20 characters max
    public func generateComplicationInsight(recovery: RecoveryScore?) -> String {
        guard let recovery = recovery else {
            return "Sync needed"
        }

        switch recovery.category {
        case .optimal:
            return "Ready to push"
        case .moderate:
            return "Balanced day"
        case .poor:
            return "Take it easy"
        }
    }

    /// Generate strain guidance text
    public func generateStrainGuidanceText(
        guidance: StrainGuidance?,
        currentStrain: Double
    ) -> String {
        guard let guidance = guidance else {
            return "Target: sync for guidance"
        }

        let remaining = guidance.remainingToTarget(currentStrain: currentStrain)

        if remaining > 0 {
            return String(format: "%.1f more to target", remaining)
        } else {
            let over = guidance.overTarget(currentStrain: currentStrain)
            if over > 0 {
                return "Target reached, consider rest"
            } else {
                return "In target range"
            }
        }
    }

    /// Generate a short recommendation based on recovery
    public func generateShortRecommendation(recovery: RecoveryScore) -> String {
        switch recovery.category {
        case .optimal:
            return "Great day to push harder"
        case .moderate:
            return "Listen to your body today"
        case .poor:
            return "Prioritize rest and recovery"
        }
    }

    // MARK: - Private Methods

    private func generateOptimalInsight(recovery: RecoveryScore) -> String {
        let hrvDeviation = recovery.components.hrvDeviation

        if hrvDeviation > 15 {
            return "HRV is strong. Push today!"
        } else if hrvDeviation > 5 {
            return "Well recovered. Ready to go"
        } else {
            return "Good recovery. Train hard"
        }
    }

    private func generateModerateInsight(recovery: RecoveryScore) -> String {
        let hrvDeviation = recovery.components.hrvDeviation
        let rhrDeviation = recovery.components.rhrDeviation

        if rhrDeviation > 5 {
            return "RHR elevated. Balanced effort"
        } else if hrvDeviation < -5 {
            return "HRV slightly low. Pace yourself"
        } else {
            return "Mixed signals. Listen to body"
        }
    }

    private func generatePoorInsight(recovery: RecoveryScore) -> String {
        let hrvDeviation = recovery.components.hrvDeviation
        let sleepQuality = recovery.components.sleepQuality

        if sleepQuality < 50 {
            return "Sleep was short. Rest today"
        } else if hrvDeviation < -15 {
            return "HRV is low. Recovery needed"
        } else {
            return "Body needs rest. Take it easy"
        }
    }
}
