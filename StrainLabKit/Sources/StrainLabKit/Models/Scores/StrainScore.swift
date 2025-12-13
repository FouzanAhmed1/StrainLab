import Foundation

public struct StrainScore: Codable, Identifiable, Sendable, Hashable {
    public let id: UUID
    public let date: Date
    public let score: Double
    public let category: Category
    public let components: Components

    public enum Category: String, Codable, Sendable {
        case light
        case moderate
        case high
        case allOut

        public var displayName: String {
            switch self {
            case .light: return "Light"
            case .moderate: return "Moderate"
            case .high: return "High"
            case .allOut: return "All Out"
            }
        }

        public static func from(score: Double) -> Category {
            if score >= 18 {
                return .allOut
            } else if score >= 14 {
                return .high
            } else if score >= 10 {
                return .moderate
            } else {
                return .light
            }
        }
    }

    public struct Components: Codable, Sendable, Hashable {
        public let activityMinutes: Double
        public let zoneMinutes: ZoneMinutes
        public let workoutContributions: [WorkoutContribution]

        public struct ZoneMinutes: Codable, Sendable, Hashable {
            public let zone1: Double
            public let zone2: Double
            public let zone3: Double
            public let zone4: Double
            public let zone5: Double

            public init(zone1: Double, zone2: Double, zone3: Double, zone4: Double, zone5: Double) {
                self.zone1 = zone1
                self.zone2 = zone2
                self.zone3 = zone3
                self.zone4 = zone4
                self.zone5 = zone5
            }

            public var totalMinutes: Double {
                zone1 + zone2 + zone3 + zone4 + zone5
            }
        }

        public struct WorkoutContribution: Codable, Sendable, Hashable, Identifiable {
            public let id: UUID
            public let workoutId: UUID
            public let activityType: String
            public let strainContribution: Double

            public init(workoutId: UUID, activityType: String, strainContribution: Double) {
                self.id = UUID()
                self.workoutId = workoutId
                self.activityType = activityType
                self.strainContribution = strainContribution
            }
        }

        public init(activityMinutes: Double, zoneMinutes: ZoneMinutes, workoutContributions: [WorkoutContribution]) {
            self.activityMinutes = activityMinutes
            self.zoneMinutes = zoneMinutes
            self.workoutContributions = workoutContributions
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
        String(format: "%.1f", score)
    }

    public var explanation: String {
        var parts: [String] = []

        parts.append("Today's strain is \(formattedScore) out of 21.")

        switch category {
        case .light:
            parts.append("This is a light day, ideal for recovery.")
        case .moderate:
            parts.append("This is moderate activity, good for building fitness.")
        case .high:
            parts.append("This is high strain, ensure you recover properly.")
        case .allOut:
            parts.append("This is maximum effort. Prioritize recovery tomorrow.")
        }

        if components.zoneMinutes.zone5 > 0 {
            parts.append("You spent \(Int(components.zoneMinutes.zone5)) minutes in your peak heart rate zone.")
        }

        return parts.joined(separator: " ")
    }
}
