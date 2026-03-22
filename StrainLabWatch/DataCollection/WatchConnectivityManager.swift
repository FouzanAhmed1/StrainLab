import Foundation
import WatchConnectivity
import StrainLabKit

public final class WatchConnectivityManager: NSObject, ObservableObject, @unchecked Sendable {
    public static let shared = WatchConnectivityManager()

    @Published public var isReachable = false
    @Published public var isPaired = false
    @Published public var lastSyncDate: Date?
    @Published public var isSyncing = false

    // Real-time data streaming
    @Published public var liveHeartRateFromPhone: Double = 0
    @Published public var liveStrainFromPhone: Double = 0
    @Published public var isWorkoutActiveOnPhone = false

    // Workout control callbacks
    public var onWorkoutStartRequested: ((String) -> Void)?
    public var onWorkoutPauseRequested: (() -> Void)?
    public var onWorkoutResumeRequested: (() -> Void)?
    public var onWorkoutStopRequested: (() -> Void)?

    private var session: WCSession?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let dataStore = WatchDataStore.shared

    // Real-time streaming timer
    private var streamingTimer: Timer?
    private var isStreamingLiveData = false

    private override init() {
        super.init()

        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    // MARK: - Real-Time Data Streaming

    /// Start streaming live heart rate and workout data to iPhone
    public func startLiveDataStreaming(healthKit: WatchHealthKitManager) {
        guard !isStreamingLiveData else { return }
        isStreamingLiveData = true

        streamingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.sendLiveHeartRateUpdate(healthKit.currentHeartRate, zone: healthKit.heartRateZone)
        }
    }

    /// Stop streaming live data
    public func stopLiveDataStreaming() {
        streamingTimer?.invalidate()
        streamingTimer = nil
        isStreamingLiveData = false
    }

    /// Send real-time heart rate update to iPhone
    public func sendLiveHeartRateUpdate(_ heartRate: Double, zone: HeartRateZone) {
        guard let session = session,
              session.isReachable,
              heartRate > 0 else { return }

        let message: [String: Any] = [
            "type": "liveHeartRate",
            "heartRate": heartRate,
            "zone": zone.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ]

        session.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }

    /// Send live workout stats to iPhone
    public func sendLiveWorkoutStats(
        heartRate: Double,
        strain: Double,
        calories: Double,
        duration: TimeInterval,
        zone: HeartRateZone
    ) {
        guard let session = session,
              session.isReachable else { return }

        let message: [String: Any] = [
            "type": "liveWorkoutStats",
            "heartRate": heartRate,
            "strain": strain,
            "calories": calories,
            "duration": duration,
            "zone": zone.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ]

        session.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }

    /// Notify iPhone that workout started
    public func notifyWorkoutStarted(activityType: String) {
        guard let session = session else { return }

        let message: [String: Any] = [
            "type": "workoutStarted",
            "activityType": activityType,
            "timestamp": Date().timeIntervalSince1970
        ]

        if session.isReachable {
            session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        } else {
            session.transferUserInfo(message)
        }
    }

    /// Notify iPhone that workout ended
    public func notifyWorkoutEnded(
        strain: Double,
        duration: TimeInterval,
        calories: Double,
        avgHeartRate: Double,
        maxHeartRate: Double
    ) {
        guard let session = session else { return }

        let message: [String: Any] = [
            "type": "workoutEnded",
            "strain": strain,
            "duration": duration,
            "calories": calories,
            "avgHeartRate": avgHeartRate,
            "maxHeartRate": maxHeartRate,
            "timestamp": Date().timeIntervalSince1970
        ]

        if session.isReachable {
            session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        } else {
            session.transferUserInfo(message)
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

    // MARK: - Bidirectional Sync

    /// Send accumulated Watch data to iPhone
    /// Called during background refresh or manually
    public func sendDataToPhone(_ payload: WatchDataPayload) {
        guard let session = session,
              session.activationState == .activated,
              payload.hasData else { return }

        do {
            let data = try encoder.encode(payload)
            let message: [String: Any] = [
                "type": "watchDataPayload",
                "data": data,
                "timestamp": Date().timeIntervalSince1970
            ]

            if session.isReachable {
                session.sendMessage(message, replyHandler: { [weak self] response in
                    // iPhone acknowledged receipt
                    DispatchQueue.main.async {
                        self?.lastSyncDate = Date()
                        self?.dataStore.setLastDataSentDate(Date())
                    }
                }) { error in
                    // Fall back to background transfer
                    session.transferUserInfo(message)
                }
            } else {
                // Queue for background transfer
                session.transferUserInfo(message)
            }
        } catch {
            print("WatchConnectivityManager: Failed to encode data payload: \(error)")
        }
    }

    /// Send all pending accumulated data to iPhone
    public func sendPendingDataToPhone() {
        let hrSamples = dataStore.getPendingHeartRateSamples()
        let hrvSamples = dataStore.getPendingHRVSamples()
        let lastSent = dataStore.getLastDataSentDate() ?? Date.distantPast

        guard !hrSamples.isEmpty || !hrvSamples.isEmpty else { return }

        let payload = WatchDataPayload(
            heartRateSamples: hrSamples,
            hrvSamples: hrvSamples,
            completedWorkouts: [],
            lastSyncTimestamp: lastSent
        )

        sendDataToPhone(payload)

        // Clear pending data after sending
        dataStore.clearPendingHeartRateSamples()
        dataStore.clearPendingHRVSamples()
    }

    /// Queue heart rate samples for next sync
    public func queueHeartRateSamples(_ samples: [HeartRateSample]) {
        dataStore.appendPendingHeartRateSamples(samples)
    }

    /// Queue HRV samples for next sync
    public func queueHRVSamples(_ samples: [HRVSample]) {
        dataStore.appendPendingHRVSamples(samples)
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
        case "phoneSyncPayload":
            handlePhoneSyncPayload(message)

        // Workout control commands from iPhone
        case "startWorkout":
            if let activityType = message["activityType"] as? String {
                DispatchQueue.main.async {
                    self.onWorkoutStartRequested?(activityType)
                }
            }
        case "pauseWorkout":
            DispatchQueue.main.async {
                self.onWorkoutPauseRequested?()
            }
        case "resumeWorkout":
            DispatchQueue.main.async {
                self.onWorkoutResumeRequested?()
            }
        case "stopWorkout":
            DispatchQueue.main.async {
                self.onWorkoutStopRequested?()
            }

        // Live data from iPhone (if mirroring)
        case "liveDataFromPhone":
            if let hr = message["heartRate"] as? Double {
                DispatchQueue.main.async {
                    self.liveHeartRateFromPhone = hr
                }
            }
            if let strain = message["strain"] as? Double {
                DispatchQueue.main.async {
                    self.liveStrainFromPhone = strain
                }
            }

        case "phoneWorkoutStatus":
            if let isActive = message["isActive"] as? Bool {
                DispatchQueue.main.async {
                    self.isWorkoutActiveOnPhone = isActive
                }
            }

        default:
            break
        }
    }

    /// Handle incoming score sync from iPhone
    private func handlePhoneSyncPayload(_ message: [String: Any]) {
        guard let data = message["data"] as? Data else {
            print("WatchConnectivityManager: No data in phoneSyncPayload")
            return
        }

        do {
            let payload = try decoder.decode(PhoneSyncPayload.self, from: data)

            // Update score engine with received data
            Task {
                await WatchScoreEngine.shared.syncScoresFromPhone(payload)

                await MainActor.run {
                    self.lastSyncDate = payload.timestamp
                }
            }

            // Post notification for UI updates
            NotificationCenter.default.post(
                name: .phoneSyncReceived,
                object: nil,
                userInfo: ["payload": payload]
            )
        } catch {
            print("WatchConnectivityManager: Failed to decode phone sync payload: \(error)")
        }
    }
}

public extension Notification.Name {
    static let watchSyncRequested = Notification.Name("watchSyncRequested")
    static let watchSyncCompleted = Notification.Name("watchSyncCompleted")
    static let phoneSyncReceived = Notification.Name("phoneSyncReceived")
    static let watchDataSent = Notification.Name("watchDataSent")
}
