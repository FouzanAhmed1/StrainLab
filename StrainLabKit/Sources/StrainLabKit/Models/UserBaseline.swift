import Foundation

public struct UserBaseline: Codable, Identifiable, Sendable, Hashable {
    public let id: UUID
    public let date: Date
    public let hrvBaseline7Day: Double
    public let rhrBaseline7Day: Double
    public let sleepNeedMinutes: Double
    public let maxHeartRate: Double

    public init(
        id: UUID = UUID(),
        date: Date,
        hrvBaseline7Day: Double,
        rhrBaseline7Day: Double,
        sleepNeedMinutes: Double = 450,
        maxHeartRate: Double
    ) {
        self.id = id
        self.date = date
        self.hrvBaseline7Day = hrvBaseline7Day
        self.rhrBaseline7Day = rhrBaseline7Day
        self.sleepNeedMinutes = sleepNeedMinutes
        self.maxHeartRate = maxHeartRate
    }

    public var sleepNeedHours: Double {
        sleepNeedMinutes / 60.0
    }

    public static func defaultBaseline(age: Int) -> UserBaseline {
        let estimatedMaxHR = Double(220 - age)
        return UserBaseline(
            date: Date(),
            hrvBaseline7Day: 50,
            rhrBaseline7Day: 60,
            sleepNeedMinutes: 450,
            maxHeartRate: estimatedMaxHR
        )
    }
}
