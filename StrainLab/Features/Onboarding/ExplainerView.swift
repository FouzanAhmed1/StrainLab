import SwiftUI

struct ExplainerView: View {
    @ObservedObject private var coordinator = OnboardingCoordinator.shared

    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let highlights: [(icon: String, title: String, subtitle: String)]

    var body: some View {
        VStack(spacing: StrainLabTheme.paddingL) {
            Spacer()

            // Header
            VStack(spacing: StrainLabTheme.paddingM) {
                Image(systemName: icon)
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(iconColor)

                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(StrainLabTheme.textPrimary)

                Text(description)
                    .font(StrainLabTheme.bodyFont)
                    .foregroundStyle(StrainLabTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, StrainLabTheme.paddingL)
            }

            // Highlights
            VStack(spacing: StrainLabTheme.paddingM) {
                ForEach(highlights.indices, id: \.self) { index in
                    let highlight = highlights[index]
                    HighlightRow(
                        icon: highlight.icon,
                        title: highlight.title,
                        subtitle: highlight.subtitle,
                        color: iconColor
                    )
                }
            }
            .padding(.horizontal, StrainLabTheme.paddingL)
            .padding(.top, StrainLabTheme.paddingM)

            Spacer()

            // Navigation
            HStack(spacing: StrainLabTheme.paddingM) {
                if coordinator.canGoBack {
                    Button {
                        coordinator.previousStep()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(StrainLabTheme.textSecondary)
                            .frame(width: 50, height: 50)
                            .background(StrainLabTheme.surface)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                Button {
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
            }
            .padding(.horizontal, StrainLabTheme.paddingL)
            .padding(.bottom, StrainLabTheme.paddingXL)
        }
    }
}

struct HighlightRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: StrainLabTheme.paddingM) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(StrainLabTheme.headlineFont)
                    .foregroundStyle(StrainLabTheme.textPrimary)

                Text(subtitle)
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
    ExplainerView(
        icon: "waveform.path.ecg",
        iconColor: .green,
        title: "What is StrainLab?",
        description: "StrainLab uses your Apple Watch data to calculate three key metrics.",
        highlights: [
            ("heart.fill", "Recovery", "How ready your body is"),
            ("flame.fill", "Strain", "How hard you've worked"),
            ("moon.fill", "Sleep", "Foundation of recovery")
        ]
    )
    .background(Color.black)
}
