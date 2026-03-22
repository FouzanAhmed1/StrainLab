import Foundation
import HealthKit
import StrainLabKit
import Combine

@Observable
public final class WatchHealthKitManager: @unchecked Sendable {
    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKAnchoredObjectQuery?
    private var hrvQuery: HKAnchoredObjectQuery?
    private var liveHeartRateQuery: HKAnchoredObjectQuery?
    private var streamingWorkoutQuery: HKQuery?

    public private(set) var pendingHeartRateSamples: [HeartRateSample] = []
    public private(set) var pendingHRVSamples: [HRVSample] = []
    public private(set) var isAuthorized = false

    // MARK: - Real-Time Heart Rate Monitoring
    public private(set) var currentHeartRate: Double = 0
    public private(set) var heartRateHistory: [HeartRateReading] = []
    public private(set) var isMonitoringHeartRate = false
    public private(set) var heartRateZone: HeartRateZone = .rest
    public private(set) var averageHeartRate: Double = 0
    public private(set) var maxHeartRate: Double = 0
    public private(set) var minHeartRate: Double = 999

    // MARK: - Live HRV Monitoring
    public private(set) var currentHRV: Double = 0
    public private(set) var hrvTrend: HRVTrend = .stable
    public private(set) var isMonitoringHRV = false

    // MARK: - Callbacks for real-time updates
    public var onHeartRateUpdate: ((Double, HeartRateZone) -> Void)?
    public var onHRVUpdate: ((Double, HRVTrend) -> Void)?

    private let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    private let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
    private let restingHRType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
    private let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
    private let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
    private let respiratoryRateType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!
    private let oxygenSatType = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!

    // User's max HR for zone calculation (can be personalized)
    public var userMaxHeartRate: Double = 190

    public init() {}

    public func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let typesToRead: Set<HKSampleType> = [
            heartRateType,
            hrvType,
            restingHRType,
            activeEnergyType,
            sleepType,
            respiratoryRateType,
            oxygenSatType,
            HKWorkoutType.workoutType()
        ]

        let typesToShare: Set<HKSampleType> = [
            HKWorkoutType.workoutType()
        ]

        try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
        isAuthorized = true

        // Set user's estimated max HR based on age if available
        await loadUserMaxHeartRate()
    }

    private func loadUserMaxHeartRate() async {
        // Try to get user's age for more accurate max HR calculation
        let dateOfBirthComponents = try? await healthStore.dateOfBirthComponents()
        if let birthYear = dateOfBirthComponents?.year {
            let currentYear = Calendar.current.component(.year, from: Date())
            let age = currentYear - birthYear
            // Standard formula: 220 - age (can be improved with more sophisticated formulas)
            userMaxHeartRate = Double(220 - age)
        }
    }

    public func startHeartRateObservation() {
        stopHeartRateObservation()

        let predicate = HKQuery.predicateForSamples(
            withStart: Date(),
            end: nil,
            options: .strictStartDate
        )

        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, error in
            guard error == nil else { return }
            self?.processHeartRateSamples(samples as? [HKQuantitySample] ?? [])
        }

        query.updateHandler = { [weak self] _, samples, _, _, error in
            guard error == nil else { return }
            self?.processHeartRateSamples(samples as? [HKQuantitySample] ?? [])
        }

        healthStore.execute(query)
        heartRateQuery = query
    }

    public func stopHeartRateObservation() {
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
        }
    }

    public func startHRVObservation() {
        stopHRVObservation()

        let predicate = HKQuery.predicateForSamples(
            withStart: Date().daysAgo(1),
            end: nil,
            options: .strictStartDate
        )

        let query = HKAnchoredObjectQuery(
            type: hrvType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, error in
            guard error == nil else { return }
            self?.processHRVSamples(samples as? [HKQuantitySample] ?? [])
        }

        query.updateHandler = { [weak self] _, samples, _, _, error in
            guard error == nil else { return }
            self?.processHRVSamples(samples as? [HKQuantitySample] ?? [])
        }

        healthStore.execute(query)
        hrvQuery = query
    }

    public func stopHRVObservation() {
        if let query = hrvQuery {
            healthStore.stop(query)
            hrvQuery = nil
        }
    }

    private func processHeartRateSamples(_ samples: [HKQuantitySample]) {
        let hrUnit = HKUnit.count().unitDivided(by: .minute())

        let newSamples = samples.map { sample in
            HeartRateSample(
                timestamp: sample.endDate,
                beatsPerMinute: sample.quantity.doubleValue(for: hrUnit),
                source: .watch
            )
        }

        DispatchQueue.main.async {
            self.pendingHeartRateSamples.append(contentsOf: newSamples)
        }
    }

    private func processHRVSamples(_ samples: [HKQuantitySample]) {
        let msUnit = HKUnit.secondUnit(with: .milli)

        let newSamples = samples.map { sample in
            HRVSample(
                timestamp: sample.endDate,
                sdnnMilliseconds: sample.quantity.doubleValue(for: msUnit),
                rrIntervalsMs: nil
            )
        }

        DispatchQueue.main.async {
            self.pendingHRVSamples.append(contentsOf: newSamples)
        }
    }

    public func clearPendingSamples() {
        pendingHeartRateSamples.removeAll()
        pendingHRVSamples.removeAll()
    }

    public func getAndClearHeartRateSamples() -> [HeartRateSample] {
        let samples = pendingHeartRateSamples
        pendingHeartRateSamples.removeAll()
        return samples
    }

    public func getAndClearHRVSamples() -> [HRVSample] {
        let samples = pendingHRVSamples
        pendingHRVSamples.removeAll()
        return samples
    }

    // MARK: - Overnight and Historical Queries

    /// Query overnight HRV samples (typically 10 PM to 7 AM window)
    /// Used for recovery score calculation
    public func queryOvernightHRV() async -> [HRVSample] {
        let calendar = Calendar.current
        let now = Date()

        // Define overnight window
        // If before 7 AM, use previous night's window
        // Otherwise, use last night (yesterday 10 PM to today 7 AM)
        let hour = calendar.component(.hour, from: now)

        let startDate: Date
        let endDate: Date

        if hour < 7 {
            // Early morning: use overnight starting yesterday at 10 PM
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
            startDate = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: yesterday)!
            endDate = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: now)!
        } else {
            // After 7 AM: use last night's data
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
            startDate = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: yesterday)!
            endDate = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: now)!
        }

        return await queryHRVSamples(from: startDate, to: endDate)
    }

    /// Query HRV samples within a specific date range
    public func queryHRVSamples(from startDate: Date, to endDate: Date) async -> [HRVSample] {
        await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(
                withStart: startDate,
                end: endDate,
                options: .strictStartDate
            )

            let sortDescriptor = NSSortDescriptor(
                key: HKSampleSortIdentifierStartDate,
                ascending: true
            )

            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard error == nil,
                      let quantitySamples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }

                let msUnit = HKUnit.secondUnit(with: .milli)
                let hrvSamples = quantitySamples.map { sample in
                    HRVSample(
                        timestamp: sample.endDate,
                        sdnnMilliseconds: sample.quantity.doubleValue(for: msUnit),
                        rrIntervalsMs: nil
                    )
                }

                continuation.resume(returning: hrvSamples)
            }

            healthStore.execute(query)
        }
    }

    /// Query resting heart rate for a specific date
    public func queryRestingHeartRate(for date: Date = Date()) async -> Double? {
        await withCheckedContinuation { continuation in
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let predicate = HKQuery.predicateForSamples(
                withStart: startOfDay,
                end: endOfDay,
                options: .strictStartDate
            )

            let sortDescriptor = NSSortDescriptor(
                key: HKSampleSortIdentifierStartDate,
                ascending: false
            )

            let query = HKSampleQuery(
                sampleType: restingHRType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard error == nil,
                      let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let hrUnit = HKUnit.count().unitDivided(by: .minute())
                let rhr = sample.quantity.doubleValue(for: hrUnit)
                continuation.resume(returning: rhr)
            }

            healthStore.execute(query)
        }
    }

    /// Query last night's sleep duration in minutes
    public func queryLastNightSleepDuration() async -> Double? {
        await withCheckedContinuation { continuation in
            let calendar = Calendar.current
            let now = Date()

            // Define sleep window (yesterday 6 PM to today noon)
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
            let startDate = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: yesterday)!
            let endDate = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now)!

            let predicate = HKQuery.predicateForSamples(
                withStart: startDate,
                end: endDate,
                options: .strictStartDate
            )

            let sortDescriptor = NSSortDescriptor(
                key: HKSampleSortIdentifierStartDate,
                ascending: true
            )

            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard error == nil,
                      let categorySamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }

                // Filter for actual sleep stages (not just in bed)
                let sleepStages: Set<HKCategoryValueSleepAnalysis> = [
                    .asleepCore,
                    .asleepDeep,
                    .asleepREM,
                    .asleepUnspecified
                ]

                var totalSleepSeconds: TimeInterval = 0

                for sample in categorySamples {
                    if let sleepValue = HKCategoryValueSleepAnalysis(rawValue: sample.value),
                       sleepStages.contains(sleepValue) {
                        totalSleepSeconds += sample.endDate.timeIntervalSince(sample.startDate)
                    }
                }

                let sleepMinutes = totalSleepSeconds / 60
                continuation.resume(returning: sleepMinutes > 0 ? sleepMinutes : nil)
            }

            healthStore.execute(query)
        }
    }

    /// Query recent heart rate samples (for background sync)
    public func queryRecentHeartRateSamples(hours: Int = 1) async -> [HeartRateSample] {
        let startDate = Date().addingTimeInterval(-Double(hours) * 60 * 60)

        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(
                withStart: startDate,
                end: Date(),
                options: .strictStartDate
            )

            let sortDescriptor = NSSortDescriptor(
                key: HKSampleSortIdentifierStartDate,
                ascending: true
            )

            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard error == nil,
                      let quantitySamples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }

                let hrUnit = HKUnit.count().unitDivided(by: .minute())
                let hrSamples = quantitySamples.map { sample in
                    HeartRateSample(
                        timestamp: sample.endDate,
                        beatsPerMinute: sample.quantity.doubleValue(for: hrUnit),
                        source: .watch
                    )
                }

                continuation.resume(returning: hrSamples)
            }

            healthStore.execute(query)
        }
    }

    /// Query recent HRV samples (for background sync)
    public func queryRecentHRVSamples(hours: Int = 1) async -> [HRVSample] {
        let startDate = Date().addingTimeInterval(-Double(hours) * 60 * 60)
        return await queryHRVSamples(from: startDate, to: Date())
    }

    /// Query heart rate samples for a specific date (for strain calculation)
    public func queryTodayHeartRateSamples() async -> [HeartRateSample] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(
                withStart: startOfDay,
                end: Date(),
                options: .strictStartDate
            )

            let sortDescriptor = NSSortDescriptor(
                key: HKSampleSortIdentifierStartDate,
                ascending: true
            )

            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard error == nil,
                      let quantitySamples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }

                let hrUnit = HKUnit.count().unitDivided(by: .minute())
                let hrSamples = quantitySamples.map { sample in
                    HeartRateSample(
                        timestamp: sample.endDate,
                        beatsPerMinute: sample.quantity.doubleValue(for: hrUnit),
                        source: .watch
                    )
                }

                continuation.resume(returning: hrSamples)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Continuous Real-Time Heart Rate Monitoring

    /// Start continuous heart rate monitoring with real-time updates
    /// This provides sub-second updates during active monitoring
    public func startContinuousHeartRateMonitoring() {
        guard !isMonitoringHeartRate else { return }

        isMonitoringHeartRate = true
        heartRateHistory.removeAll()
        maxHeartRate = 0
        minHeartRate = 999
        averageHeartRate = 0

        let predicate = HKQuery.predicateForSamples(
            withStart: Date(),
            end: nil,
            options: .strictStartDate
        )

        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, error in
            guard error == nil else { return }
            self?.processLiveHeartRateSamples(samples as? [HKQuantitySample] ?? [])
        }

        query.updateHandler = { [weak self] _, samples, _, _, error in
            guard error == nil else { return }
            self?.processLiveHeartRateSamples(samples as? [HKQuantitySample] ?? [])
        }

        healthStore.execute(query)
        liveHeartRateQuery = query

        print("Started continuous heart rate monitoring")
    }

    /// Stop continuous heart rate monitoring
    public func stopContinuousHeartRateMonitoring() {
        if let query = liveHeartRateQuery {
            healthStore.stop(query)
            liveHeartRateQuery = nil
        }
        isMonitoringHeartRate = false
        print("Stopped continuous heart rate monitoring")
    }

    private func processLiveHeartRateSamples(_ samples: [HKQuantitySample]) {
        let hrUnit = HKUnit.count().unitDivided(by: .minute())

        for sample in samples {
            let bpm = sample.quantity.doubleValue(for: hrUnit)
            let reading = HeartRateReading(
                timestamp: sample.endDate,
                bpm: bpm,
                zone: calculateHeartRateZone(bpm: bpm)
            )

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                self.currentHeartRate = bpm
                self.heartRateZone = reading.zone

                // Update statistics
                if bpm > self.maxHeartRate {
                    self.maxHeartRate = bpm
                }
                if bpm < self.minHeartRate && bpm > 30 {
                    self.minHeartRate = bpm
                }

                // Add to history (keep last 300 readings ~ 5 minutes at 1/sec)
                self.heartRateHistory.append(reading)
                if self.heartRateHistory.count > 300 {
                    self.heartRateHistory.removeFirst()
                }

                // Calculate rolling average
                let sum = self.heartRateHistory.reduce(0) { $0 + $1.bpm }
                self.averageHeartRate = sum / Double(self.heartRateHistory.count)

                // Notify callback
                self.onHeartRateUpdate?(bpm, reading.zone)

                // Also add to pending samples for sync
                self.pendingHeartRateSamples.append(HeartRateSample(
                    timestamp: sample.endDate,
                    beatsPerMinute: bpm,
                    source: .watch
                ))
            }
        }
    }

    /// Calculate heart rate zone based on percentage of max HR
    public func calculateHeartRateZone(bpm: Double) -> HeartRateZone {
        let percentage = (bpm / userMaxHeartRate) * 100

        switch percentage {
        case 0..<50:
            return .rest
        case 50..<60:
            return .zone1  // Very light
        case 60..<70:
            return .zone2  // Light
        case 70..<80:
            return .zone3  // Moderate
        case 80..<90:
            return .zone4  // Hard
        default:
            return .zone5  // Maximum
        }
    }

    // MARK: - Real-Time HRV Monitoring

    /// Start real-time HRV monitoring
    public func startContinuousHRVMonitoring() {
        guard !isMonitoringHRV else { return }

        isMonitoringHRV = true

        let predicate = HKQuery.predicateForSamples(
            withStart: Date().addingTimeInterval(-300), // Last 5 minutes
            end: nil,
            options: .strictStartDate
        )

        let query = HKAnchoredObjectQuery(
            type: hrvType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, error in
            guard error == nil else { return }
            self?.processLiveHRVSamples(samples as? [HKQuantitySample] ?? [])
        }

        query.updateHandler = { [weak self] _, samples, _, _, error in
            guard error == nil else { return }
            self?.processLiveHRVSamples(samples as? [HKQuantitySample] ?? [])
        }

        healthStore.execute(query)
        hrvQuery = query

        print("Started continuous HRV monitoring")
    }

    /// Stop real-time HRV monitoring
    public func stopContinuousHRVMonitoring() {
        stopHRVObservation()
        isMonitoringHRV = false
        print("Stopped continuous HRV monitoring")
    }

    private var recentHRVReadings: [Double] = []

    private func processLiveHRVSamples(_ samples: [HKQuantitySample]) {
        let msUnit = HKUnit.secondUnit(with: .milli)

        for sample in samples {
            let sdnn = sample.quantity.doubleValue(for: msUnit)

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                let previousHRV = self.currentHRV
                self.currentHRV = sdnn

                // Track recent readings for trend
                self.recentHRVReadings.append(sdnn)
                if self.recentHRVReadings.count > 10 {
                    self.recentHRVReadings.removeFirst()
                }

                // Calculate trend
                if self.recentHRVReadings.count >= 3 {
                    let recentAvg = self.recentHRVReadings.suffix(3).reduce(0, +) / 3
                    let olderAvg = self.recentHRVReadings.prefix(self.recentHRVReadings.count - 3).reduce(0, +) / Double(max(1, self.recentHRVReadings.count - 3))

                    let change = ((recentAvg - olderAvg) / olderAvg) * 100
                    if change > 5 {
                        self.hrvTrend = .improving
                    } else if change < -5 {
                        self.hrvTrend = .declining
                    } else {
                        self.hrvTrend = .stable
                    }
                }

                // Notify callback
                self.onHRVUpdate?(sdnn, self.hrvTrend)

                // Add to pending samples
                self.pendingHRVSamples.append(HRVSample(
                    timestamp: sample.endDate,
                    sdnnMilliseconds: sdnn,
                    rrIntervalsMs: nil
                ))
            }
        }
    }

    // MARK: - Workout Heart Rate Streaming

    /// Start streaming heart rate during a workout session
    public func startWorkoutHeartRateStreaming(workout: HKWorkout? = nil) {
        startContinuousHeartRateMonitoring()
    }

    /// Stop workout heart rate streaming
    public func stopWorkoutHeartRateStreaming() -> WorkoutHeartRateStats {
        stopContinuousHeartRateMonitoring()

        let stats = WorkoutHeartRateStats(
            averageHeartRate: averageHeartRate,
            maxHeartRate: maxHeartRate,
            minHeartRate: minHeartRate == 999 ? 0 : minHeartRate,
            heartRateHistory: heartRateHistory,
            zoneDistribution: calculateZoneDistribution()
        )

        // Clear history
        heartRateHistory.removeAll()

        return stats
    }

    private func calculateZoneDistribution() -> [HeartRateZone: TimeInterval] {
        var distribution: [HeartRateZone: TimeInterval] = [:]
        HeartRateZone.allCases.forEach { distribution[$0] = 0 }

        guard heartRateHistory.count > 1 else { return distribution }

        for i in 1..<heartRateHistory.count {
            let duration = heartRateHistory[i].timestamp.timeIntervalSince(heartRateHistory[i-1].timestamp)
            let zone = heartRateHistory[i-1].zone
            distribution[zone, default: 0] += duration
        }

        return distribution
    }

    // MARK: - Real-Time Recovery Status

    /// Get current recovery status based on real-time HRV
    public func getCurrentRecoveryStatus() -> RecoveryStatus {
        guard currentHRV > 0 else { return .unknown }

        // Simple classification based on HRV values
        // In production, this would use personalized baselines
        switch currentHRV {
        case 0..<30:
            return .poor
        case 30..<50:
            return .moderate
        case 50..<80:
            return .good
        default:
            return .excellent
        }
    }

    // MARK: - Live Stress Detection

    /// Detect stress level based on current HRV and heart rate
    public func detectStressLevel() -> StressLevel {
        guard currentHRV > 0 && currentHeartRate > 0 else { return .unknown }

        // Low HRV + elevated HR = high stress
        // High HRV + normal HR = low stress
        let hrvScore = min(100, currentHRV / 80 * 100)
        let hrScore = max(0, 100 - (currentHeartRate - 60) / 60 * 100)

        let combinedScore = (hrvScore + hrScore) / 2

        switch combinedScore {
        case 0..<25:
            return .high
        case 25..<50:
            return .moderate
        case 50..<75:
            return .low
        default:
            return .minimal
        }
    }
}

// MARK: - Supporting Types

public struct HeartRateReading: Identifiable, Sendable {
    public let id = UUID()
    public let timestamp: Date
    public let bpm: Double
    public let zone: HeartRateZone
}

public enum HeartRateZone: String, CaseIterable, Sendable {
    case rest = "Rest"
    case zone1 = "Zone 1"
    case zone2 = "Zone 2"
    case zone3 = "Zone 3"
    case zone4 = "Zone 4"
    case zone5 = "Zone 5"

    public var displayName: String { rawValue }

    public var color: String {
        switch self {
        case .rest: return "gray"
        case .zone1: return "blue"
        case .zone2: return "green"
        case .zone3: return "yellow"
        case .zone4: return "orange"
        case .zone5: return "red"
        }
    }

    public var description: String {
        switch self {
        case .rest: return "Resting"
        case .zone1: return "Very Light"
        case .zone2: return "Light"
        case .zone3: return "Moderate"
        case .zone4: return "Hard"
        case .zone5: return "Maximum"
        }
    }

    public var percentageRange: ClosedRange<Int> {
        switch self {
        case .rest: return 0...49
        case .zone1: return 50...59
        case .zone2: return 60...69
        case .zone3: return 70...79
        case .zone4: return 80...89
        case .zone5: return 90...100
        }
    }
}

public enum HRVTrend: String, Sendable {
    case improving = "Improving"
    case stable = "Stable"
    case declining = "Declining"

    public var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }
}

public enum RecoveryStatus: String, Sendable {
    case excellent = "Excellent"
    case good = "Good"
    case moderate = "Moderate"
    case poor = "Poor"
    case unknown = "Unknown"
}

public enum StressLevel: String, Sendable {
    case minimal = "Minimal"
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case unknown = "Unknown"
}

public struct WorkoutHeartRateStats: Sendable {
    public let averageHeartRate: Double
    public let maxHeartRate: Double
    public let minHeartRate: Double
    public let heartRateHistory: [HeartRateReading]
    public let zoneDistribution: [HeartRateZone: TimeInterval]

    public var totalDuration: TimeInterval {
        guard let first = heartRateHistory.first,
              let last = heartRateHistory.last else { return 0 }
        return last.timestamp.timeIntervalSince(first.timestamp)
    }

    public func zonePercentage(_ zone: HeartRateZone) -> Double {
        guard totalDuration > 0 else { return 0 }
        return (zoneDistribution[zone] ?? 0) / totalDuration * 100
    }
}

public enum HealthKitError: Error, LocalizedError {
    case notAvailable
    case authorizationDenied
    case dataNotAvailable

    public var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .authorizationDenied:
            return "HealthKit authorization was denied"
        case .dataNotAvailable:
            return "Requested health data is not available"
        }
    }
}
