import SwiftUI

/// View modifier that gates premium features behind a paywall
struct FeatureGate: ViewModifier {
    let feature: PremiumFeature
    @ObservedObject var premiumManager = PremiumManager.shared
    @State private var showingPaywall = false

    func body(content: Content) -> some View {
        if premiumManager.requiresPremium(for: feature) {
            lockedContent
        } else {
            content
        }
    }

    private var lockedContent: some View {
        Button {
            showingPaywall = true
        } label: {
            VStack(spacing: StrainLabTheme.paddingS) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(StrainLabTheme.textTertiary)

                Text(feature.rawValue)
                    .font(StrainLabTheme.captionFont)
                    .foregroundStyle(StrainLabTheme.textSecondary)

                PremiumBadge()
            }
            .frame(maxWidth: .infinity)
            .padding(StrainLabTheme.paddingL)
            .background(StrainLabTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusM))
        }
        .sheet(isPresented: $showingPaywall) {
            // PaywallView will be added later
            Text("Premium Required")
                .font(StrainLabTheme.titleFont)
        }
    }
}

/// Small badge indicating a premium feature
struct PremiumBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 10))
            Text("Premium")
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            LinearGradient(
                colors: [Color.purple, Color.blue],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(Capsule())
    }
}

/// View modifier that shows premium badge on a feature
struct PremiumBadgeModifier: ViewModifier {
    let feature: PremiumFeature
    @ObservedObject var premiumManager = PremiumManager.shared

    func body(content: Content) -> some View {
        if premiumManager.requiresPremium(for: feature) {
            content.overlay(alignment: .topTrailing) {
                PremiumBadge()
                    .padding(8)
            }
        } else {
            content
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Gates this view behind a premium feature check
    func requiresPremium(_ feature: PremiumFeature) -> some View {
        modifier(FeatureGate(feature: feature))
    }

    /// Shows a premium badge if the feature requires premium
    func premiumBadge(for feature: PremiumFeature) -> some View {
        modifier(PremiumBadgeModifier(feature: feature))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Text("Free Feature")
            .padding()
            .background(Color.green.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 8))

        Text("Premium Feature")
            .padding()
            .background(Color.purple.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .requiresPremium(.longTermTrends)

        PremiumBadge()
    }
    .padding()
    .background(Color.black)
}
