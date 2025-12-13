import Foundation

// MARK: - Strain Guidance

/// Recommended strain range and training status for the day
public struct StrainGuidance: Codable, Sendable, Equatable {
    public let recommendedRange: ClosedRange<Double>
    public let weeklyLoadStatus: WeeklyLoadStatus
    public let rationale: String

    public init(
        recommendedRange: ClosedRange<Double>,
        weeklyLoadStatus: WeeklyLoadStatus,
        rationale: String
    ) {
        self.recommendedRange = recommendedRange
        self.weeklyLoadStatus = weeklyLoadStatus
        self.rationale = rationale
    }

    /// Formatted range string (e.g., "14-18")
    public var formattedRange: String {
        "\(Int(recommendedRange.lowerBound))-\(Int(recommendedRange.upperBound))"
    }

    /// Midpoint of the recommended range
    public var targetMidpoint: Double {
        (recommendedRange.lowerBound + recommendedRange.upperBound) / 2
    }

    /// Calculates remaining strain to reach minimum target
    public func remainingToTarget(currentStrain: Double) -> Double {
        max(0, recommendedRange.lowerBound - currentStrain)
    }

    /// Calculates how much over the maximum target the current strain is
    public func overTarget(currentStrain: Double) -> Double {
        max(0, currentStrain - recommendedRange.upperBound)
    }

    /// Returns status relative to the target range
    public func targetStatus(currentStrain: Double) -> TargetStatus {
        if currentStrain < recommendedRange.lowerBound {
            return .belowTarget
        } else if currentStrain > recommendedRange.upperBound {
            return .aboveTarget
        } else {
            return .inRange
        }
    }
}

// MARK: - Target Status

public enum TargetStatus: String, Sendable {
    case belowTarget = "Below Target"
    case inRange = "In Range"
    case aboveTarget = "Above Target"

    public var description: String {
        switch self {
        case .belowTarget: return "Keep going!"
        case .inRange: return "On track"
        case .aboveTarget: return "Consider resting"
        }
    }
}

// MARK: - Weekly Load Status

public enum WeeklyLoadStatus: String, Codable, Sendable {
    case underLoaded = "Under-loaded"
    case optimal = "Optimal"
    case building = "Building"
    case peaking = "Peaking"
    case overReaching = "Over-reaching"
    case deloading = "Deloading"
    case unknown = "Analyzing"

    public var displayName: String { rawValue }

    public var shortDescription: String {
        switch self {
        case .underLoaded: return "Below target volume"
        case .optimal: return "Well balanced"
        case .building: return "Progressive overload"
        case .peaking: return "High volume"
        case .overReaching: return "Reduce intensity"
        case .deloading: return "Recovery phase"
        case .unknown: return "Collecting data"
        }
    }

    public var description: String {
        switch self {
        case .underLoaded:
            return "Training volume is below target"
        case .optimal:
            return "Training load is well balanced"
        case .building:
            return "Progressively increasing load"
        case .peaking:
            return "High training volume phase"
        case .overReaching:
            return "Consider reducing intensity"
        case .deloading:
            return "Recovery-focused phase"
        case .unknown:
            return "Building training history"
        }
    }
}

// MARK: - Training Intensity

/// User preference for training intensity
public enum TrainingIntensity: String, Codable, Sendable, CaseIterable {
    case light = "Light"
    case moderate = "Moderate"
    case intense = "Intense"

    public var displayName: String { rawValue }

    public var targetDailyStrain: Double {
        switch self {
        case .light: return 8
        case .moderate: return 11
        case .intense: return 14
        }
    }
}

// MARK: - Codable Extensions for ClosedRange

extension StrainGuidance {
    enum CodingKeys: String, CodingKey {
        case lowerBound, upperBound, weeklyLoadStatus, rationale
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let lowerBound = try container.decode(Double.self, forKey: .lowerBound)
        let upperBound = try container.decode(Double.self, forKey: .upperBound)
        self.recommendedRange = lowerBound...upperBound
        self.weeklyLoadStatus = try container.decode(WeeklyLoadStatus.self, forKey: .weeklyLoadStatus)
        self.rationale = try container.decode(String.self, forKey: .rationale)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(recommendedRange.lowerBound, forKey: .lowerBound)
        try container.encode(recommendedRange.upperBound, forKey: .upperBound)
        try container.encode(weeklyLoadStatus, forKey: .weeklyLoadStatus)
        try container.encode(rationale, forKey: .rationale)
    }
}
