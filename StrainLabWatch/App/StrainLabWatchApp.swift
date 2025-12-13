import SwiftUI
import HealthKit

@main
struct StrainLabWatchApp: App {
    @State private var healthKitManager = WatchHealthKitManager()
    @StateObject private var workoutManager = WorkoutSessionManager()
    @StateObject private var connectivityManager = WatchConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environment(healthKitManager)
                .environmentObject(workoutManager)
                .environmentObject(connectivityManager)
                .task {
                    do {
                        try await healthKitManager.requestAuthorization()
                        healthKitManager.startHRVObservation()
                    } catch {
                        print("HealthKit authorization failed: \(error)")
                    }
                }
        }
    }
}
