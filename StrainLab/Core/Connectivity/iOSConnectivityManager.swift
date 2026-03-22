import Foundation
import WatchConnectivity
import StrainLabKit

public final class iOSConnectivityManager: NSObject, ObservableObject, @unchecked Sendable {
    public static let shared = iOSConnectivityManager()

    @Published public var isWatchReachable = false
    @Published public var isWatchPaired = false
    @Published public var isReceivingLiveData = false

    // Live data from Watch
    @Published public var liveHeartRate: Double = 0
    @Published public var liveStrain: Double = 0
    @Published public var liveCalories: Double = 0
    @Published public var liveDuration: TimeInterval = 0
    @Published public var currentZone: String = "Rest"
    @Published public var isWorkoutActiveOnWatch = false

    var isReachable: Bool { isWatchReachable }

    private var session: WCSession?
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    // Data callbacks
    public var onHeartRateSamplesReceived: (([HeartRateSample]) -> Void)?
    public var onHRVSamplesReceived: (([HRVSample]) -> Void)?
    public var onWorkoutReceived: ((WorkoutSession) -> Void)?

    // Real-time callbacks
    public var onLiveHeartRateReceived: ((_ heartRate: Double, _ zone: String) -> Void)?
    public var onLiveWorkoutStatsReceived: ((LiveWorkoutStats) -> Void)?
    public var onWorkoutStarted: (() -> Void)?
    public var onWorkoutEnded: ((WorkoutSummary) -> Void)?

    private override init() {
        super.init()

        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    // MARK: - Sync Commands

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

    // MARK: - Workout Control Commands

    public func sendWorkoutCommand(_ command: WorkoutCommand) {
        guard let session = session,
              session.activationState == .activated,
              session.isReachable else { return }

        var message: [String: Any] = [
            "timestamp": Date().timeIntervalSince1970
        ]

        switch command {
        case .start(let activityType):
            message["type"] = "startWorkout"
            message["activityType"] = activityType
        case .pause:
            message["type"] = "pauseWorkout"
        case .resume:
            message["type"] = "resumeWorkout"
        case .stop:
            message["type"] = "stopWorkout"
        }

        session.sendMessage(message, replyHandler: nil) { error in
            print("Failed to send workout command: \(error.localizedDescription)")
        }
    }

    // MARK: - Score Sync to Watch

    /// Send scores and baseline to Watch
    public func sendScoresToWatch(
        recovery: RecoveryScore?,
        strain: StrainScore?,
        sleep: SleepScore?,
        baseline: UserBaseline?
    ) {
        guard let session = session,
              session.activationState == .activated else { return }

        guard let baseline = baseline else { return }

        let payload = PhoneSyncPayload(
            timestamp: Date(),
            recovery: recovery,
            strain: strain,
            sleep: sleep,
            baseline: baseline
        )

        do {
            let data = try encoder.encode(payload)
            let message: [String: Any] = [
                "type": "phoneSyncPayload",
                "data": data,
                "timestamp": Date().timeIntervalSince1970
            ]

            if session.isReachable {
                session.sendMessage(message, replyHandler: nil) { error in
                    // Fall back to background transfer
                    session.transferUserInfo(message)
                }
            } else {
                session.transferUserInfo(message)
            }
        } catch {
            print("Failed to encode phone sync payload: \(error)")
        }
    }

    // MARK: - Message Processing

    private func processReceivedMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else { return }

        switch type {
        // Data batches
        case "heartRateBatch", "hrvBatch", "workoutCompleted", "watchDataPayload":
            processDataMessage(type: type, message: message)

        // Live heart rate update
        case "liveHeartRate":
            if let heartRate = message["heartRate"] as? Double,
               let zone = message["zone"] as? String {
                DispatchQueue.main.async {
                    self.liveHeartRate = heartRate
                    self.currentZone = zone
                    self.isReceivingLiveData = true
                    self.onLiveHeartRateReceived?(heartRate, zone)
                }
            }

        // Live workout stats
        case "liveWorkoutStats":
            if let heartRate = message["heartRate"] as? Double,
               let strain = message["strain"] as? Double,
               let calories = message["calories"] as? Double,
               let duration = message["duration"] as? TimeInterval,
               let zone = message["zone"] as? String {

                let stats = LiveWorkoutStats(
                    heartRate: heartRate,
                    strain: strain,
                    calories: calories,
                    duration: duration,
                    zone: zone
                )

                DispatchQueue.main.async {
                    self.liveHeartRate = heartRate
                    self.liveStrain = strain
                    self.liveCalories = calories
                    self.liveDuration = duration
                    self.currentZone = zone
                    self.isWorkoutActiveOnWatch = true
                    self.onLiveWorkoutStatsReceived?(stats)
                }
            }

        // Workout started notification
        case "workoutStarted":
            DispatchQueue.main.async {
                self.isWorkoutActiveOnWatch = true
                self.onWorkoutStarted?()
            }

        // Workout ended notification
        case "workoutEnded":
            if let strain = message["strain"] as? Double,
               let duration = message["duration"] as? TimeInterval,
               let calories = message["calories"] as? Double,
               let avgHeartRate = message["avgHeartRate"] as? Double,
               let maxHeartRate = message["maxHeartRate"] as? Double {

                let summary = WorkoutSummary(
                    date: Date(),
                    strain: strain,
                    duration: duration,
                    calories: calories,
                    avgHeartRate: avgHeartRate,
                    maxHeartRate: maxHeartRate
                )

                DispatchQueue.main.async {
                    self.isWorkoutActiveOnWatch = false
                    self.isReceivingLiveData = false
                    self.onWorkoutEnded?(summary)
                }
            }

        default:
            break
        }
    }

    private func processDataMessage(type: String, message: [String: Any]) {
        guard let data = message["data"] as? Data else { return }

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

            case "watchDataPayload":
                let payload = try decoder.decode(WatchDataPayload.self, from: data)
                DispatchQueue.main.async {
                    // Process all data from payload
                    if !payload.heartRateSamples.isEmpty {
                        self.onHeartRateSamplesReceived?(payload.heartRateSamples)
                    }
                    if !payload.hrvSamples.isEmpty {
                        self.onHRVSamplesReceived?(payload.hrvSamples)
                    }
                    for workout in payload.completedWorkouts {
                        self.onWorkoutReceived?(workout)
                    }
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
            if !session.isReachable {
                self.isReceivingLiveData = false
            }
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
