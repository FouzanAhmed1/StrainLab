import Foundation

/// User-configurable settings for the app
public struct UserSettings: Codable, Equatable {
    // Sleep Settings
    public var sleepNeedHours: Double = 7.5
    public var sleepGoalEnabled: Bool = true

    // Notification Settings
    public var notificationsEnabled: Bool = true
    public var morningNotificationHour: Int = 7
    public var morningNotificationMinute: Int = 0
    public var weeklyNotificationEnabled: Bool = true
    public var weeklyNotificationDay: Int = 1 // Monday

    // Training Settings
    public var trainingIntensity: TrainingIntensity = .moderate
    public var maxHeartRate: Int? // nil = use age-based formula
    public var age: Int?

    // Display Settings
    public var showDataQualityIndicators: Bool = true

    public init() {}
}

// MARK: - Training Intensity

public enum TrainingIntensity: String, Codable, CaseIterable {
    case light = "Light"
    case moderate = "Moderate"
    case intense = "Intense"

    public var description: String {
        switch self {
        case .light:
            return "Recovery focused, lower strain targets"
        case .moderate:
            return "Balanced training and recovery"
        case .intense:
            return "Performance focused, higher strain targets"
        }
    }

    public var strainMultiplier: Double {
        switch self {
        case .light: return 0.8
        case .moderate: return 1.0
        case .intense: return 1.2
        }
    }
}

// MARK: - Computed Properties

extension UserSettings {
    public var sleepNeedMinutes: Double {
        sleepNeedHours * 60
    }

    public var morningNotificationTime: DateComponents {
        var components = DateComponents()
        components.hour = morningNotificationHour
        components.minute = morningNotificationMinute
        return components
    }

    public var calculatedMaxHeartRate: Int {
        if let maxHR = maxHeartRate {
            return maxHR
        }
        if let age = age {
            return 220 - age
        }
        return 190 // Default fallback
    }
}
