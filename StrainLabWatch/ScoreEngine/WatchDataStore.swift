import Foundation
import StrainLabKit

/// Manages local persistence of scores and data on Apple Watch using UserDefaults
/// Uses App Group for sharing data with complications
public final class WatchDataStore: @unchecked Sendable {

    public static let shared = WatchDataStore()

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Keys

    private enum Keys {
        static let recoveryScore = "watch.score.recovery"
        static let strainScore = "watch.score.strain"
        static let sleepScore = "watch.score.sleep"
        static let baseline = "watch.baseline"
        static let strainGuidance = "watch.strainGuidance"
        static let dailyInsight = "watch.insight"
        static let recoveryHistory = "watch.history.recovery"
        static let strainHistory = "watch.history.strain"
        static let sleepHistory = "watch.history.sleep"
        static let lastPhoneSyncDate = "watch.sync.lastPhone"
        static let lastDataSentDate = "watch.sync.lastDataSent"
        static let pendingHeartRateSamples = "watch.pending.heartRate"
        static let pendingHRVSamples = "watch.pending.hrv"
        static let shortInsight = "watch.insight.short"
        static let isLocalCalculation = "watch.score.isLocal"
    }

    // MARK: - Initialization

    private init() {
        // Use App Group for sharing with complications
        if let groupDefaults = UserDefaults(suiteName: "group.com.strainlab.shared") {
            self.defaults = groupDefaults
        } else {
            // Fallback to standard defaults (complications won't have access)
            self.defaults = UserDefaults.standard
        }
    }

    // MARK: - Score Persistence

    public func saveRecoveryScore(_ score: RecoveryScore) {
        save(score, forKey: Keys.recoveryScore)
    }

    public func getRecoveryScore() -> RecoveryScore? {
        load(RecoveryScore.self, forKey: Keys.recoveryScore)
    }

    public func saveStrainScore(_ score: StrainScore) {
        save(score, forKey: Keys.strainScore)
    }

    public func getStrainScore() -> StrainScore? {
        load(StrainScore.self, forKey: Keys.strainScore)
    }

    public func saveSleepScore(_ score: SleepScore) {
        save(score, forKey: Keys.sleepScore)
    }

    public func getSleepScore() -> SleepScore? {
        load(SleepScore.self, forKey: Keys.sleepScore)
    }

    // MARK: - Baseline

    public func saveBaseline(_ baseline: UserBaseline) {
        save(baseline, forKey: Keys.baseline)
    }

    public func getBaseline() -> UserBaseline? {
        load(UserBaseline.self, forKey: Keys.baseline)
    }

    // MARK: - Strain Guidance

    public func saveStrainGuidance(_ guidance: StrainGuidance) {
        save(guidance, forKey: Keys.strainGuidance)
    }

    public func getStrainGuidance() -> StrainGuidance? {
        load(StrainGuidance.self, forKey: Keys.strainGuidance)
    }

    // MARK: - Daily Insight

    public func saveDailyInsight(_ insight: DailyInsight) {
        save(insight, forKey: Keys.dailyInsight)
    }

    public func getDailyInsight() -> DailyInsight? {
        load(DailyInsight.self, forKey: Keys.dailyInsight)
    }

    // MARK: - Short Insight (for complications)

    public func saveShortInsight(_ insight: String) {
        defaults.set(insight, forKey: Keys.shortInsight)
    }

    public func getShortInsight() -> String? {
        defaults.string(forKey: Keys.shortInsight)
    }

    // MARK: - Score History (for trends)

    public func saveRecoveryHistory(_ scores: [RecoveryScore]) {
        save(scores, forKey: Keys.recoveryHistory)
    }

    public func getRecoveryHistory() -> [RecoveryScore] {
        load([RecoveryScore].self, forKey: Keys.recoveryHistory) ?? []
    }

    public func saveStrainHistory(_ scores: [StrainScore]) {
        save(scores, forKey: Keys.strainHistory)
    }

    public func getStrainHistory() -> [StrainScore] {
        load([StrainScore].self, forKey: Keys.strainHistory) ?? []
    }

    public func saveSleepHistory(_ scores: [SleepScore]) {
        save(scores, forKey: Keys.sleepHistory)
    }

    public func getSleepHistory() -> [SleepScore] {
        load([SleepScore].self, forKey: Keys.sleepHistory) ?? []
    }

    // MARK: - Sync Timestamps

    public func setLastPhoneSyncDate(_ date: Date) {
        defaults.set(date, forKey: Keys.lastPhoneSyncDate)
    }

    public func getLastPhoneSyncDate() -> Date? {
        defaults.object(forKey: Keys.lastPhoneSyncDate) as? Date
    }

    public func setLastDataSentDate(_ date: Date) {
        defaults.set(date, forKey: Keys.lastDataSentDate)
    }

    public func getLastDataSentDate() -> Date? {
        defaults.object(forKey: Keys.lastDataSentDate) as? Date
    }

    // MARK: - Local Calculation Flag

    public func setIsLocalCalculation(_ isLocal: Bool) {
        defaults.set(isLocal, forKey: Keys.isLocalCalculation)
    }

    public func getIsLocalCalculation() -> Bool {
        defaults.bool(forKey: Keys.isLocalCalculation)
    }

    // MARK: - Pending Data Queue (for offline sync)

    public func savePendingHeartRateSamples(_ samples: [HeartRateSample]) {
        save(samples, forKey: Keys.pendingHeartRateSamples)
    }

    public func getPendingHeartRateSamples() -> [HeartRateSample] {
        load([HeartRateSample].self, forKey: Keys.pendingHeartRateSamples) ?? []
    }

    public func appendPendingHeartRateSamples(_ samples: [HeartRateSample]) {
        var existing = getPendingHeartRateSamples()
        existing.append(contentsOf: samples)
        // Keep only last 24 hours worth to prevent unbounded growth
        let cutoff = Date().addingTimeInterval(-24 * 60 * 60)
        existing = existing.filter { $0.timestamp > cutoff }
        savePendingHeartRateSamples(existing)
    }

    public func clearPendingHeartRateSamples() {
        defaults.removeObject(forKey: Keys.pendingHeartRateSamples)
    }

    public func savePendingHRVSamples(_ samples: [HRVSample]) {
        save(samples, forKey: Keys.pendingHRVSamples)
    }

    public func getPendingHRVSamples() -> [HRVSample] {
        load([HRVSample].self, forKey: Keys.pendingHRVSamples) ?? []
    }

    public func appendPendingHRVSamples(_ samples: [HRVSample]) {
        var existing = getPendingHRVSamples()
        existing.append(contentsOf: samples)
        // Keep only last 24 hours worth
        let cutoff = Date().addingTimeInterval(-24 * 60 * 60)
        existing = existing.filter { $0.timestamp > cutoff }
        savePendingHRVSamples(existing)
    }

    public func clearPendingHRVSamples() {
        defaults.removeObject(forKey: Keys.pendingHRVSamples)
    }

    // MARK: - Clear All Data

    public func clearAll() {
        let keys = [
            Keys.recoveryScore,
            Keys.strainScore,
            Keys.sleepScore,
            Keys.baseline,
            Keys.strainGuidance,
            Keys.dailyInsight,
            Keys.recoveryHistory,
            Keys.strainHistory,
            Keys.sleepHistory,
            Keys.lastPhoneSyncDate,
            Keys.lastDataSentDate,
            Keys.pendingHeartRateSamples,
            Keys.pendingHRVSamples,
            Keys.shortInsight,
            Keys.isLocalCalculation
        ]

        keys.forEach { defaults.removeObject(forKey: $0) }
    }

    // MARK: - Private Helpers

    private func save<T: Encodable>(_ value: T, forKey key: String) {
        do {
            let data = try encoder.encode(value)
            defaults.set(data, forKey: key)
        } catch {
            print("WatchDataStore: Failed to encode \(key): \(error)")
        }
    }

    private func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        do {
            return try decoder.decode(type, from: data)
        } catch {
            print("WatchDataStore: Failed to decode \(key): \(error)")
            return nil
        }
    }
}
