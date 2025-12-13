import Foundation

public struct SleepScore: Codable, Identifiable, Sendable, Hashable {
    public let id: UUID
    public let date: Date
    public let score: Double
    public let components: Components

    public struct Components: Codable, Sendable, Hashable {
        public let durationScore: Double
        public let efficiencyScore: Double
        public let stageScore: Double
        public let totalDurationMinutes: Double
        public let sleepNeedMinutes: Double
        public let efficiency: Double
        public let deepSleepMinutes: Double
        public let remSleepMinutes: Double

        public init(
            durationScore: Double,
            efficiencyScore: Double,
            stageScore: Double,
            totalDurationMinutes: Double,
            sleepNeedMinutes: Double,
            efficiency: Double,
            deepSleepMinutes: Double,
            remSleepMinutes: Double
        ) {
            self.durationScore = durationScore
            self.efficiencyScore = efficiencyScore
            self.stageScore = stageScore
            self.totalDurationMinutes = totalDurationMinutes
            self.sleepNeedMinutes = sleepNeedMinutes
            self.efficiency = efficiency
            self.deepSleepMinutes = deepSleepMinutes
            self.remSleepMinutes = remSleepMinutes
        }

        public var totalHours: Double {
            totalDurationMinutes / 60.0
        }

        public var sleepNeedHours: Double {
            sleepNeedMinutes / 60.0
        }

        public var formattedDuration: String {
            let hours = Int(totalDurationMinutes / 60)
            let minutes = Int(totalDurationMinutes.truncatingRemainder(dividingBy: 60))
            return "\(hours)h \(minutes)m"
        }

        public var formattedDeepSleep: String {
            let hours = Int(deepSleepMinutes / 60)
            let minutes = Int(deepSleepMinutes.truncatingRemainder(dividingBy: 60))
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(minutes)m"
        }

        public var formattedRemSleep: String {
            let hours = Int(remSleepMinutes / 60)
            let minutes = Int(remSleepMinutes.truncatingRemainder(dividingBy: 60))
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(minutes)m"
        }
    }

    public init(
        id: UUID = UUID(),
        date: Date,
        score: Double,
        components: Components
    ) {
        self.id = id
        self.date = date
        self.score = score
        self.components = components
    }

    public var formattedScore: String {
        "\(Int(score))%"
    }

    public var category: String {
        if score >= 85 {
            return "Excellent"
        } else if score >= 70 {
            return "Good"
        } else if score >= 50 {
            return "Fair"
        } else {
            return "Poor"
        }
    }

    public var explanation: String {
        var parts: [String] = []

        let durationPercent = (components.totalDurationMinutes / components.sleepNeedMinutes) * 100
        if durationPercent >= 95 {
            parts.append("You met your sleep need of \(String(format: "%.1f", components.sleepNeedHours)) hours.")
        } else {
            let deficit = components.sleepNeedMinutes - components.totalDurationMinutes
            parts.append("You were \(Int(deficit)) minutes short of your \(String(format: "%.1f", components.sleepNeedHours)) hour sleep need.")
        }

        let efficiencyPercent = components.efficiency * 100
        if efficiencyPercent >= 90 {
            parts.append("Your sleep efficiency was excellent at \(Int(efficiencyPercent))%.")
        } else if efficiencyPercent >= 80 {
            parts.append("Your sleep efficiency was good at \(Int(efficiencyPercent))%.")
        } else {
            parts.append("Your sleep efficiency was \(Int(efficiencyPercent))%, indicating restless sleep.")
        }

        return parts.joined(separator: " ")
    }
}
