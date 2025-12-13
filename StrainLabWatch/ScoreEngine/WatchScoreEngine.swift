import Foundation
import StrainLabKit
import WidgetKit

/// Orchestrates score calculation and management on Apple Watch
/// Provides offline-capable scoring with sync support from iPhone
@Observable
public final class WatchScoreEngine: @unchecked Sendable {

    public static let shared = WatchScoreEngine()

    // MARK: - Published State

    public private(set) var recoveryScore: RecoveryScore?
    public private(set) var strainScore: StrainScore?
    public private(set) var sleepScore: SleepScore?
    public private(set) var strainGuidance: StrainGuidance?
    public private(set) var dailyInsight: DailyInsight?
    public private(set) var shortInsight: String?

    // History for trends
    public private(set) var recoveryHistory: [RecoveryScore] = []
    public private(set) var strainHistory: [StrainScore] = []
    public private(set) var sleepHistory: [SleepScore] = []

    // Baseline (synced from iPhone)
    public private(set) var baseline: UserBaseline?

    // Sync state
    public private(set) var isLocalCalculation: Bool = false
    public private(set) var lastSyncDate: Date?

    // MARK: - Private Properties

    private let dataStore: WatchDataStore
    private let recoveryCalculator: WatchRecoveryCalculator
    private let strainCalculator: WatchStrainCalculator
    private let insightGenerator: WatchInsightGenerator

    // MARK: - Initialization

    private init() {
        self.dataStore = WatchDataStore.shared
        self.recoveryCalculator = WatchRecoveryCalculator()
        self.strainCalculator = WatchStrainCalculator()
        self.insightGenerator = WatchInsightGenerator()
    }

    // MARK: - Load Cached Data

    /// Loads cached scores from local storage on app launch
    public func loadCachedScores() async {
        await MainActor.run {
            self.recoveryScore = dataStore.getRecoveryScore()
            self.strainScore = dataStore.getStrainScore()
            self.sleepScore = dataStore.getSleepScore()
            self.baseline = dataStore.getBaseline()
            self.strainGuidance = dataStore.getStrainGuidance()
            self.dailyInsight = dataStore.getDailyInsight()
            self.shortInsight = dataStore.getShortInsight()
            self.recoveryHistory = dataStore.getRecoveryHistory()
            self.strainHistory = dataStore.getStrainHistory()
            self.sleepHistory = dataStore.getSleepHistory()
            self.isLocalCalculation = dataStore.getIsLocalCalculation()
            self.lastSyncDate = dataStore.getLastPhoneSyncDate()
        }
    }

    // MARK: - Sync from iPhone

    /// Receives and processes scores synced from iPhone
    /// This is the primary source of truth when connected
    public func syncScoresFromPhone(_ payload: PhoneSyncPayload) async {
        await MainActor.run {
            // Update scores
            self.recoveryScore = payload.recovery
            self.strainScore = payload.strain
            self.sleepScore = payload.sleep
            self.baseline = payload.baseline
            self.strainGuidance = payload.strainGuidance
            self.dailyInsight = payload.dailyInsight
            self.isLocalCalculation = false
            self.lastSyncDate = payload.timestamp

            // Update history if provided
            if let history = payload.scoreHistory {
                self.recoveryHistory = history.recoveryScores
                self.strainHistory = history.strainScores
                self.sleepHistory = history.sleepScores
            }

            // Generate short insight for complications
            self.shortInsight = insightGenerator.generateShortInsight(
                recovery: payload.recovery
            )
        }

        // Persist to local storage
        await saveToDataStore()

        // Reload complications
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Local Calculation (Offline Mode)

    /// Calculates scores locally when iPhone is not available
    /// Uses simplified algorithms and cached baseline
    public func calculateLocalScores(
        overnightHRV: [HRVSample],
        restingHeartRate: Double?,
        sleepDurationMinutes: Double?,
        todayHeartRateSamples: [HeartRateSample]
    ) async {
        guard let baseline = self.baseline else {
            // Cannot calculate without baseline, use defaults
            await MainActor.run {
                self.shortInsight = "Sync with iPhone for scores"
                self.isLocalCalculation = true
            }
            return
        }

        // Calculate recovery
        let calculatedRecovery = recoveryCalculator.calculate(
            overnightHRV: overnightHRV,
            restingHeartRate: restingHeartRate,
            sleepDurationMinutes: sleepDurationMinutes,
            baseline: baseline
        )

        // Calculate strain
        let calculatedStrain = strainCalculator.calculate(
            heartRateSamples: todayHeartRateSamples,
            maxHeartRate: baseline.maxHeartRate
        )

        // Generate short insight
        let insight = insightGenerator.generateShortInsight(
            recovery: calculatedRecovery
        )

        // Generate basic strain guidance
        let guidance = calculateBasicGuidance(recovery: calculatedRecovery)

        await MainActor.run {
            self.recoveryScore = calculatedRecovery
            self.strainScore = calculatedStrain
            self.strainGuidance = guidance
            self.shortInsight = insight
            self.isLocalCalculation = true
        }

        // Persist
        await saveToDataStore()

        // Reload complications
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Live Strain Updates (During Workouts)

    /// Updates strain score in real-time during workouts
    public func updateLiveStrain(
        heartRateSamples: [HeartRateSample]
    ) async {
        guard let baseline = self.baseline else { return }

        let updatedStrain = strainCalculator.calculate(
            heartRateSamples: heartRateSamples,
            maxHeartRate: baseline.maxHeartRate
        )

        await MainActor.run {
            self.strainScore = updatedStrain
        }

        // Save but don't reload complications (too frequent)
        dataStore.saveStrainScore(updatedStrain)
    }

    // MARK: - Helpers

    private func calculateBasicGuidance(recovery: RecoveryScore?) -> StrainGuidance? {
        guard let recovery = recovery else { return nil }

        let range: ClosedRange<Double>
        switch recovery.category {
        case .optimal:
            range = 14...18
        case .moderate:
            range = 10...14
        case .poor:
            range = 4...8
        }

        return StrainGuidance(
            recommendedRange: range,
            weeklyLoadStatus: .unknown,
            rationale: "Based on today's recovery"
        )
    }

    private func saveToDataStore() async {
        if let recovery = recoveryScore {
            dataStore.saveRecoveryScore(recovery)
        }
        if let strain = strainScore {
            dataStore.saveStrainScore(strain)
        }
        if let sleep = sleepScore {
            dataStore.saveSleepScore(sleep)
        }
        if let baseline = baseline {
            dataStore.saveBaseline(baseline)
        }
        if let guidance = strainGuidance {
            dataStore.saveStrainGuidance(guidance)
        }
        if let insight = dailyInsight {
            dataStore.saveDailyInsight(insight)
        }
        if let shortInsight = shortInsight {
            dataStore.saveShortInsight(shortInsight)
        }

        dataStore.saveRecoveryHistory(recoveryHistory)
        dataStore.saveStrainHistory(strainHistory)
        dataStore.saveSleepHistory(sleepHistory)
        dataStore.setIsLocalCalculation(isLocalCalculation)

        if let syncDate = lastSyncDate {
            dataStore.setLastPhoneSyncDate(syncDate)
        }
    }

    // MARK: - Data for Complications

    /// Returns current data formatted for complications
    public func getComplicationData() -> ComplicationData {
        ComplicationData(
            recoveryScore: recoveryScore?.score ?? 0,
            recoveryCategory: recoveryScore?.category ?? .moderate,
            strainScore: strainScore?.score ?? 0,
            targetRange: strainGuidance?.recommendedRange,
            shortInsight: shortInsight
        )
    }
}

// MARK: - Complication Data

public struct ComplicationData: Sendable {
    public let recoveryScore: Double
    public let recoveryCategory: RecoveryScore.Category
    public let strainScore: Double
    public let targetRange: ClosedRange<Double>?
    public let shortInsight: String?

    public var formattedRecoveryScore: String {
        "\(Int(recoveryScore))"
    }

    public var formattedStrainScore: String {
        String(format: "%.1f", strainScore)
    }

    public var formattedTargetRange: String? {
        guard let range = targetRange else { return nil }
        return "\(Int(range.lowerBound))-\(Int(range.upperBound))"
    }
}
