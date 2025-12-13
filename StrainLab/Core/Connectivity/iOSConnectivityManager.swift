import Foundation
import WatchConnectivity
import StrainLabKit

public final class iOSConnectivityManager: NSObject, ObservableObject, @unchecked Sendable {
    public static let shared = iOSConnectivityManager()

    @Published public var isWatchReachable = false
    @Published public var isWatchPaired = false

    private var session: WCSession?
    private let decoder = JSONDecoder()

    public var onHeartRateSamplesReceived: (([HeartRateSample]) -> Void)?
    public var onHRVSamplesReceived: (([HRVSample]) -> Void)?
    public var onWorkoutReceived: ((WorkoutSession) -> Void)?

    private override init() {
        super.init()

        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    public func sendSyncRequest() {
        guard let session = session,
              session.activationState == .activated,
              session.isReachable else { return }

        let message: [String: Any] = [
            "type": "syncRequest",
            "timestamp": Date().timeIntervalSince1970
        ]

        session.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }

    public func sendSyncComplete() {
        guard let session = session,
              session.activationState == .activated else { return }

        let message: [String: Any] = [
            "type": "syncComplete",
            "timestamp": Date().timeIntervalSince1970
        ]

        if session.isReachable {
            session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        } else {
            session.transferUserInfo(message)
        }
    }

    private func processReceivedMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String,
              let data = message["data"] as? Data else { return }

        do {
            switch type {
            case "heartRateBatch":
                let samples = try decoder.decode([HeartRateSample].self, from: data)
                DispatchQueue.main.async {
                    self.onHeartRateSamplesReceived?(samples)
                }

            case "hrvBatch":
                let samples = try decoder.decode([HRVSample].self, from: data)
                DispatchQueue.main.async {
                    self.onHRVSamplesReceived?(samples)
                }

            case "workoutCompleted":
                let workout = try decoder.decode(WorkoutSession.self, from: data)
                DispatchQueue.main.async {
                    self.onWorkoutReceived?(workout)
                }

            default:
                break
            }
        } catch {
            print("Failed to decode message: \(error)")
        }
    }
}

extension iOSConnectivityManager: WCSessionDelegate {
    public func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
            self.isWatchPaired = session.isPaired
        }
    }

    public func sessionDidBecomeInactive(_ session: WCSession) {}

    public func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    public func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
        }
    }

    public func sessionWatchStateDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchPaired = session.isPaired
        }
    }

    public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        processReceivedMessage(message)
    }

    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        processReceivedMessage(userInfo)
    }

    public func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        processReceivedMessage(message)
        replyHandler(["status": "received"])
    }
}
