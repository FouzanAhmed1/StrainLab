import SwiftUI

struct WelcomeView: View {
    @ObservedObject private var coordinator = OnboardingCoordinator.shared

    var body: some View {
        VStack(spacing: StrainLabTheme.paddingXL) {
            Spacer()

            // App icon/logo area
            VStack(spacing: StrainLabTheme.paddingM) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [StrainLabTheme.strainBlue, StrainLabTheme.recoveryGreen],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)

                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(.white)
                }

                Text("StrainLab")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(StrainLabTheme.textPrimary)
            }

            // Tagline
            VStack(spacing: StrainLabTheme.paddingS) {
                Text("Train Smarter")
                    .font(StrainLabTheme.titleFont)
                    .foregroundStyle(StrainLabTheme.textPrimary)

                Text("Understand your body's readiness for training with recovery, strain, and sleep insights.")
                    .font(StrainLabTheme.bodyFont)
                    .foregroundStyle(StrainLabTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, StrainLabTheme.paddingL)
            }

            Spacer()

            // CTA Button
            VStack(spacing: StrainLabTheme.paddingM) {
                Button {
                    coordinator.nextStep()
                } label: {
                    Text("Get Started")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(StrainLabTheme.strainBlue)
                        .clipShape(RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusM))
                }
                .buttonStyle(.plain)

                Text("Takes about 2 minutes")
                    .font(StrainLabTheme.captionFont)
                    .foregroundStyle(StrainLabTheme.textTertiary)
            }
            .padding(.horizontal, StrainLabTheme.paddingL)
            .padding(.bottom, StrainLabTheme.paddingXL)
        }
    }
}

#Preview {
    WelcomeView()
        .background(Color.black)
}
