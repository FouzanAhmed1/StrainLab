import SwiftUI
import HealthKit

struct WatchHomeView: View {
    @Environment(WatchHealthKitManager.self) private var healthKit
    @EnvironmentObject private var workoutManager: WorkoutSessionManager
    @EnvironmentObject private var connectivityManager: WatchConnectivityManager

    var body: some View {
        NavigationStack {
            List {
                if workoutManager.isWorkoutActive {
                    NavigationLink {
                        ActiveWorkoutView()
                    } label: {
                        HStack {
                            Image(systemName: "figure.run")
                                .foregroundStyle(.green)
                            Text("Active Workout")
                        }
                    }
                } else {
                    NavigationLink {
                        WorkoutSelectionView()
                    } label: {
                        Label("Start Workout", systemImage: "plus.circle.fill")
                    }
                }

                Section {
                    StatusRow(
                        title: "HR Samples",
                        value: "\(healthKit.pendingHeartRateSamples.count)"
                    )
                    StatusRow(
                        title: "HRV Samples",
                        value: "\(healthKit.pendingHRVSamples.count)"
                    )
                    StatusRow(
                        title: "Phone",
                        value: connectivityManager.isReachable ? "Connected" : "Not Connected",
                        valueColor: connectivityManager.isReachable ? .green : .secondary
                    )
                } header: {
                    Text("Status")
                }

                Section {
                    Button {
                        syncData()
                    } label: {
                        Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .disabled(!connectivityManager.isReachable)
                }
            }
            .navigationTitle("StrainLab")
        }
    }

    private func syncData() {
        let hrSamples = healthKit.getAndClearHeartRateSamples()
        let hrvSamples = healthKit.getAndClearHRVSamples()

        if !hrSamples.isEmpty {
            connectivityManager.transferHeartRateSamples(hrSamples)
        }

        if !hrvSamples.isEmpty {
            connectivityManager.transferHRVSamples(hrvSamples)
        }
    }
}

struct StatusRow: View {
    let title: String
    let value: String
    var valueColor: Color = .secondary

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(valueColor)
        }
    }
}

#Preview {
    WatchHomeView()
        .environment(WatchHealthKitManager())
        .environmentObject(WorkoutSessionManager())
        .environmentObject(WatchConnectivityManager.shared)
}
