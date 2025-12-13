import SwiftUI
import HealthKit

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
                            .foregroundStyle(.green)
                        Text(name)
                    }
                }
            }
        }
        .navigationTitle("Select Workout")
    }

    private func startWorkout(type: HKWorkoutActivityType) {
        Task {
            do {
                try await workoutManager.startWorkout(activityType: type)
                dismiss()
            } catch {
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
