import Foundation

// MARK: - Watch -> iPhone Payload

/// Data payload sent from Watch to iPhone containing collected health samples
public struct WatchDataPayload: Codable, Sendable {
    public let timestamp: Date
    public let heartRateSamples: [HeartRateSample]
    public let hrvSamples: [HRVSample]
    public let completedWorkouts: [WorkoutSession]
    public let lastSyncTimestamp: Date

    public init(
        timestamp: Date = Date(),
        heartRateSamples: [HeartRateSample],
        hrvSamples: [HRVSample],
        completedWorkouts: [WorkoutSession] = [],
        lastSyncTimestamp: Date
    ) {
        self.timestamp = timestamp
        self.heartRateSamples = heartRateSamples
        self.hrvSamples = hrvSamples
        self.completedWorkouts = completedWorkouts
        self.lastSyncTimestamp = lastSyncTimestamp
    }

    /// Returns true if there is any data to sync
    public var hasData: Bool {
        !heartRateSamples.isEmpty || !hrvSamples.isEmpty || !completedWorkouts.isEmpty
    }
}

// MARK: - iPhone -> Watch Payload

/// Data payload sent from iPhone to Watch containing computed scores and insights
public struct PhoneSyncPayload: Codable, Sendable {
    public let timestamp: Date
    public let recovery: RecoveryScore?
    public let strain: StrainScore?
    public let sleep: SleepScore?
    public let baseline: UserBaseline
    public let strainGuidance: StrainGuidance?
    public let dailyInsight: DailyInsight?
    public let scoreHistory: ScoreHistory?

    public init(
        timestamp: Date = Date(),
        recovery: RecoveryScore?,
        strain: StrainScore?,
        sleep: SleepScore?,
        baseline: UserBaseline,
        strainGuidance: StrainGuidance? = nil,
        dailyInsight: DailyInsight? = nil,
        scoreHistory: ScoreHistory? = nil
    ) {
        self.timestamp = timestamp
        self.recovery = recovery
        self.strain = strain
        self.sleep = sleep
        self.baseline = baseline
        self.strainGuidance = strainGuidance
        self.dailyInsight = dailyInsight
        self.scoreHistory = scoreHistory
    }
}

// MARK: - Score History

/// Historical scores for displaying trends on Watch
public struct ScoreHistory: Codable, Sendable, Equatable {
    public let recoveryScores: [RecoveryScore]
    public let strainScores: [StrainScore]
    public let sleepScores: [SleepScore]

    public init(
        recoveryScores: [RecoveryScore] = [],
        strainScores: [StrainScore] = [],
        sleepScores: [SleepScore] = []
    ) {
        self.recoveryScores = recoveryScores
        self.strainScores = strainScores
        self.sleepScores = sleepScores
    }

    /// Returns the most recent N days of recovery scores
    public func recentRecoveryScores(days: Int) -> [RecoveryScore] {
        Array(recoveryScores.suffix(days))
    }

    /// Returns the most recent N days of strain scores
    public func recentStrainScores(days: Int) -> [StrainScore] {
        Array(strainScores.suffix(days))
    }

    /// Returns the most recent N days of sleep scores
    public func recentSleepScores(days: Int) -> [SleepScore] {
        Array(sleepScores.suffix(days))
    }
}
