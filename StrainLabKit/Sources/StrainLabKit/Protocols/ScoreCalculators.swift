import Foundation

public protocol RecoveryScoreCalculating: Sendable {
    func calculate(
        currentHRV: Double,
        currentRHR: Double,
        hrvBaseline: Double,
        rhrBaseline: Double,
        sleepQuality: Double
    ) -> RecoveryScore
}

public protocol StrainScoreCalculating: Sendable {
    func calculate(
        heartRateSamples: [HeartRateSample],
        maxHeartRate: Double,
        workouts: [WorkoutSession]
    ) -> StrainScore
}

public protocol SleepScoreCalculating: Sendable {
    func calculate(
        session: SleepSession,
        sleepNeedMinutes: Double
    ) -> SleepScore
}
