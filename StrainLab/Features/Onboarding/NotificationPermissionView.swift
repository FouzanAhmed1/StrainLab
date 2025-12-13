import SwiftUI

struct NotificationPermissionView: View {
    @ObservedObject private var coordinator = OnboardingCoordinator.shared
    @ObservedObject private var notificationManager = NotificationManager.shared
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: StrainLabTheme.paddingL) {
            Spacer()

            // Header
            VStack(spacing: StrainLabTheme.paddingM) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 56, weight: .medium))
                    .foregroundStyle(StrainLabTheme.strainBlue)

                Text("Morning Recovery Alerts")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(StrainLabTheme.textPrimary)

                Text("Get your recovery score each morning to help plan your day.")
                    .font(StrainLabTheme.bodyFont)
                    .foregroundStyle(StrainLabTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, StrainLabTheme.paddingL)
            }

            // Example notification
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(StrainLabTheme.strainBlue)

                    Text("STRAINLAB")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(StrainLabTheme.textTertiary)

                    Spacer()

                    Text("now")
                        .font(.system(size: 11))
                        .foregroundStyle(StrainLabTheme.textTertiary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Recovery: 78%")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(StrainLabTheme.textPrimary)

                    Text("Great recovery — today is a good day to push harder")
                        .font(.system(size: 13))
                        .foregroundStyle(StrainLabTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
            }
            .padding(StrainLabTheme.paddingM)
            .background(StrainLabTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusM))
            .padding(.horizontal, StrainLabTheme.paddingL)

            Spacer()

            // Buttons
            VStack(spacing: StrainLabTheme.paddingM) {
                Button {
                    Task {
                        await requestNotificationPermission()
                    }
                } label: {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .tint(.white)
                        } else if notificationManager.isAuthorized {
                            Image(systemName: "checkmark")
                            Text("Notifications Enabled")
                        } else {
                            Text("Enable Notifications")
                        }
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(notificationManager.isAuthorized ? StrainLabTheme.recoveryGreen : StrainLabTheme.strainBlue)
                    .clipShape(RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusM))
                }
                .buttonStyle(.plain)
                .disabled(isRequesting || notificationManager.isAuthorized)

                Button {
                    coordinator.nextStep()
                } label: {
                    Text(notificationManager.isAuthorized ? "Continue" : "Skip for now")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(StrainLabTheme.textSecondary)
                }
            }
            .padding(.horizontal, StrainLabTheme.paddingL)
            .padding(.bottom, StrainLabTheme.paddingXL)
        }
    }

    private func requestNotificationPermission() async {
        isRequesting = true
        let _ = await notificationManager.requestAuthorization()
        await MainActor.run {
            isRequesting = false
            if notificationManager.isAuthorized {
                // Schedule default morning notification
                Task {
                    await notificationManager.scheduleMorningRecoveryNotification(hour: 7, minute: 0)
                }
            }
        }
    }
}

#Preview {
    NotificationPermissionView()
        .background(Color.black)
}
