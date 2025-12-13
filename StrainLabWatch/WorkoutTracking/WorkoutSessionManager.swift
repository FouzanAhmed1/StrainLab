import Foundation
import HealthKit
import CoreMotion
import StrainLabKit

@Observable
public final class WorkoutSessionManager: NSObject, @unchecked Sendable {
    private let healthStore = HKHealthStore()
    private let motionManager = CMMotionManager()

    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?

    public private(set) var currentHeartRate: Double = 0
    public private(set) var elapsedTime: TimeInterval = 0
    public private(set) var activeCalories: Double = 0
    public private(set) var isWorkoutActive = false

    private var heartRateSamples: [HeartRateSample] = []
    private var accelerometerReadings: [(timestamp: Date, magnitude: Double)] = []
    private var workoutStartDate: Date?
    private var timer: Timer?

    public override init() {
        super.init()
    }

    public func startWorkout(activityType: HKWorkoutActivityType) async throws {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activityType
        configuration.locationType = .unknown

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
        workoutSession?.startActivity(with: startDate)
        try await workoutBuilder?.beginCollection(at: startDate)

        startAccelerometerUpdates()
        startElapsedTimeTimer()

        DispatchQueue.main.async {
            self.isWorkoutActive = true
        }
    }

    public func pauseWorkout() {
        workoutSession?.pause()
        timer?.invalidate()
    }

    public func resumeWorkout() {
        workoutSession?.resume()
        startElapsedTimeTimer()
    }

    public func endWorkout() async throws -> WorkoutSession {
        let endDate = Date()
        workoutSession?.end()
        try await workoutBuilder?.endCollection(at: endDate)

        stopAccelerometerUpdates()
        timer?.invalidate()

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

        resetState()

        return session
    }

    private func resetState() {
        heartRateSamples = []
        accelerometerReadings = []
        currentHeartRate = 0
        elapsedTime = 0
        activeCalories = 0
        workoutStartDate = nil

        DispatchQueue.main.async {
            self.isWorkoutActive = false
        }
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
                    }

                case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                    if let value = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) {
                        self.activeCalories = value
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
        default: return "figure.mixed.cardio"
        }
    }
}
