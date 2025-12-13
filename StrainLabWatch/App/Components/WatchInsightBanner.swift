import SwiftUI
import StrainLabKit

/// Single-line insight banner for Watch display
/// Shows a concise natural language insight at the top of the screen
struct WatchInsightBanner: View {
    let insight: String?
    let confidence: DailyInsight.Confidence?

    init(insight: String?, confidence: DailyInsight.Confidence? = nil) {
        self.insight = insight
        self.confidence = confidence
    }

    init(dailyInsight: DailyInsight?) {
        self.insight = dailyInsight?.shortHeadline
        self.confidence = dailyInsight?.confidence
    }

    var body: some View {
        HStack(spacing: WatchTheme.paddingS) {
            // Confidence indicator dot
            if let confidence = confidence {
                Circle()
                    .fill(confidenceColor(confidence))
                    .frame(width: 6, height: 6)
            }

            Text(insight ?? "Sync for insights")
                .font(WatchTheme.captionFont)
                .foregroundStyle(WatchTheme.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, WatchTheme.paddingM)
        .padding(.vertical, WatchTheme.paddingS)
        .frame(maxWidth: .infinity)
        .background(WatchTheme.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: WatchTheme.cornerRadiusS))
    }

    private func confidenceColor(_ confidence: DailyInsight.Confidence) -> Color {
        switch confidence {
        case .high:
            return WatchTheme.recoveryGreen
        case .moderate:
            return WatchTheme.recoveryYellow
        case .low:
            return WatchTheme.textTertiary
        }
    }
}

// MARK: - Short Insight Banner

/// Even more compact insight text (no background)
struct WatchShortInsight: View {
    let text: String?

    var body: some View {
        Text(text ?? "Sync for insights")
            .font(WatchTheme.captionFont)
            .foregroundStyle(WatchTheme.textSecondary)
            .lineLimit(1)
            .multilineTextAlignment(.center)
    }
}

// MARK: - Preview

#Preview("Insight Banner") {
    VStack(spacing: 16) {
        WatchInsightBanner(
            insight: "HRV is strong. Push today!",
            confidence: .high
        )

        WatchInsightBanner(
            insight: "Mixed signals. Listen to body",
            confidence: .moderate
        )

        WatchInsightBanner(
            insight: "Building your baseline",
            confidence: .low
        )

        WatchShortInsight(text: "Ready to push")
    }
    .padding()
    .watchBackground()
}
