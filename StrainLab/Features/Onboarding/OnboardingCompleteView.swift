import SwiftUI

struct OnboardingCompleteView: View {
    @ObservedObject private var coordinator = OnboardingCoordinator.shared

    var body: some View {
        VStack(spacing: StrainLabTheme.paddingXL) {
            Spacer()

            // Celebration
            VStack(spacing: StrainLabTheme.paddingL) {
                ZStack {
                    Circle()
                        .fill(StrainLabTheme.recoveryGreen.opacity(0.2))
                        .frame(width: 120, height: 120)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64, weight: .medium))
                        .foregroundStyle(StrainLabTheme.recoveryGreen)
                }

                Text("You're All Set!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(StrainLabTheme.textPrimary)

                Text("StrainLab is ready to start tracking your recovery, strain, and sleep.")
                    .font(StrainLabTheme.bodyFont)
                    .foregroundStyle(StrainLabTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, StrainLabTheme.paddingL)
            }

            // Tips
            VStack(spacing: StrainLabTheme.paddingM) {
                TipRow(
                    icon: "applewatch",
                    title: "Wear Your Watch",
                    description: "Wear it to bed for accurate overnight data"
                )

                TipRow(
                    icon: "calendar",
                    title: "Give It Time",
                    description: "Baselines improve after 7+ days of data"
                )

                TipRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Check Daily",
                    description: "Morning is the best time to see your recovery"
                )
            }
            .padding(.horizontal, StrainLabTheme.paddingL)

            Spacer()

            // Start button
            Button {
                coordinator.completeOnboarding()
            } label: {
                Text("Start Using StrainLab")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [StrainLabTheme.strainBlue, StrainLabTheme.recoveryGreen],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusM))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, StrainLabTheme.paddingL)
            .padding(.bottom, StrainLabTheme.paddingXL)
        }
    }
}

struct TipRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: StrainLabTheme.paddingM) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(StrainLabTheme.strainBlue)
                .frame(width: 40, height: 40)
                .background(StrainLabTheme.strainBlue.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(StrainLabTheme.headlineFont)
                    .foregroundStyle(StrainLabTheme.textPrimary)

                Text(description)
                    .font(StrainLabTheme.captionFont)
                    .foregroundStyle(StrainLabTheme.textSecondary)
            }

            Spacer()
        }
        .padding(StrainLabTheme.paddingM)
        .background(StrainLabTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusM))
    }
}

#Preview {
    OnboardingCompleteView()
        .background(Color.black)
}
