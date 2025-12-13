import SwiftUI
import HealthKit

@main
struct StrainLabWatchApp: App {
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) var appDelegate

    @State private var healthKitManager = WatchHealthKitManager()
    @State private var scoreEngine = WatchScoreEngine.shared
    @StateObject private var workoutManager = WorkoutSessionManager()
    @StateObject private var connectivityManager = WatchConnectivityManager.shared

    private let backgroundManager = WatchBackgroundManager.shared
    private let notificationManager = WatchNotificationManager.shared

    var body: some Scene {
        WindowGroup {
            DailyReadinessView()
                .environment(healthKitManager)
                .environment(scoreEngine)
                .environmentObject(workoutManager)
                .environmentObject(connectivityManager)
                .task {
                    await setupApp()
                }
        }
    }

    private func setupApp() async {
        // 1. Request HealthKit authorization
        do {
            try await healthKitManager.requestAuthorization()
            healthKitManager.startHeartRateObservation()
            healthKitManager.startHRVObservation()
        } catch {
            print("HealthKit authorization failed: \(error)")
        }

        // 2. Request notification authorization
        _ = await notificationManager.requestAuthorization()
        notificationManager.setNotificationsEnabled(true)

        // 3. Configure background manager with dependencies
        backgroundManager.configure(
            healthKitManager: healthKitManager,
            scoreEngine: scoreEngine,
            connectivityManager: connectivityManager
        )

        // 4. Load cached scores
        await scoreEngine.loadCachedScores()

        // 5. Request sync from iPhone
        connectivityManager.requestSync()
    }
}
