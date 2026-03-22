import Foundation
import HealthKit
import CoreMotion
import StrainLabKit
import WidgetKit

public final class WorkoutSessionManager: NSObject, ObservableObject, @unchecked Sendable {
    private let healthStore = HKHealthStore()
    private let motionManager = CMMotionManager()

    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?

    // MARK: - Published Properties
    @Published public private(set) var currentHeartRate: Double = 0
    @Published public private(set) var elapsedTime: TimeInterval = 0
    @Published public private(set) var activeCalories: Double = 0
    @Published public private(set) var isWorkoutActive = false
    @Published public private(set) var isPaused = false

    // MARK: - Real-Time Strain Calculation
    @Published public private(set) var liveStrain: Double = 0
    @Published public private(set) var currentZone: HeartRateZone = .rest
    @Published public private(set) var zoneTimeDistribution: [HeartRateZone: TimeInterval] = [:]
    @Published public private(set) var averageHeartRate: Double = 0
    @Published public private(set) var maxHeartRate: Double = 0
    @Published public private(set) var minHeartRate: Double = 999

    // MARK: - Heart Rate History for Live Chart
    @Published public private(set) var heartRateHistory: [LiveHeartRatePoint] = []

    // MARK: - Workout Stats
    @Published public private(set) var distance: Double = 0 // meters
    @Published public private(set) var pace: Double = 0 // min/km
    @Published public private(set) var cadence: Double = 0 // steps/min

    private var heartRateSamples: [HeartRateSample] = []
    private var accelerometerReadings: [(timestamp: Date, magnitude: Double)] = []
    private var workoutStartDate: Date?
    private var timer: Timer?
    private var strainCalculationTimer: Timer?

    // User's max HR for zone calculations
    public var userMaxHeartRate: Double = 190

    // Live strain calculation state
    private var lastZoneUpdateTime: Date?
    private var rawStrainAccumulator: Double = 0

    // Zone weights for strain calculation (exponential)
    private let zoneWeights: [HeartRateZone: Double] = [
        .rest: 0.0,
        .zone1: 0.5,
        .zone2: 1.0,
        .zone3: 2.0,
        .zone4: 4.0,
        .zone5: 8.0
    ]

    public override init() {
        super.init()
        initializeZoneDistribution()
    }

    private func initializeZoneDistribution() {
        for zone in HeartRateZone.allCases {
            zoneTimeDistribution[zone] = 0
        }
    }

    public func startWorkout(activityType: HKWorkoutActivityType) async throws {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activityType
        configuration.locationType = activityType.defaultLocationType

        workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
        workoutBuilder = workoutSession?.associatedWorkoutBuilder()

        workoutSession?.delegate = self
        workoutBuilder?.delegate = self

        workoutBuilder?.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore,
            workoutConfiguration: configuration
        )

        let startDate = Date()
        workoutStartDate = startDate
        lastZoneUpdateTime = startDate
        workoutSession?.startActivity(with: startDate)
        try await workoutBuilder?.beginCollection(at: startDate)

        startAccelerometerUpdates()
        startElapsedTimeTimer()
        startStrainCalculationTimer()
        initializeZoneDistribution()

        // Reset stats
        rawStrainAccumulator = 0
        liveStrain = 0
        heartRateHistory.removeAll()
        maxHeartRate = 0
        minHeartRate = 999
        averageHeartRate = 0

        DispatchQueue.main.async {
            self.isWorkoutActive = true
            self.isPaused = false
        }
    }

    public func pauseWorkout() {
        workoutSession?.pause()
        timer?.invalidate()
        strainCalculationTimer?.invalidate()
        DispatchQueue.main.async {
            self.isPaused = true
        }
    }

    public func resumeWorkout() {
        workoutSession?.resume()
        lastZoneUpdateTime = Date()
        startElapsedTimeTimer()
        startStrainCalculationTimer()
        DispatchQueue.main.async {
            self.isPaused = false
        }
    }

    public func endWorkout() async throws -> WorkoutSession {
        let endDate = Date()
        workoutSession?.end()
        try await workoutBuilder?.endCollection(at: endDate)

        stopAccelerometerUpdates()
        timer?.invalidate()
        strainCalculationTimer?.invalidate()

        let activityTypeName = workoutSession?.workoutConfiguration.activityType.name ?? "Unknown"

        let session = WorkoutSession(
            activityType: activityTypeName,
            startDate: workoutStartDate ?? endDate,
            endDate: endDate,
            heartRateSamples: heartRateSamples,
            activeEnergyBurned: activeCalories,
            accelerometerSummary: buildAccelerometerSummary()
        )

        if let _ = try? await workoutBuilder?.finishWorkout() {
            // Workout saved to HealthKit
        }

        // Save final workout data to shared store for complications
        saveWorkoutDataToSharedStore()

        // Reload complications with new data
        WidgetCenter.shared.reloadAllTimelines()

        resetState()

        return session
    }

    private func saveWorkoutDataToSharedStore() {
        let defaults = UserDefaults(suiteName: "group.com.strainlab.shared")
        defaults?.set(liveStrain, forKey: "watch.workout.lastStrain")
        defaults?.set(elapsedTime, forKey: "watch.workout.lastDuration")
        defaults?.set(activeCalories, forKey: "watch.workout.lastCalories")
        defaults?.set(averageHeartRate, forKey: "watch.workout.lastAvgHR")
        defaults?.set(maxHeartRate, forKey: "watch.workout.lastMaxHR")
        defaults?.set(Date(), forKey: "watch.workout.lastDate")
    }

    private func resetState() {
        heartRateSamples = []
        accelerometerReadings = []
        heartRateHistory = []
        currentHeartRate = 0
        elapsedTime = 0
        activeCalories = 0
        workoutStartDate = nil
        liveStrain = 0
        rawStrainAccumulator = 0
        maxHeartRate = 0
        minHeartRate = 999
        averageHeartRate = 0
        distance = 0
        pace = 0
        cadence = 0
        initializeZoneDistribution()

        DispatchQueue.main.async {
            self.isWorkoutActive = false
            self.isPaused = false
        }
    }

    // MARK: - Real-Time Strain Calculation

    private func startStrainCalculationTimer() {
        strainCalculationTimer?.invalidate()
        strainCalculationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateLiveStrain()
        }
    }

    private func updateLiveStrain() {
        guard !isPaused, currentHeartRate > 0 else { return }

        let now = Date()
        let timeSinceLastUpdate = lastZoneUpdateTime.map { now.timeIntervalSince($0) } ?? 1.0
        lastZoneUpdateTime = now

        // Calculate current zone
        let zone = calculateZone(forHeartRate: currentHeartRate)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.currentZone = zone

            // Update zone time distribution
            self.zoneTimeDistribution[zone, default: 0] += timeSinceLastUpdate

            // Calculate zone minutes contribution
            let zoneWeight = self.zoneWeights[zone] ?? 0
            let zoneMinutesContribution = (timeSinceLastUpdate / 60.0) * zoneWeight

            self.rawStrainAccumulator += zoneMinutesContribution

            // Convert to 0-21 scale using logarithmic formula
            // Formula: 21 * (1 - e^(-rawStrain/200))
            self.liveStrain = 21 * (1 - exp(-self.rawStrainAccumulator / 200))

            // Update complications periodically (every 30 seconds)
            if Int(self.elapsedTime) % 30 == 0 {
                self.updateLiveComplication()
            }
        }
    }

    private func calculateZone(forHeartRate hr: Double) -> HeartRateZone {
        let percentage = (hr / userMaxHeartRate) * 100

        switch percentage {
        case 0..<50:
            return .rest
        case 50..<60:
            return .zone1
        case 60..<70:
            return .zone2
        case 70..<80:
            return .zone3
        case 80..<90:
            return .zone4
        default:
            return .zone5
        }
    }

    private func updateLiveComplication() {
        let defaults = UserDefaults(suiteName: "group.com.strainlab.shared")
        defaults?.set(liveStrain, forKey: "watch.score.strain.value")
        WidgetCenter.shared.reloadTimelines(ofKind: "StrainWatchComplication")
    }

    // MARK: - Heart Rate Statistics

    private func updateHeartRateStatistics(newHR: Double) {
        // Update max/min
        if newHR > maxHeartRate {
            maxHeartRate = newHR
        }
        if newHR < minHeartRate && newHR > 30 {
            minHeartRate = newHR
        }

        // Add to history for live chart
        let point = LiveHeartRatePoint(
            timestamp: Date(),
            bpm: newHR,
            zone: calculateZone(forHeartRate: newHR)
        )
        heartRateHistory.append(point)

        // Keep only last 5 minutes of data (300 points at 1/sec)
        if heartRateHistory.count > 300 {
            heartRateHistory.removeFirst()
        }

        // Calculate rolling average
        let sum = heartRateHistory.reduce(0.0) { $0 + $1.bpm }
        averageHeartRate = sum / Double(heartRateHistory.count)
    }

    // MARK: - Formatted Properties

    public var formattedStrain: String {
        String(format: "%.1f", liveStrain)
    }

    public var formattedAverageHR: String {
        "\(Int(averageHeartRate))"
    }

    public var formattedMaxHR: String {
        "\(Int(maxHeartRate))"
    }

    public var zonePercentages: [HeartRateZone: Double] {
        let total = zoneTimeDistribution.values.reduce(0, +)
        guard total > 0 else { return [:] }

        var percentages: [HeartRateZone: Double] = [:]
        for (zone, time) in zoneTimeDistribution {
            percentages[zone] = (time / total) * 100
        }
        return percentages
    }

    private func startElapsedTimeTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startDate = self.workoutStartDate else { return }
            DispatchQueue.main.async {
                self.elapsedTime = Date().timeIntervalSince(startDate)
            }
        }
    }

    private func startAccelerometerUpdates() {
        guard motionManager.isAccelerometerAvailable else { return }

        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let data = data, error == nil else { return }

            let magnitude = sqrt(
                pow(data.acceleration.x, 2) +
                pow(data.acceleration.y, 2) +
                pow(data.acceleration.z, 2)
            )

            self?.accelerometerReadings.append((Date(), magnitude))
        }
    }

    private func stopAccelerometerUpdates() {
        motionManager.stopAccelerometerUpdates()
    }

    private func buildAccelerometerSummary() -> WorkoutSession.AccelerometerSummary {
        let magnitudes = accelerometerReadings.map { $0.magnitude }

        guard !magnitudes.isEmpty else {
            return WorkoutSession.AccelerometerSummary(
                averageMagnitude: 0,
                peakMagnitude: 0,
                movementMinutes: 0
            )
        }

        let average = magnitudes.reduce(0, +) / Double(magnitudes.count)
        let peak = magnitudes.max() ?? 0

        let movementReadings = magnitudes.filter { $0 > 1.1 }
        let movementMinutes = Double(movementReadings.count) / 10.0 / 60.0

        return WorkoutSession.AccelerometerSummary(
            averageMagnitude: average,
            peakMagnitude: peak,
            movementMinutes: movementMinutes
        )
    }

    public var formattedElapsedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

extension WorkoutSessionManager: HKWorkoutSessionDelegate {
    public func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        DispatchQueue.main.async {
            switch toState {
            case .running:
                self.isWorkoutActive = true
            case .paused:
                self.isWorkoutActive = true
            case .ended:
                self.isWorkoutActive = false
            default:
                break
            }
        }
    }

    public func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error.localizedDescription)")
    }
}

extension WorkoutSessionManager: HKLiveWorkoutBuilderDelegate {
    public func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }

            let statistics = workoutBuilder.statistics(for: quantityType)

            DispatchQueue.main.async {
                switch quantityType {
                case HKQuantityType.quantityType(forIdentifier: .heartRate):
                    if let value = statistics?.mostRecentQuantity()?.doubleValue(
                        for: .count().unitDivided(by: .minute())
                    ) {
                        self.currentHeartRate = value
                        self.heartRateSamples.append(HeartRateSample(
                            timestamp: Date(),
                            beatsPerMinute: value,
                            source: .watch
                        ))
                        self.updateHeartRateStatistics(newHR: value)
                    }

                case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                    if let value = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) {
                        self.activeCalories = value
                    }

                case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning),
                     HKQuantityType.quantityType(forIdentifier: .distanceCycling):
                    if let value = statistics?.sumQuantity()?.doubleValue(for: .meter()) {
                        self.distance = value
                        // Calculate pace (min/km)
                        if self.elapsedTime > 0 && value > 0 {
                            self.pace = (self.elapsedTime / 60) / (value / 1000)
                        }
                    }

                case HKQuantityType.quantityType(forIdentifier: .runningStrideLength):
                    if let strideLength = statistics?.mostRecentQuantity()?.doubleValue(for: .meter()),
                       strideLength > 0 {
                        // Estimate cadence from stride length and distance
                        // This is a rough estimate
                        if self.elapsedTime > 0 && self.distance > 0 {
                            let stepsEstimate = self.distance / strideLength
                            self.cadence = (stepsEstimate / self.elapsedTime) * 60
                        }
                    }

                default:
                    break
                }
            }
        }
    }

    public func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Handle workout events if needed
    }
}

// MARK: - Supporting Types

public struct LiveHeartRatePoint: Identifiable, Sendable {
    public let id = UUID()
    public let timestamp: Date
    public let bpm: Double
    public let zone: HeartRateZone
}

extension HKWorkoutActivityType {
    var name: String {
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
        case .rowing: return "Rowing"
        case .elliptical: return "Elliptical"
        case .stairClimbing: return "Stair Climbing"
        case .functionalStrengthTraining: return "Functional Training"
        case .coreTraining: return "Core Training"
        case .dance: return "Dance"
        case .martialArts: return "Martial Arts"
        case .pilates: return "Pilates"
        case .tennis: return "Tennis"
        case .basketball: return "Basketball"
        case .soccer: return "Soccer"
        default: return "Workout"
        }
    }

    var systemImageName: String {
        switch self {
        case .running: return "figure.run"
        case .cycling: return "figure.outdoor.cycle"
        case .swimming: return "figure.pool.swim"
        case .walking: return "figure.walk"
        case .hiking: return "figure.hiking"
        case .traditionalStrengthTraining: return "dumbbell.fill"
        case .yoga: return "figure.yoga"
        case .highIntensityIntervalTraining: return "flame.fill"
        case .crossTraining: return "figure.cross.training"
        case .rowing: return "figure.rower"
        case .elliptical: return "figure.elliptical"
        case .stairClimbing: return "figure.stair.stepper"
        case .functionalStrengthTraining: return "figure.strengthtraining.functional"
        case .coreTraining: return "figure.core.training"
        case .dance: return "figure.dance"
        case .martialArts: return "figure.martial.arts"
        case .pilates: return "figure.pilates"
        case .tennis: return "figure.tennis"
        case .basketball: return "figure.basketball"
        case .soccer: return "figure.soccer"
        default: return "figure.mixed.cardio"
        }
    }

    var defaultLocationType: HKWorkoutSessionLocationType {
        switch self {
        case .running, .cycling, .walking, .hiking:
            return .outdoor
        case .swimming:
            return .unknown
        default:
            return .indoor
        }
    }
}
