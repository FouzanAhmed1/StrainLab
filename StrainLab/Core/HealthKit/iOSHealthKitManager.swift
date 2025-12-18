import Foundation
import HealthKit
import StrainLabKit

public enum HealthKitError: Error {
    case notAvailable
    case authorizationDenied
    case queryFailed(Error)
}

public actor iOSHealthKitManager: HealthDataProvider {
    private let healthStore = HKHealthStore()

    private let readTypes: Set<HKSampleType> = [
        HKQuantityType.quantityType(forIdentifier: .heartRate)!,
        HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!,
        HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!,
        HKWorkoutType.workoutType()
    ]

    public init() {}

    public func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
    }

    public func fetchHeartRateSamples(from startDate: Date, to endDate: Date) async throws -> [HeartRateSample] {
        let type = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        let samples = try await querySamples(type: type, predicate: predicate)

        let unit = HKUnit.count().unitDivided(by: .minute())
        return samples.map { sample in
            HeartRateSample(
                timestamp: sample.endDate,
                beatsPerMinute: sample.quantity.doubleValue(for: unit),
                source: .watch
            )
        }
    }

    public func fetchHRVSamples(from startDate: Date, to endDate: Date) async throws -> [HRVSample] {
        let type = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        let samples = try await querySamples(type: type, predicate: predicate)

        let msUnit = HKUnit.secondUnit(with: .milli)
        return samples.map { sample in
            HRVSample(
                timestamp: sample.endDate,
                sdnnMilliseconds: sample.quantity.doubleValue(for: msUnit),
                rrIntervalsMs: nil
            )
        }
    }

    public func fetchSleepSessions(from startDate: Date, to endDate: Date) async throws -> [SleepSession] {
        let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        let samples = try await queryCategorySamples(type: type, predicate: predicate)
        return groupSleepSamplesIntoSessions(samples)
    }

    public func fetchWorkouts(from startDate: Date, to endDate: Date) async throws -> [WorkoutSession] {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        let workouts = try await queryWorkouts(predicate: predicate)

        var sessions: [WorkoutSession] = []
        for workout in workouts {
            let heartRates = try await fetchHeartRateSamples(from: workout.startDate, to: workout.endDate)
            sessions.append(WorkoutSession(
                activityType: workout.workoutActivityType.commonName,
                startDate: workout.startDate,
                endDate: workout.endDate,
                heartRateSamples: heartRates,
                activeEnergyBurned: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()),
                accelerometerSummary: nil
            ))
        }

        return sessions
    }

    public func fetchRestingHeartRate(for date: Date) async throws -> Double? {
        let type = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        let samples = try await querySamples(type: type, predicate: predicate, limit: 1)
        return samples.first?.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
    }

    private func querySamples(
        type: HKQuantityType,
        predicate: NSPredicate,
        limit: Int = HKObjectQueryNoLimit
    ) async throws -> [HKQuantitySample] {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: limit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
                }
            }
            healthStore.execute(query)
        }
    }

    private func queryCategorySamples(
        type: HKCategoryType,
        predicate: NSPredicate
    ) async throws -> [HKCategorySample] {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples as? [HKCategorySample] ?? [])
                }
            }
            healthStore.execute(query)
        }
    }

    private func queryWorkouts(predicate: NSPredicate) async throws -> [HKWorkout] {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKWorkoutType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples as? [HKWorkout] ?? [])
                }
            }
            healthStore.execute(query)
        }
    }

    private func groupSleepSamplesIntoSessions(_ samples: [HKCategorySample]) -> [SleepSession] {
        guard !samples.isEmpty else { return [] }

        var sessions: [SleepSession] = []
        var currentSessionSamples: [HKCategorySample] = [samples[0]]

        for sample in samples.dropFirst() {
            let lastEnd = currentSessionSamples.last!.endDate
            if sample.startDate.timeIntervalSince(lastEnd) < 2 * 60 * 60 {
                currentSessionSamples.append(sample)
            } else {
                if let session = buildSleepSession(from: currentSessionSamples) {
                    sessions.append(session)
                }
                currentSessionSamples = [sample]
            }
        }

        if !currentSessionSamples.isEmpty {
            if let session = buildSleepSession(from: currentSessionSamples) {
                sessions.append(session)
            }
        }

        return sessions
    }

    private func buildSleepSession(from samples: [HKCategorySample]) -> SleepSession? {
        guard let firstSample = samples.first, let lastSample = samples.last else { return nil }

        let stages = samples.compactMap { sample -> SleepSession.SleepStage? in
            guard let value = HKCategoryValueSleepAnalysis(rawValue: sample.value) else { return nil }

            let stageType: SleepSession.SleepStage.StageType
            switch value {
            case .awake:
                stageType = .awake
            case .asleepREM:
                stageType = .rem
            case .asleepCore:
                stageType = .core
            case .asleepDeep:
                stageType = .deep
            case .inBed:
                stageType = .inBed
            default:
                stageType = .asleepUnspecified
            }

            return SleepSession.SleepStage(
                type: stageType,
                startDate: sample.startDate,
                endDate: sample.endDate
            )
        }

        return SleepSession(
            startDate: firstSample.startDate,
            endDate: lastSample.endDate,
            stages: stages
        )
    }
}

private extension HKWorkoutActivityType {
    var commonName: String {
        switch self {
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .walking: return "Walking"
        case .hiking: return "Hiking"
        case .traditionalStrengthTraining: return "Strength Training"
        case .yoga: return "Yoga"
        case .highIntensityIntervalTraining: return "HIIT"
        case .crossTraining: return "Cross Training"
        default: return "Workout"
        }
    }
}
