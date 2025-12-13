import SwiftUI
import HealthKit

struct HealthKitPermissionView: View {
    @ObservedObject private var coordinator = OnboardingCoordinator.shared
    @State private var permissionGranted = false
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: StrainLabTheme.paddingL) {
            Spacer()

            // Header
            VStack(spacing: StrainLabTheme.paddingM) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 56, weight: .medium))
                    .foregroundStyle(StrainLabTheme.recoveryRed)

                Text("Health Data Access")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(StrainLabTheme.textPrimary)

                Text("StrainLab needs access to your health data to calculate your recovery, strain, and sleep scores.")
                    .font(StrainLabTheme.bodyFont)
                    .foregroundStyle(StrainLabTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, StrainLabTheme.paddingL)
            }

            // Data types
            VStack(spacing: StrainLabTheme.paddingS) {
                DataTypeRow(icon: "waveform.path", title: "Heart Rate Variability")
                DataTypeRow(icon: "heart.fill", title: "Heart Rate")
                DataTypeRow(icon: "bed.double.fill", title: "Sleep Analysis")
                DataTypeRow(icon: "figure.walk", title: "Workouts & Activity")
            }
            .padding(.horizontal, StrainLabTheme.paddingL)
            .padding(.top, StrainLabTheme.paddingM)

            Spacer()

            // Privacy note
            HStack(spacing: StrainLabTheme.paddingS) {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(StrainLabTheme.textTertiary)

                Text("Your data stays on your device. We never share or sell your health information.")
                    .font(StrainLabTheme.captionFont)
                    .foregroundStyle(StrainLabTheme.textTertiary)
            }
            .padding(.horizontal, StrainLabTheme.paddingL)

            // Buttons
            VStack(spacing: StrainLabTheme.paddingM) {
                Button {
                    Task {
                        await requestHealthKitPermission()
                    }
                } label: {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(permissionGranted ? "Permission Granted" : "Allow Health Access")
                        }
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(permissionGranted ? StrainLabTheme.recoveryGreen : StrainLabTheme.strainBlue)
                    .clipShape(RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusM))
                }
                .buttonStyle(.plain)
                .disabled(isRequesting || permissionGranted)

                if permissionGranted {
                    Button {
                        coordinator.nextStep()
                    } label: {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(StrainLabTheme.strainBlue)
                    }
                }
            }
            .padding(.horizontal, StrainLabTheme.paddingL)
            .padding(.bottom, StrainLabTheme.paddingXL)
        }
    }

    private func requestHealthKitPermission() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            coordinator.nextStep()
            return
        }

        isRequesting = true

        let healthStore = HKHealthStore()

        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.heartRate),
            HKQuantityType(.heartRateVariabilitySDNN),
            HKQuantityType(.restingHeartRate),
            HKCategoryType(.sleepAnalysis),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.appleExerciseTime),
            HKObjectType.workoutType()
        ]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            await MainActor.run {
                permissionGranted = true
                isRequesting = false
            }
        } catch {
            await MainActor.run {
                isRequesting = false
                // Still allow continuing even if permission fails
                coordinator.nextStep()
            }
        }
    }
}

struct DataTypeRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: StrainLabTheme.paddingM) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(StrainLabTheme.recoveryRed)
                .frame(width: 24)

            Text(title)
                .font(StrainLabTheme.bodyFont)
                .foregroundStyle(StrainLabTheme.textPrimary)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(StrainLabTheme.recoveryGreen)
        }
        .padding(StrainLabTheme.paddingM)
        .background(StrainLabTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusS))
    }
}

#Preview {
    HealthKitPermissionView()
        .background(Color.black)
}
