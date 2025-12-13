import Foundation
import WatchKit
import WidgetKit

/// Manages background app refresh scheduling and execution for Apple Watch
/// Handles periodic data collection, iPhone sync, and complication updates
public final class WatchBackgroundManager: NSObject, @unchecked Sendable {

    public static let shared = WatchBackgroundManager()

    // MARK: - Dependencies

    private weak var healthKitManager: WatchHealthKitManager?
    private weak var scoreEngine: WatchScoreEngine?
    private weak var connectivityManager: WatchConnectivityManager?
    private let dataStore = WatchDataStore.shared
    private let notificationManager = WatchNotificationManager.shared

    // MARK: - Refresh Intervals

    private enum RefreshInterval {
        static let morning: TimeInterval = 5 * 60        // 5 minutes (6-8 AM)
        static let daytime: TimeInterval = 15 * 60       // 15 minutes (8 AM - 10 PM)
        static let nighttime: TimeInterval = 2 * 60 * 60 // 2 hours (10 PM - 6 AM)
    }

    // MARK: - Initialization

    private override init() {
        super.init()
    }

    // MARK: - Configuration

    /// Configure with required dependencies
    public func configure(
        healthKitManager: WatchHealthKitManager,
        scoreEngine: WatchScoreEngine,
        connectivityManager: WatchConnectivityManager
    ) {
        self.healthKitManager = healthKitManager
        self.scoreEngine = scoreEngine
        self.connectivityManager = connectivityManager
    }

    // MARK: - Background Task Registration

    /// Register for background refresh tasks
    /// Note: Background task identifiers should be registered in Info.plist
    /// under BGTaskSchedulerPermittedIdentifiers
    public func registerBackgroundTasks() {
        // Background task registration happens automatically via Info.plist
        // Schedule the initial refresh
        scheduleNextRefresh()
    }

    /// Schedule the next background refresh
    public func scheduleNextRefresh() {
        let interval = calculateRefreshInterval()
        let refreshDate = Date().addingTimeInterval(interval)

        WKApplication.shared().scheduleBackgroundRefresh(
            withPreferredDate: refreshDate,
            userInfo: nil
        ) { error in
            if let error = error {
                print("WatchBackgroundManager: Failed to schedule refresh: \(error)")
            } else {
                print("WatchBackgroundManager: Next refresh scheduled for \(refreshDate)")
            }
        }
    }

    // MARK: - Background Refresh Handling

    /// Handle a background refresh task
    /// Call this from WKApplicationDelegate.handle(_:)
    public func handleBackgroundRefresh(_ backgroundTask: WKRefreshBackgroundTask) async {
        defer {
            // Always schedule next refresh and complete the task
            scheduleNextRefresh()
            backgroundTask.setTaskCompletedWithSnapshot(false)
        }

        print("WatchBackgroundManager: Starting background refresh")

        // 1. Collect pending health data
        await collectHealthData()

        // 2. Attempt to sync with iPhone
        await syncWithiPhone()

        // 3. Calculate local scores if needed
        await calculateLocalScoresIfNeeded()

        // 4. Update complications
        reloadComplications()

        // 5. Check and send notifications
        await checkAndSendNotifications()

        print("WatchBackgroundManager: Background refresh complete")
    }

    // MARK: - Data Collection

    private func collectHealthData() async {
        guard let healthKit = healthKitManager else { return }

        // Query recent heart rate samples
        let heartRateSamples = await healthKit.queryRecentHeartRateSamples(hours: 1)
        if !heartRateSamples.isEmpty {
            connectivityManager?.queueHeartRateSamples(heartRateSamples)
            print("WatchBackgroundManager: Collected \(heartRateSamples.count) HR samples")
        }

        // Query recent HRV samples
        let hrvSamples = await healthKit.queryRecentHRVSamples(hours: 1)
        if !hrvSamples.isEmpty {
            connectivityManager?.queueHRVSamples(hrvSamples)
            print("WatchBackgroundManager: Collected \(hrvSamples.count) HRV samples")
        }
    }

    // MARK: - iPhone Sync

    private func syncWithiPhone() async {
        guard let connectivity = connectivityManager else { return }

        // Check if iPhone is reachable
        guard connectivity.isReachable else {
            print("WatchBackgroundManager: iPhone not reachable, queueing data")
            return
        }

        // Send queued data to iPhone
        connectivity.sendPendingDataToPhone()
    }

    // MARK: - Local Score Calculation

    private func calculateLocalScoresIfNeeded() async {
        guard let scoreEngine = scoreEngine, let healthKit = healthKitManager else { return }

        // Check if we have recent scores from iPhone
        let lastSync = dataStore.getLastPhoneSyncDate()
        let staleThreshold: TimeInterval = 2 * 60 * 60 // 2 hours

        let needsLocalCalculation: Bool
        if let lastSync = lastSync {
            needsLocalCalculation = Date().timeIntervalSince(lastSync) > staleThreshold
        } else {
            needsLocalCalculation = true
        }

        if needsLocalCalculation {
            print("WatchBackgroundManager: Calculating local scores (stale data)")

            // Gather health data for local calculation
            let overnightHRV = await healthKit.queryOvernightHRV()
            let restingHeartRate = await healthKit.queryRestingHeartRate()
            let sleepDuration = await healthKit.queryLastNightSleepDuration()
            let todayHeartRateSamples = await healthKit.queryTodayHeartRateSamples()

            await scoreEngine.calculateLocalScores(
                overnightHRV: overnightHRV,
                restingHeartRate: restingHeartRate,
                sleepDurationMinutes: sleepDuration,
                todayHeartRateSamples: todayHeartRateSamples
            )
            dataStore.setIsLocalCalculation(true)
        }
    }

    // MARK: - Complication Updates

    private func reloadComplications() {
        WidgetCenter.shared.reloadAllTimelines()
        print("WatchBackgroundManager: Complication timelines reloaded")
    }

    // MARK: - Notifications

    private func checkAndSendNotifications() async {
        await notificationManager.checkAndSendScheduledNotifications()
    }

    // MARK: - Refresh Interval Calculation

    private func calculateRefreshInterval() -> TimeInterval {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())

        // Morning: More frequent updates to capture wake-up HRV
        if hour >= 6 && hour < 8 {
            return RefreshInterval.morning
        }
        // Daytime: Regular updates for strain tracking
        else if hour >= 8 && hour < 22 {
            return RefreshInterval.daytime
        }
        // Nighttime: Conserve battery
        else {
            return RefreshInterval.nighttime
        }
    }
}

// MARK: - WKApplicationDelegate Integration

/// Extension to integrate with WKApplicationDelegate
extension WatchBackgroundManager {

    /// Check if this is a handled background task
    public func isHandledBackgroundTask(_ task: WKRefreshBackgroundTask) -> Bool {
        return task is WKApplicationRefreshBackgroundTask
    }
}
