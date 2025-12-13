import SwiftUI

struct InsightCardView: View {
    let insight: DailyInsight
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: StrainLabTheme.paddingS) {
            // Main insight content
            VStack(alignment: .leading, spacing: StrainLabTheme.paddingXS) {
                Text(insight.headline)
                    .font(StrainLabTheme.headlineFont)
                    .foregroundStyle(StrainLabTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(insight.recommendation)
                    .font(StrainLabTheme.bodyFont)
                    .foregroundStyle(recommendationColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Confidence indicator and expand button
            HStack {
                ConfidenceBadge(confidence: insight.confidence)

                Spacer()

                if !insight.factors.isEmpty {
                    Button {
                        withAnimation(StrainLabTheme.standardAnimation) {
                            isExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(isExpanded ? "Less" : "Details")
                                .font(StrainLabTheme.captionFont)
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(StrainLabTheme.textTertiary)
                    }
                }
            }

            // Expanded factors
            if isExpanded && !insight.factors.isEmpty {
                VStack(alignment: .leading, spacing: StrainLabTheme.paddingXS) {
                    ForEach(insight.factors) { factor in
                        FactorRow(factor: factor)
                    }
                }
                .padding(.top, StrainLabTheme.paddingXS)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(StrainLabTheme.paddingM)
        .background(StrainLabTheme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusM))
    }

    private var recommendationColor: Color {
        // Color based on positive vs negative tone
        if insight.recommendation.lowercased().contains("push") ||
           insight.recommendation.lowercased().contains("great") ||
           insight.recommendation.lowercased().contains("good day") {
            return StrainLabTheme.recoveryGreen
        } else if insight.recommendation.lowercased().contains("rest") ||
                  insight.recommendation.lowercased().contains("recovery") ||
                  insight.recommendation.lowercased().contains("prioritize") {
            return StrainLabTheme.recoveryYellow
        }
        return StrainLabTheme.textSecondary
    }
}

// MARK: - Supporting Views

struct ConfidenceBadge: View {
    let confidence: DailyInsight.Confidence

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(badgeColor)
                .frame(width: 6, height: 6)

            Text(confidence.displayName)
                .font(StrainLabTheme.captionFont)
                .foregroundStyle(StrainLabTheme.textTertiary)
        }
    }

    private var badgeColor: Color {
        switch confidence {
        case .high:
            return StrainLabTheme.recoveryGreen
        case .moderate:
            return StrainLabTheme.recoveryYellow
        case .low:
            return StrainLabTheme.textTertiary
        }
    }
}

struct FactorRow: View {
    let factor: DailyInsight.Factor

    var body: some View {
        HStack(spacing: StrainLabTheme.paddingS) {
            Image(systemName: iconName)
                .font(.system(size: 12))
                .foregroundStyle(statusColor)
                .frame(width: 16)

            Text(factor.description)
                .font(StrainLabTheme.captionFont)
                .foregroundStyle(StrainLabTheme.textSecondary)

            Spacer()
        }
    }

    private var iconName: String {
        switch factor.status {
        case .positive:
            return "arrow.up.circle.fill"
        case .neutral:
            return "minus.circle.fill"
        case .negative:
            return "arrow.down.circle.fill"
        }
    }

    private var statusColor: Color {
        switch factor.status {
        case .positive:
            return StrainLabTheme.recoveryGreen
        case .neutral:
            return StrainLabTheme.textTertiary
        case .negative:
            return StrainLabTheme.recoveryRed
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        InsightCardView(insight: DailyInsight(
            headline: "HRV is strong and sleep was solid",
            recommendation: "Today is a good day to push harder",
            confidence: .high,
            factors: [
                .init(type: .hrv, status: .positive, description: "HRV is 15% above your baseline"),
                .init(type: .sleep, status: .positive, description: "Sleep was excellent (7h 42m)"),
                .init(type: .restingHeartRate, status: .neutral, description: "Resting HR is normal"),
                .init(type: .strain, status: .positive, description: "Light strain yesterday")
            ]
        ))

        InsightCardView(insight: DailyInsight(
            headline: "Your body needs more recovery time",
            recommendation: "Prioritize recovery today",
            confidence: .moderate,
            factors: [
                .init(type: .hrv, status: .negative, description: "HRV is 12% below your baseline"),
                .init(type: .sleep, status: .negative, description: "Sleep was insufficient (5h 20m)")
            ]
        ))

        InsightCardView(insight: .noData)
    }
    .padding()
    .background(Color.black)
}
