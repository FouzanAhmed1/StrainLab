import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var premiumManager = PremiumManager.shared
    @State private var selectedPlan: PremiumPlan = .yearly
    @State private var isPurchasing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: StrainLabTheme.paddingL) {
                    // Header
                    headerSection

                    // Features
                    featuresSection

                    // Pricing
                    pricingSection

                    // CTA
                    ctaSection

                    // Footer
                    footerSection
                }
                .padding(.horizontal, StrainLabTheme.paddingM)
                .padding(.bottom, StrainLabTheme.paddingXL)
            }
            .background(StrainLabTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(StrainLabTheme.textTertiary)
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: StrainLabTheme.paddingM) {
            // Premium badge
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.system(size: 24))
                Text("Premium")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
            }
            .foregroundStyle(
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )

            Text("Unlock the full potential of your training data")
                .font(StrainLabTheme.bodyFont)
                .foregroundStyle(StrainLabTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, StrainLabTheme.paddingL)
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(spacing: StrainLabTheme.paddingS) {
            FeatureRow(
                icon: "chart.line.uptrend.xyaxis",
                title: "Long-Term Trends",
                description: "14, 28, and 90-day analytics",
                color: StrainLabTheme.strainBlue
            )

            FeatureRow(
                icon: "moon.zzz.fill",
                title: "Sleep Debt Tracking",
                description: "Monitor accumulated sleep debt",
                color: StrainLabTheme.sleepPurple
            )

            FeatureRow(
                icon: "flame.fill",
                title: "Strain Guidance",
                description: "Personalized training recommendations",
                color: .orange
            )

            FeatureRow(
                icon: "eye.fill",
                title: "Deep Transparency",
                description: "See exactly how scores are calculated",
                color: StrainLabTheme.recoveryGreen
            )

            FeatureRow(
                icon: "bell.badge.fill",
                title: "Weekly Summaries",
                description: "Comprehensive weekly reports",
                color: .red
            )
        }
    }

    // MARK: - Pricing

    private var pricingSection: some View {
        VStack(spacing: StrainLabTheme.paddingM) {
            ForEach(PremiumPlan.allCases) { plan in
                PlanCard(
                    plan: plan,
                    isSelected: selectedPlan == plan,
                    onSelect: { selectedPlan = plan }
                )
            }
        }
        .padding(.top, StrainLabTheme.paddingM)
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: StrainLabTheme.paddingM) {
            Button {
                Task {
                    await purchaseSelectedPlan()
                }
            } label: {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Subscribe Now")
                    }
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusM))
            }
            .buttonStyle(.plain)
            .disabled(isPurchasing)

            Button {
                Task {
                    await restorePurchases()
                }
            } label: {
                Text("Restore Purchases")
                    .font(StrainLabTheme.captionFont)
                    .foregroundStyle(StrainLabTheme.textSecondary)
            }
        }
        .padding(.top, StrainLabTheme.paddingM)
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: StrainLabTheme.paddingS) {
            Text("Subscription automatically renews unless cancelled at least 24 hours before the end of the current period.")
                .font(.system(size: 11))
                .foregroundStyle(StrainLabTheme.textTertiary)
                .multilineTextAlignment(.center)

            HStack(spacing: StrainLabTheme.paddingL) {
                Button("Privacy Policy") {
                    // Open privacy policy
                }
                .font(.system(size: 11))
                .foregroundStyle(StrainLabTheme.textSecondary)

                Button("Terms of Use") {
                    // Open terms
                }
                .font(.system(size: 11))
                .foregroundStyle(StrainLabTheme.textSecondary)
            }
        }
        .padding(.top, StrainLabTheme.paddingM)
    }

    // MARK: - Actions

    private func purchaseSelectedPlan() async {
        isPurchasing = true
        // Simulate purchase (StoreKit implementation would go here)
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        await MainActor.run {
            premiumManager.upgradeToPremium()
            isPurchasing = false
            dismiss()
        }
    }

    private func restorePurchases() async {
        isPurchasing = true
        // Simulate restore
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await MainActor.run {
            isPurchasing = false
        }
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: StrainLabTheme.paddingM) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.15))
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

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.purple)
        }
        .padding(StrainLabTheme.paddingM)
        .background(StrainLabTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusM))
    }
}

struct PlanCard: View {
    let plan: PremiumPlan
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(plan.title)
                            .font(StrainLabTheme.headlineFont)
                            .foregroundStyle(StrainLabTheme.textPrimary)

                        if plan.isBestValue {
                            Text("BEST VALUE")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                        }
                    }

                    Text(plan.subtitle)
                        .font(StrainLabTheme.captionFont)
                        .foregroundStyle(StrainLabTheme.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(plan.price)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(StrainLabTheme.textPrimary)

                    Text(plan.period)
                        .font(StrainLabTheme.captionFont)
                        .foregroundStyle(StrainLabTheme.textTertiary)
                }
            }
            .padding(StrainLabTheme.paddingM)
            .background(isSelected ? StrainLabTheme.surfaceElevated : StrainLabTheme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusM)
                    .stroke(
                        isSelected ? Color.purple : Color.clear,
                        lineWidth: 2
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusM))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Premium Plan

enum PremiumPlan: String, CaseIterable, Identifiable {
    case yearly
    case monthly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .yearly: return "Yearly"
        case .monthly: return "Monthly"
        }
    }

    var subtitle: String {
        switch self {
        case .yearly: return "Save 40% vs monthly"
        case .monthly: return "Cancel anytime"
        }
    }

    var price: String {
        switch self {
        case .yearly: return "$49.99"
        case .monthly: return "$6.99"
        }
    }

    var period: String {
        switch self {
        case .yearly: return "per year"
        case .monthly: return "per month"
        }
    }

    var isBestValue: Bool {
        self == .yearly
    }
}

#Preview {
    PaywallView()
}
