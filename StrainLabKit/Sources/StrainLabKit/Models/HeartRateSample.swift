import Foundation

public struct HeartRateSample: Codable, Identifiable, Sendable, Hashable {
    public let id: UUID
    public let timestamp: Date
    public let beatsPerMinute: Double
    public let source: SampleSource

    public enum SampleSource: String, Codable, Sendable {
        case watch
        case manual
    }

    public init(id: UUID = UUID(), timestamp: Date, beatsPerMinute: Double, source: SampleSource) {
        self.id = id
        self.timestamp = timestamp
        self.beatsPerMinute = beatsPerMinute
        self.source = source
    }
}
