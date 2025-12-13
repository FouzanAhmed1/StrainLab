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
    private let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!

    public init() {}

    public func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let typesToRead: Set<HKSampleType> = [
            heartRateType,
            hrvType,
            activeEnergyType,
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
