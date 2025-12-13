import Foundation
import WatchConnectivity
import StrainLabKit

public final class WatchConnectivityManager: NSObject, ObservableObject, @unchecked Sendable {
    public static let shared = WatchConnectivityManager()

    @Published public var isReachable = false
    @Published public var isPaired = false

    private var session: WCSession?
    private let encoder = JSONEncoder()

    private override init() {
        super.init()

        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    public func transferHeartRateSamples(_ samples: [HeartRateSample]) {
        guard let session = session,
              session.activationState == .activated,
              !samples.isEmpty else { return }

        do {
            let data = try encoder.encode(samples)
            let message: [String: Any] = [
                "type": "heartRateBatch",
                "data": data,
                "timestamp": Date().timeIntervalSince1970
            ]
            session.transferUserInfo(message)
        } catch {
            print("Failed to encode heart rate samples: \(error)")
        }
    }

    public func transferHRVSamples(_ samples: [HRVSample]) {
        guard let session = session,
              session.activationState == .activated,
              !samples.isEmpty else { return }

        do {
            let data = try encoder.encode(samples)
            let message: [String: Any] = [
                "type": "hrvBatch",
                "data": data,
                "timestamp": Date().timeIntervalSince1970
            ]
            session.transferUserInfo(message)
        } catch {
            print("Failed to encode HRV samples: \(error)")
        }
    }

    public func sendWorkoutSession(_ workout: WorkoutSession) {
        guard let session = session,
              session.activationState == .activated else { return }

        do {
            let data = try encoder.encode(workout)
            let message: [String: Any] = [
                "type": "workoutCompleted",
                "data": data,
                "timestamp": Date().timeIntervalSince1970
            ]

            if session.isReachable {
                session.sendMessage(message, replyHandler: nil) { error in
                    session.transferUserInfo(message)
                }
            } else {
                session.transferUserInfo(message)
            }
        } catch {
            print("Failed to encode workout session: \(error)")
        }
    }

    public func requestSync() {
        guard let session = session,
              session.activationState == .activated else { return }

        let message: [String: Any] = [
            "type": "syncRequest",
            "timestamp": Date().timeIntervalSince1970
        ]

        if session.isReachable {
            session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    public func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            #if os(watchOS)
            self.isPaired = true
            #else
            self.isPaired = session.isPaired
            #endif
        }
    }

    public func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {}

    public func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif

    public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleReceivedMessage(message)
    }

    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        handleReceivedMessage(userInfo)
    }

    private func handleReceivedMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else { return }

        switch type {
        case "syncRequest":
            NotificationCenter.default.post(name: .watchSyncRequested, object: nil)
        case "syncComplete":
            NotificationCenter.default.post(name: .watchSyncCompleted, object: nil)
        default:
            break
        }
    }
}

public extension Notification.Name {
    static let watchSyncRequested = Notification.Name("watchSyncRequested")
    static let watchSyncCompleted = Notification.Name("watchSyncCompleted")
}
