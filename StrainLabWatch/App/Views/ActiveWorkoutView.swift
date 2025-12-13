import SwiftUI
import StrainLabKit

struct ActiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var workoutManager: WorkoutSessionManager
    @EnvironmentObject private var connectivityManager: WatchConnectivityManager
    @State private var showingEndConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text(workoutManager.formattedElapsedTime)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Duration")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 24) {
                    MetricView(
                        value: "\(Int(workoutManager.currentHeartRate))",
                        unit: "BPM",
                        icon: "heart.fill",
                        color: .red
                    )

                    MetricView(
                        value: "\(Int(workoutManager.activeCalories))",
                        unit: "CAL",
                        icon: "flame.fill",
                        color: .orange
                    )
                }

                Spacer()

                HStack(spacing: 16) {
                    Button {
                        if workoutManager.isWorkoutActive {
                            workoutManager.pauseWorkout()
                        } else {
                            workoutManager.resumeWorkout()
                        }
                    } label: {
                        Image(systemName: workoutManager.isWorkoutActive ? "pause.fill" : "play.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.bordered)
                    .tint(.yellow)

                    Button {
                        showingEndConfirmation = true
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
            .padding()
        }
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "End Workout?",
            isPresented: $showingEndConfirmation,
            titleVisibility: .visible
        ) {
            Button("End Workout", role: .destructive) {
                endWorkout()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func endWorkout() {
        Task {
            do {
                let session = try await workoutManager.endWorkout()
                connectivityManager.sendWorkoutSession(session)
                dismiss()
            } catch {
                print("Failed to end workout: \(error)")
            }
        }
    }
}

struct MetricView: View {
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        ActiveWorkoutView()
            .environmentObject(WorkoutSessionManager())
            .environmentObject(WatchConnectivityManager.shared)
    }
}
