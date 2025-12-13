import Foundation

public struct HRVSample: Codable, Identifiable, Sendable, Hashable {
    public let id: UUID
    public let timestamp: Date
    public let sdnnMilliseconds: Double
    public let rrIntervalsMs: [Double]?

    public init(
        id: UUID = UUID(),
        timestamp: Date,
        sdnnMilliseconds: Double,
        rrIntervalsMs: [Double]? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.sdnnMilliseconds = sdnnMilliseconds
        self.rrIntervalsMs = rrIntervalsMs
    }
}
