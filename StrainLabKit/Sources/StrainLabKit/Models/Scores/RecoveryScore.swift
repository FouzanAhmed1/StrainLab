import Foundation

public struct RecoveryScore: Codable, Identifiable, Sendable, Hashable {
    public let id: UUID
    public let date: Date
    public let score: Double
    public let category: Category
    public let components: Components

    public enum Category: String, Codable, Sendable {
        case poor
        case moderate
        case optimal

        public var displayName: String {
            rawValue.capitalized
        }

        public static func from(score: Double) -> Category {
            if score >= 67 {
                return .optimal
            } else if score >= 34 {
                return .moderate
            } else {
                return .poor
            }
        }
    }

    public struct Components: Codable, Sendable, Hashable {
        public let hrvDeviation: Double
        public let rhrDeviation: Double
        public let sleepQuality: Double
        public let hrvBaseline: Double
        public let rhrBaseline: Double
        public let currentHRV: Double
        public let currentRHR: Double

        public init(
            hrvDeviation: Double,
            rhrDeviation: Double,
            sleepQuality: Double,
            hrvBaseline: Double,
            rhrBaseline: Double,
            currentHRV: Double,
            currentRHR: Double
        ) {
            self.hrvDeviation = hrvDeviation
            self.rhrDeviation = rhrDeviation
            self.sleepQuality = sleepQuality
            self.hrvBaseline = hrvBaseline
            self.rhrBaseline = rhrBaseline
            self.currentHRV = currentHRV
            self.currentRHR = currentRHR
        }
    }

    public init(
        id: UUID = UUID(),
        date: Date,
        score: Double,
        category: Category,
        components: Components
    ) {
        self.id = id
        self.date = date
        self.score = score
        self.category = category
        self.components = components
    }

    public var formattedScore: String {
        "\(Int(score))%"
    }

    public var explanation: String {
        var parts: [String] = []

        if components.hrvDeviation > 5 {
            parts.append("Your HRV is above your baseline, indicating good recovery.")
        } else if components.hrvDeviation < -5 {
            parts.append("Your HRV is below your baseline, suggesting your body needs more recovery.")
        } else {
            parts.append("Your HRV is close to your baseline.")
        }

        if components.rhrDeviation < -3 {
            parts.append("Your resting heart rate is lower than usual, a positive recovery sign.")
        } else if components.rhrDeviation > 3 {
            parts.append("Your resting heart rate is elevated, which may indicate incomplete recovery.")
        }

        if components.sleepQuality >= 80 {
            parts.append("Your sleep quality was excellent last night.")
        } else if components.sleepQuality >= 60 {
            parts.append("Your sleep quality was moderate last night.")
        } else {
            parts.append("Your sleep quality was below optimal last night.")
        }

        return parts.joined(separator: " ")
    }
}
