import SwiftUI
import HealthKit
import WatchKit

struct WorkoutSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var workoutManager: WorkoutSessionManager

    private let workoutTypes: [(HKWorkoutActivityType, String, String)] = [
        (.running, "Running", "figure.run"),
        (.cycling, "Cycling", "figure.outdoor.cycle"),
        (.walking, "Walking", "figure.walk"),
        (.hiking, "Hiking", "figure.hiking"),
        (.traditionalStrengthTraining, "Strength", "dumbbell.fill"),
        (.highIntensityIntervalTraining, "HIIT", "flame.fill"),
        (.yoga, "Yoga", "figure.yoga"),
        (.swimming, "Swimming", "figure.pool.swim"),
        (.crossTraining, "Cross Training", "figure.cross.training")
    ]

    var body: some View {
        List {
            ForEach(workoutTypes, id: \.0) { type, name, icon in
                Button {
                    startWorkout(type: type)
                } label: {
                    HStack {
                        Image(systemName: icon)
                            .font(.title3)
                            .frame(width: 30)
                            .foregroundStyle(WatchTheme.recoveryGreen)
                        Text(name)
                            .font(WatchTheme.bodyFont)
                    }
                }
                .accessibilityLabel("Start \(name) workout")
            }
        }
        .navigationTitle("Select Workout")
    }

    private func startWorkout(type: HKWorkoutActivityType) {
        Task {
            do {
                // Play haptic feedback on workout start
                WKInterfaceDevice.current().play(.start)
                try await workoutManager.startWorkout(activityType: type)
                dismiss()
            } catch {
                // Play failure haptic
                WKInterfaceDevice.current().play(.failure)
                print("Failed to start workout: \(error)")
            }
        }
    }
}

#Preview {
    NavigationStack {
        WorkoutSelectionView()
            .environmentObject(WorkoutSessionManager())
    }
}
