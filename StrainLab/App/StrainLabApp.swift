import SwiftUI

@main
struct StrainLabApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var isAuthorized = false
    @Published var isLoading = true
    @Published var errorMessage: String?

    private let connectivityManager = iOSConnectivityManager.shared

    init() {
        setupConnectivityHandlers()
    }

    func initialize() async {
        isLoading = true

        do {
            let healthKit = iOSHealthKitManager()
            try await healthKit.requestAuthorization()
            isAuthorized = true
        } catch {
            errorMessage = error.localizedDescription
            isAuthorized = false
        }

        isLoading = false
    }

    private func setupConnectivityHandlers() {
        connectivityManager.onHeartRateSamplesReceived = { samples in
            Task {
                try? await CoreDataManager.shared.saveHeartRateSamples(samples)
            }
        }

        connectivityManager.onHRVSamplesReceived = { samples in
            Task {
                try? await CoreDataManager.shared.saveHRVSamples(samples)
            }
        }

        connectivityManager.onWorkoutReceived = { workout in
            print("Received workout: \(workout.activityType)")
        }
    }
}
