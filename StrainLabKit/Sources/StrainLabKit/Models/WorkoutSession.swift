import Foundation

public struct WorkoutSession: Codable, Identifiable, Sendable, Hashable {
    public let id: UUID
    public let activityType: String
    public let startDate: Date
    public let endDate: Date
    public let heartRateSamples: [HeartRateSample]
    public let activeEnergyBurned: Double?
    public let accelerometerSummary: AccelerometerSummary?

    public struct AccelerometerSummary: Codable, Sendable, Hashable {
        public let averageMagnitude: Double
        public let peakMagnitude: Double
        public let movementMinutes: Double

        public init(averageMagnitude: Double, peakMagnitude: Double, movementMinutes: Double) {
            self.averageMagnitude = averageMagnitude
            self.peakMagnitude = peakMagnitude
            self.movementMinutes = movementMinutes
        }
    }

    public init(
        id: UUID = UUID(),
        activityType: String,
        startDate: Date,
        endDate: Date,
        heartRateSamples: [HeartRateSample],
        activeEnergyBurned: Double? = nil,
        accelerometerSummary: AccelerometerSummary? = nil
    ) {
        self.id = id
        self.activityType = activityType
        self.startDate = startDate
        self.endDate = endDate
        self.heartRateSamples = heartRateSamples
        self.activeEnergyBurned = activeEnergyBurned
        self.accelerometerSummary = accelerometerSummary
    }

    public var durationMinutes: Double {
        endDate.timeIntervalSince(startDate) / 60.0
    }

    public var averageHeartRate: Double {
        guard !heartRateSamples.isEmpty else { return 0 }
        return heartRateSamples.reduce(0.0) { $0 + $1.beatsPerMinute } / Double(heartRateSamples.count)
    }

    public var maxHeartRate: Double {
        heartRateSamples.map { $0.beatsPerMinute }.max() ?? 0
    }
}

public enum WorkoutActivityType: String, Codable, Sendable, CaseIterable {
    case running = "Running"
    case cycling = "Cycling"
    case swimming = "Swimming"
    case walking = "Walking"
    case hiking = "Hiking"
    case strength = "Strength Training"
    case yoga = "Yoga"
    case hiit = "HIIT"
    case crossTraining = "Cross Training"
    case other = "Other"

    public var systemImageName: String {
        switch self {
        case .running: return "figure.run"
        case .cycling: return "figure.outdoor.cycle"
        case .swimming: return "figure.pool.swim"
        case .walking: return "figure.walk"
        case .hiking: return "figure.hiking"
        case .strength: return "dumbbell.fill"
        case .yoga: return "figure.yoga"
        case .hiit: return "flame.fill"
        case .crossTraining: return "figure.cross.training"
        case .other: return "figure.mixed.cardio"
        }
    }
}
