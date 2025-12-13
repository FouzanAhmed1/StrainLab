import Foundation
import StrainLabKit

/// Central engine that coordinates score calculations and baseline updates
public actor ScoreEngine {
    private let recoveryCalculator = RecoveryScoreCalculator()
    private let strainCalculator = StrainScoreCalculator()
    private let sleepCalculator = SleepScoreCalculator()
    private let baselineCalculator = BaselineCalculator()
    private let hrvProcessor = HRVProcessor()

    private let coreDataManager: CoreDataManager
    private let healthKitManager: iOSHealthKitManager

    public init(coreDataManager: CoreDataManager, healthKitManager: iOSHealthKitManager) {
        self.coreDataManager = coreDataManager
        self.healthKitManager = healthKitManager
    }

    /// Calculate today's recovery score
    public func calculateTodayRecovery() async throws -> RecoveryScore {
        let baseline = try await getOrCreateBaseline()
        let today = Date()

        let hrvSamples = try await healthKitManager.fetchHRVSamples(
            from: today.daysAgo(1),
            to: today
        )

        let currentHRV = hrvSamples.last?.sdnnMilliseconds ?? baseline.hrvBaseline7Day

        let rhr = try await healthKitManager.fetchRestingHeartRate(for: today)
        let currentRHR = rhr ?? baseline.rhrBaseline7Day

        let sleepSessions = try await healthKitManager.fetchSleepSessions(
            from: today.daysAgo(1),
            to: today
        )

        var sleepQuality = 70.0
        if let lastSleep = sleepSessions.last {
            let sleepScore = sleepCalculator.calculate(
                session: lastSleep,
                sleepNeedMinutes: baseline.sleepNeedMinutes
            )
            sleepQuality = sleepScore.score
        }

        let score = recoveryCalculator.calculate(
            currentHRV: currentHRV,
            currentRHR: currentRHR,
            hrvBaseline: baseline.hrvBaseline7Day,
            rhrBaseline: baseline.rhrBaseline7Day,
            sleepQuality: sleepQuality
        )

        try await coreDataManager.saveRecoveryScore(score)

        return score
    }

    /// Calculate today's strain score
    public func calculateTodayStrain() async throws -> StrainScore {
        let baseline = try await getOrCreateBaseline()
        let today = Date().startOfDay
        let now = Date()

        let heartRateSamples = try await healthKitManager.fetchHeartRateSamples(
            from: today,
            to: now
        )

        let workouts = try await healthKitManager.fetchWorkouts(
            from: today,
            to: now
        )

        let score = strainCalculator.calculate(
            heartRateSamples: heartRateSamples,
            maxHeartRate: baseline.maxHeartRate,
            workouts: workouts
        )

        try await coreDataManager.saveStrainScore(score)

        return score
    }

    /// Calculate last night's sleep score
    public func calculateLastNightSleep() async throws -> SleepScore? {
        let baseline = try await getOrCreateBaseline()
        let today = Date()

        let sleepSessions = try await healthKitManager.fetchSleepSessions(
            from: today.daysAgo(1),
            to: today
        )

        guard let lastSleep = sleepSessions.last else {
            return nil
        }

        let score = sleepCalculator.calculate(
            session: lastSleep,
            sleepNeedMinutes: baseline.sleepNeedMinutes
        )

        try await coreDataManager.saveSleepScore(score)

        return score
    }

    /// Get or create user baseline
    public func getOrCreateBaseline() async throws -> UserBaseline {
        if let existing = try await coreDataManager.fetchLatestUserBaseline() {
            if Calendar.current.isDateInToday(existing.date) {
                return existing
            }
        }

        return try await updateBaseline()
    }

    /// Update baseline with latest 7 day averages
    public func updateBaseline() async throws -> UserBaseline {
        let hrvValues = try await coreDataManager.fetchHRVValues(days: 7)
        let rhrValues = try await coreDataManager.fetchRHRValues(days: 7)

        let cleanedHRV = baselineCalculator.detectOutliers(values: hrvValues)
        let cleanedRHR = baselineCalculator.detectOutliers(values: rhrValues)

        let hrvBaseline = cleanedHRV.isEmpty ? 50.0 : baselineCalculator.calculateRollingAverage(values: cleanedHRV, days: 7)
        let rhrBaseline = cleanedRHR.isEmpty ? 60.0 : baselineCalculator.calculateRollingAverage(values: cleanedRHR, days: 7)

        let existing = try await coreDataManager.fetchLatestUserBaseline()
        let maxHR = existing?.maxHeartRate ?? 190.0
        let sleepNeed = existing?.sleepNeedMinutes ?? 450.0

        let baseline = UserBaseline(
            date: Date(),
            hrvBaseline7Day: hrvBaseline,
            rhrBaseline7Day: rhrBaseline,
            sleepNeedMinutes: sleepNeed,
            maxHeartRate: maxHR
        )

        try await coreDataManager.saveUserBaseline(baseline)

        return baseline
    }

    /// Fetch historical scores for trends
    public func fetchWeeklyTrends() async throws -> (
        recovery: [RecoveryScore],
        strain: [StrainScore],
        sleep: [SleepScore]
    ) {
        let today = Date()
        let weekAgo = today.daysAgo(7)

        let recovery = try await coreDataManager.fetchRecoveryScores(from: weekAgo, to: today)
        let strain = try await coreDataManager.fetchStrainScores(from: weekAgo, to: today)
        let sleep = try await coreDataManager.fetchSleepScores(from: weekAgo, to: today)

        return (recovery, strain, sleep)
    }

    /// Process incoming data from Watch
    public func processWatchData(
        heartRateSamples: [HeartRateSample]?,
        hrvSamples: [HRVSample]?,
        workout: WorkoutSession?
    ) async throws {
        if let hrSamples = heartRateSamples, !hrSamples.isEmpty {
            try await coreDataManager.saveHeartRateSamples(hrSamples)
        }

        if let hrvData = hrvSamples, !hrvData.isEmpty {
            try await coreDataManager.saveHRVSamples(hrvData)
        }

        if workout != nil {
            _ = try await calculateTodayStrain()
        }
    }
}
