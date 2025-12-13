import Foundation

public protocol WatchDataTransferring: Sendable {
    func sendHeartRateSamples(_ samples: [HeartRateSample]) async throws
    func sendHRVSamples(_ samples: [HRVSample]) async throws
    func sendWorkoutSession(_ session: WorkoutSession) async throws
    var isReachable: Bool { get }
}

public enum WatchMessage: Codable, Sendable {
    case heartRateBatch([HeartRateSample])
    case hrvBatch([HRVSample])
    case workoutCompleted(WorkoutSession)
    case syncRequest
    case syncComplete

    public var messageType: String {
        switch self {
        case .heartRateBatch: return "heartRateBatch"
        case .hrvBatch: return "hrvBatch"
        case .workoutCompleted: return "workoutCompleted"
        case .syncRequest: return "syncRequest"
        case .syncComplete: return "syncComplete"
        }
    }
}
