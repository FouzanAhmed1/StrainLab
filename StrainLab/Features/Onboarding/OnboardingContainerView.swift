import SwiftUI

/// Container view that manages the onboarding flow
struct OnboardingContainerView: View {
    @StateObject private var coordinator = OnboardingCoordinator.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            StrainLabTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                if coordinator.currentStep != .welcome && coordinator.currentStep != .done {
                    progressBar
                        .padding(.top, 8)
                }

                // Content
                TabView(selection: $coordinator.currentStep) {
                    ForEach(OnboardingStep.allCases, id: \.self) { step in
                        stepView(for: step)
                            .tag(step)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: coordinator.currentStep)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(StrainLabTheme.surface)
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 2)
                    .fill(StrainLabTheme.strainBlue)
                    .frame(width: geometry.size.width * coordinator.progress, height: 4)
                    .animation(.easeInOut(duration: 0.3), value: coordinator.progress)
            }
        }
        .frame(height: 4)
        .padding(.horizontal, StrainLabTheme.paddingL)
    }

    @ViewBuilder
    private func stepView(for step: OnboardingStep) -> some View {
        switch step {
        case .welcome:
            WelcomeView()
        case .whatIsStrainLab:
            ExplainerView(
                icon: "waveform.path.ecg",
                iconColor: StrainLabTheme.recoveryGreen,
                title: "What is StrainLab?",
                description: "StrainLab uses your Apple Watch data to calculate three key metrics that help you understand your body's readiness for training.",
                highlights: [
                    ("heart.fill", "Recovery", "How ready your body is today"),
                    ("flame.fill", "Strain", "How hard you've worked"),
                    ("moon.fill", "Sleep", "Foundation of recovery")
                ]
            )
        case .whatItIsNot:
            ExplainerView(
                icon: "exclamationmark.triangle.fill",
                iconColor: StrainLabTheme.recoveryYellow,
                title: "What it's NOT",
                description: "StrainLab provides insights to help inform your training decisions, but it's not a replacement for professional medical advice.",
                highlights: [
                    ("cross.case.fill", "Not Medical Advice", "Always consult healthcare providers"),
                    ("gauge.medium", "Not Perfect", "Scores are estimates based on available data"),
                    ("person.fill.questionmark", "Not Prescriptive", "You know your body best")
                ]
            )
        case .howItWorks:
            ExplainerView(
                icon: "gearshape.2.fill",
                iconColor: StrainLabTheme.strainBlue,
                title: "How it Works",
                description: "We analyze your heart rate variability, resting heart rate, and sleep data to calculate personalized scores.",
                highlights: [
                    ("chart.line.uptrend.xyaxis", "Personal Baselines", "Scores adapt to your unique physiology"),
                    ("clock.fill", "Overnight Data", "Wear your Watch to bed for best results"),
                    ("calendar", "7+ Days", "More data = more accurate baselines")
                ]
            )
        case .healthKitPermission:
            HealthKitPermissionView()
        case .notificationPermission:
            NotificationPermissionView()
        case .sleepGoal:
            SleepGoalSetupView()
        case .done:
            OnboardingCompleteView()
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingContainerView()
}
