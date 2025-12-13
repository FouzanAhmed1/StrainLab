import SwiftUI
import HealthKit

@main
struct StrainLabWatchApp: App {
    @State private var healthKitManager = WatchHealthKitManager()
    @State private var scoreEngine = WatchScoreEngine.shared
    @StateObject private var workoutManager = WorkoutSessionManager()
    @StateObject private var connectivityManager = WatchConnectivityManager.shared

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

        // 2. Load cached scores
        await scoreEngine.loadCachedScores()

        // 3. Request sync from iPhone
        connectivityManager.requestSync()
    }
}
