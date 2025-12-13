import Foundation
import HealthKit
import StrainLabKit

@Observable
public final class WatchHealthKitManager: @unchecked Sendable {
    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKAnchoredObjectQuery?
    private var hrvQuery: HKAnchoredObjectQuery?

    public private(set) var pendingHeartRateSamples: [HeartRateSample] = []
    public private(set) var pendingHRVSamples: [HRVSample] = []
    public private(set) var isAuthorized = false

    private let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    private let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
    private let restingHRType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
    private let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
    private let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!

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
            HKWorkoutType.workoutType()
        ]

        let typesToShare: Set<HKSampleType> = [
            HKWorkoutType.workoutType()
        ]

        try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
        isAuthorized = true
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
