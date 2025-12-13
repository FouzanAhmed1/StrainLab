import Foundation

public struct SleepSession: Codable, Identifiable, Sendable, Hashable {
    public let id: UUID
    public let startDate: Date
    public let endDate: Date
    public let stages: [SleepStage]

    public struct SleepStage: Codable, Sendable, Hashable {
        public let type: StageType
        public let startDate: Date
        public let endDate: Date

        public enum StageType: String, Codable, Sendable {
            case awake
            case rem
            case core
            case deep
            case inBed
            case asleepUnspecified
        }

        public init(type: StageType, startDate: Date, endDate: Date) {
            self.type = type
            self.startDate = startDate
            self.endDate = endDate
        }

        public var durationMinutes: Double {
            endDate.timeIntervalSince(startDate) / 60.0
        }
    }

    public init(id: UUID = UUID(), startDate: Date, endDate: Date, stages: [SleepStage]) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.stages = stages
    }

    public var totalDurationMinutes: Double {
        endDate.timeIntervalSince(startDate) / 60.0
    }

    public var sleepEfficiency: Double {
        let awakeTime = stages
            .filter { $0.type == .awake }
            .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
        let totalTime = endDate.timeIntervalSince(startDate)
        guard totalTime > 0 else { return 0 }
        return max(0, (totalTime - awakeTime) / totalTime)
    }

    public var deepSleepMinutes: Double {
        stages.filter { $0.type == .deep }.reduce(0.0) { $0 + $1.durationMinutes }
    }

    public var remSleepMinutes: Double {
        stages.filter { $0.type == .rem }.reduce(0.0) { $0 + $1.durationMinutes }
    }

    public var coreSleepMinutes: Double {
        stages.filter { $0.type == .core }.reduce(0.0) { $0 + $1.durationMinutes }
    }
}
