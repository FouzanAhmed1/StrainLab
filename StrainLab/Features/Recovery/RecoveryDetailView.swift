import SwiftUI
import StrainLabKit

struct RecoveryDetailView: View {
    let score: RecoveryScore?
    @State private var showingExplanation = false

    var body: some View {
        ScrollView {
            VStack(spacing: StrainLabTheme.paddingL) {
                if let score = score {
                    scoreSection(score)
                    explanationToggle
                    if showingExplanation {
                        explanationSection
                    }
                    componentsSection(score)
                    insightsSection(score)
                } else {
                    ProgressView()
                        .frame(height: 300)
                }
            }
            .padding(.horizontal, StrainLabTheme.paddingM)
            .padding(.bottom, StrainLabTheme.paddingXL)
        }
        .strainLabBackground()
        .navigationTitle("Recovery")
        .navigationBarTitleDisplayMode(.large)
    }

    private func scoreSection(_ score: RecoveryScore) -> some View {
        VStack(spacing: StrainLabTheme.paddingM) {
            ScoreRing(
                score: score.score,
                color: score.category.color,
                lineWidth: 14,
                showLabel: true,
                label: "Recovery"
            )
            .frame(width: 200, height: 200)

            Text(score.category.displayName)
                .font(StrainLabTheme.headlineFont)
                .foregroundStyle(score.category.color)

            Text(categoryDescription(score.category))
                .font(StrainLabTheme.bodyFont)
                .foregroundStyle(StrainLabTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, StrainLabTheme.paddingM)
    }

    private var explanationToggle: some View {
        Button {
            withAnimation(StrainLabTheme.standardAnimation) {
                showingExplanation.toggle()
            }
        } label: {
            HStack {
                Image(systemName: "info.circle")
                Text("How is this calculated?")
                Spacer()
                Image(systemName: showingExplanation ? "chevron.up" : "chevron.down")
            }
            .font(StrainLabTheme.bodyFont)
            .foregroundStyle(StrainLabTheme.textSecondary)
            .padding(StrainLabTheme.paddingM)
            .background(StrainLabTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusM))
        }
    }

    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: StrainLabTheme.paddingM) {
            Text("Understanding Recovery")
                .font(StrainLabTheme.headlineFont)
                .foregroundStyle(StrainLabTheme.textPrimary)

            VStack(alignment: .leading, spacing: StrainLabTheme.paddingS) {
                ExplanationRow(
                    title: "HRV (50%)",
                    description: "Heart Rate Variability compared to your 7 day baseline. Higher HRV indicates better parasympathetic recovery."
                )

                ExplanationRow(
                    title: "Resting HR (30%)",
                    description: "Resting heart rate compared to baseline. Lower values indicate a recovered cardiovascular system."
                )

                ExplanationRow(
                    title: "Sleep Quality (20%)",
                    description: "Based on duration, efficiency, and sleep stages from last night."
                )
            }
        }
        .padding(StrainLabTheme.paddingM)
        .background(StrainLabTheme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusM))
    }

    private func componentsSection(_ score: RecoveryScore) -> some View {
        VStack(spacing: StrainLabTheme.paddingS) {
            ComponentCard(
                title: "HRV",
                currentValue: "\(Int(score.components.currentHRV)) ms",
                baselineValue: "\(Int(score.components.hrvBaseline)) ms",
                deviation: score.components.hrvDeviation,
                deviationIsGood: score.components.hrvDeviation > 0,
                icon: "waveform.path.ecg"
            )

            ComponentCard(
                title: "Resting Heart Rate",
                currentValue: "\(Int(score.components.currentRHR)) bpm",
                baselineValue: "\(Int(score.components.rhrBaseline)) bpm",
                deviation: score.components.rhrDeviation,
                deviationIsGood: score.components.rhrDeviation < 0,
                icon: "heart.fill"
            )

            ComponentCard(
                title: "Sleep Quality",
                currentValue: "\(Int(score.components.sleepQuality))%",
                icon: "moon.fill"
            )
        }
    }

    private func insightsSection(_ score: RecoveryScore) -> some View {
        VStack(alignment: .leading, spacing: StrainLabTheme.paddingS) {
            Text("INSIGHTS")
                .font(StrainLabTheme.labelFont)
                .foregroundStyle(StrainLabTheme.textTertiary)

            ForEach(Array(generateInsights(score).enumerated()), id: \.offset) { _, insight in
                InsightCard(text: insight.text, type: insight.type)
            }
        }
    }

    private func categoryDescription(_ category: RecoveryScore.Category) -> String {
        switch category {
        case .optimal:
            return "Your body is well recovered. Consider pushing harder today."
        case .moderate:
            return "Your body is moderately recovered. Listen to your body during activity."
        case .poor:
            return "Your body needs more recovery time. Consider rest or light activity."
        }
    }

    private func generateInsights(_ score: RecoveryScore) -> [(text: String, type: InsightCard.InsightType)] {
        var insights: [(String, InsightCard.InsightType)] = []

        if score.components.hrvDeviation > 10 {
            insights.append(("HRV is significantly above baseline, indicating excellent recovery.", .positive))
        } else if score.components.hrvDeviation < -10 {
            insights.append(("HRV is below baseline. Consider lighter activity.", .warning))
        }

        if score.components.rhrDeviation > 8 {
            insights.append(("Elevated resting heart rate may indicate stress or incomplete recovery.", .warning))
        } else if score.components.rhrDeviation < -5 {
            insights.append(("Lower resting heart rate is a positive recovery indicator.", .positive))
        }

        if score.components.sleepQuality >= 80 {
            insights.append(("Excellent sleep quality supported your recovery.", .positive))
        } else if score.components.sleepQuality < 60 {
            insights.append(("Sleep quality was suboptimal. Prioritize rest tonight.", .warning))
        }

        if insights.isEmpty {
            insights.append(("Recovery metrics are within normal range.", .neutral))
        }

        return insights
    }
}

struct ExplanationRow: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(StrainLabTheme.captionFont)
                .foregroundStyle(StrainLabTheme.textPrimary)

            Text(description)
                .font(StrainLabTheme.captionFont)
                .foregroundStyle(StrainLabTheme.textTertiary)
        }
    }
}

#Preview {
    NavigationStack {
        RecoveryDetailView(score: RecoveryScore(
            date: Date(),
            score: 72,
            category: .optimal,
            components: RecoveryScore.Components(
                hrvDeviation: 8.5,
                rhrDeviation: -2.1,
                sleepQuality: 78,
                hrvBaseline: 48,
                rhrBaseline: 58,
                currentHRV: 52,
                currentRHR: 57
            )
        ))
    }
}
