import SwiftUI

struct SleepGoalSetupView: View {
    @ObservedObject private var coordinator = OnboardingCoordinator.shared
    @ObservedObject private var settingsManager = SettingsManager.shared
    @State private var selectedHours: Double = 7.5

    var body: some View {
        VStack(spacing: StrainLabTheme.paddingL) {
            Spacer()

            // Header
            VStack(spacing: StrainLabTheme.paddingM) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 56, weight: .medium))
                    .foregroundStyle(StrainLabTheme.sleepPurple)

                Text("Your Sleep Goal")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(StrainLabTheme.textPrimary)

                Text("How many hours of sleep do you aim for each night?")
                    .font(StrainLabTheme.bodyFont)
                    .foregroundStyle(StrainLabTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, StrainLabTheme.paddingL)
            }

            // Sleep goal picker
            VStack(spacing: StrainLabTheme.paddingM) {
                // Display
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.1f", selectedHours))
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(StrainLabTheme.sleepPurple)

                    Text("hours")
                        .font(StrainLabTheme.headlineFont)
                        .foregroundStyle(StrainLabTheme.textSecondary)
                }

                // Slider
                Slider(value: $selectedHours, in: 5...10, step: 0.5)
                    .tint(StrainLabTheme.sleepPurple)
                    .padding(.horizontal, StrainLabTheme.paddingL)

                // Labels
                HStack {
                    Text("5h")
                        .font(StrainLabTheme.captionFont)
                        .foregroundStyle(StrainLabTheme.textTertiary)

                    Spacer()

                    Text("10h")
                        .font(StrainLabTheme.captionFont)
                        .foregroundStyle(StrainLabTheme.textTertiary)
                }
                .padding(.horizontal, StrainLabTheme.paddingL)
            }
            .padding(.vertical, StrainLabTheme.paddingL)

            // Recommendation
            HStack(spacing: StrainLabTheme.paddingS) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(StrainLabTheme.sleepPurple)

                Text(recommendationText)
                    .font(StrainLabTheme.captionFont)
                    .foregroundStyle(StrainLabTheme.textSecondary)
            }
            .padding(.horizontal, StrainLabTheme.paddingL)

            Spacer()

            // Continue button
            Button {
                settingsManager.settings.sleepNeedHours = selectedHours
                coordinator.nextStep()
            } label: {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(StrainLabTheme.strainBlue)
                    .clipShape(RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusM))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, StrainLabTheme.paddingL)
            .padding(.bottom, StrainLabTheme.paddingXL)
        }
        .onAppear {
            selectedHours = settingsManager.settings.sleepNeedHours
        }
    }

    private var recommendationText: String {
        if selectedHours < 7 {
            return "Most adults need 7-9 hours. Consider if this is enough for you."
        } else if selectedHours <= 9 {
            return "Great! This is within the recommended range for adults."
        } else {
            return "Some people need more sleep. Listen to your body."
        }
    }
}

#Preview {
    SleepGoalSetupView()
        .background(Color.black)
}
