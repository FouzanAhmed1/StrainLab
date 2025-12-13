import SwiftUI
import StrainLabKit

struct HeroRecoveryCard: View {
    let score: RecoveryScore?
    let onTap: () -> Void

    @State private var animateRing = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: StrainLabTheme.paddingM) {
                // Header
                HStack {
                    Text("RECOVERY")
                        .font(StrainLabTheme.labelFont)
                        .foregroundStyle(StrainLabTheme.textTertiary)

                    Spacer()

                    if let score = score {
                        Text(score.category.displayName)
                            .font(StrainLabTheme.captionFont)
                            .foregroundStyle(score.category.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(score.category.color.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                // Large Score Ring
                if let score = score {
                    ScoreRing(
                        score: score.score,
                        color: score.category.color,
                        lineWidth: 16,
                        showLabel: true,
                        label: "Recovery"
                    )
                    .frame(width: 180, height: 180)
                } else {
                    // Loading state
                    ZStack {
                        Circle()
                            .stroke(StrainLabTheme.surface, lineWidth: 16)
                            .frame(width: 180, height: 180)

                        ProgressView()
                            .tint(StrainLabTheme.recoveryGreen)
                    }
                }

                // Quick stats
                if let score = score {
                    HStack(spacing: StrainLabTheme.paddingL) {
                        QuickStat(
                            label: "HRV",
                            value: "\(Int(score.components.currentHRV))",
                            unit: "ms",
                            trend: hrvTrend(score)
                        )

                        Divider()
                            .frame(height: 30)
                            .background(StrainLabTheme.surfaceHighlight)

                        QuickStat(
                            label: "RHR",
                            value: "\(Int(score.components.currentRHR))",
                            unit: "bpm",
                            trend: rhrTrend(score)
                        )
                    }
                }

                // Tap hint
                HStack {
                    Spacer()
                    Text("Tap for details")
                        .font(StrainLabTheme.captionFont)
                        .foregroundStyle(StrainLabTheme.textTertiary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundStyle(StrainLabTheme.textTertiary)
                }
            }
            .padding(StrainLabTheme.paddingL)
            .background(StrainLabTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusL))
        }
        .buttonStyle(.plain)
    }

    private func hrvTrend(_ score: RecoveryScore) -> QuickStat.Trend {
        let deviation = score.components.hrvDeviation
        if deviation > 5 {
            return .up
        } else if deviation < -5 {
            return .down
        }
        return .neutral
    }

    private func rhrTrend(_ score: RecoveryScore) -> QuickStat.Trend {
        let deviation = score.components.rhrDeviation
        // For RHR, lower is better
        if deviation < -3 {
            return .up // Good - lower RHR
        } else if deviation > 5 {
            return .down // Bad - higher RHR
        }
        return .neutral
    }
}

// MARK: - Quick Stat Component

struct QuickStat: View {
    let label: String
    let value: String
    let unit: String
    let trend: Trend

    enum Trend {
        case up, down, neutral

        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .neutral: return "minus"
            }
        }

        var color: Color {
            switch self {
            case .up: return StrainLabTheme.recoveryGreen
            case .down: return StrainLabTheme.recoveryRed
            case .neutral: return StrainLabTheme.textTertiary
            }
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(StrainLabTheme.captionFont)
                .foregroundStyle(StrainLabTheme.textTertiary)

            HStack(spacing: 4) {
                Text(value)
                    .font(StrainLabTheme.titleFont)
                    .foregroundStyle(StrainLabTheme.textPrimary)

                Text(unit)
                    .font(StrainLabTheme.captionFont)
                    .foregroundStyle(StrainLabTheme.textSecondary)
            }

            Image(systemName: trend.icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(trend.color)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        HeroRecoveryCard(
            score: RecoveryScore(
                date: Date(),
                score: 78,
                category: .optimal,
                components: RecoveryScore.Components(
                    hrvDeviation: 12.5,
                    rhrDeviation: -2.1,
                    sleepQuality: 82,
                    hrvBaseline: 48,
                    rhrBaseline: 58,
                    currentHRV: 54,
                    currentRHR: 57
                )
            ),
            onTap: {}
        )

        HeroRecoveryCard(score: nil, onTap: {})
    }
    .padding()
    .background(Color.black)
}
