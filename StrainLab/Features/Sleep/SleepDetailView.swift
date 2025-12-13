import SwiftUI
import Charts
import StrainLabKit

struct SleepDetailView: View {
    let score: SleepScore?
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
                    durationSection(score)
                    stagesSection(score)
                    componentsSection(score)
                } else {
                    ProgressView()
                        .frame(height: 300)
                }
            }
            .padding(.horizontal, StrainLabTheme.paddingM)
            .padding(.bottom, StrainLabTheme.paddingXL)
        }
        .strainLabBackground()
        .navigationTitle("Sleep")
        .navigationBarTitleDisplayMode(.large)
    }

    private func scoreSection(_ score: SleepScore) -> some View {
        VStack(spacing: StrainLabTheme.paddingM) {
            ScoreRing(
                score: score.score,
                color: StrainLabTheme.sleepPurple,
                lineWidth: 14,
                showLabel: true,
                label: "Performance"
            )
            .frame(width: 180, height: 180)

            Text(score.category)
                .font(StrainLabTheme.headlineFont)
                .foregroundStyle(StrainLabTheme.sleepPurple)

            Text(score.components.formattedDuration)
                .font(StrainLabTheme.titleFont)
                .foregroundStyle(StrainLabTheme.textPrimary)
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
            Text("Understanding Sleep Score")
                .font(StrainLabTheme.headlineFont)
                .foregroundStyle(StrainLabTheme.textPrimary)

            VStack(alignment: .leading, spacing: StrainLabTheme.paddingS) {
                ExplanationRow(
                    title: "Duration (40%)",
                    description: "How well you met your personalized sleep need. Optimal is 95-110% of your need."
                )

                ExplanationRow(
                    title: "Efficiency (35%)",
                    description: "Time actually asleep divided by time in bed. 90%+ is excellent."
                )

                ExplanationRow(
                    title: "Stage Quality (25%)",
                    description: "Balance of deep sleep (~20%) and REM sleep (~25%) for optimal recovery."
                )
            }
        }
        .padding(StrainLabTheme.paddingM)
        .background(StrainLabTheme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusM))
    }

    private func durationSection(_ score: SleepScore) -> some View {
        VStack(alignment: .leading, spacing: StrainLabTheme.paddingM) {
            Text("DURATION")
                .font(StrainLabTheme.labelFont)
                .foregroundStyle(StrainLabTheme.textTertiary)

            VStack(spacing: StrainLabTheme.paddingS) {
                DurationProgressBar(
                    actual: score.components.totalDurationMinutes,
                    need: score.components.sleepNeedMinutes
                )

                HStack {
                    VStack(alignment: .leading) {
                        Text("Sleep Need")
                            .font(StrainLabTheme.captionFont)
                            .foregroundStyle(StrainLabTheme.textTertiary)
                        Text(formatMinutes(score.components.sleepNeedMinutes))
                            .font(StrainLabTheme.bodyFont)
                            .foregroundStyle(StrainLabTheme.textPrimary)
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("Actual")
                            .font(StrainLabTheme.captionFont)
                            .foregroundStyle(StrainLabTheme.textTertiary)
                        Text(score.components.formattedDuration)
                            .font(StrainLabTheme.bodyFont)
                            .foregroundStyle(StrainLabTheme.sleepPurple)
                    }
                }
            }
        }
        .strainLabCard()
    }

    private func stagesSection(_ score: SleepScore) -> some View {
        VStack(alignment: .leading, spacing: StrainLabTheme.paddingM) {
            Text("SLEEP STAGES")
                .font(StrainLabTheme.labelFont)
                .foregroundStyle(StrainLabTheme.textTertiary)

            StagesChart(
                deep: score.components.deepSleepMinutes,
                rem: score.components.remSleepMinutes,
                light: score.components.totalDurationMinutes - score.components.deepSleepMinutes - score.components.remSleepMinutes
            )

            VStack(spacing: StrainLabTheme.paddingS) {
                StatRow(
                    label: "Deep Sleep",
                    value: score.components.formattedDeepSleep,
                    color: Color.indigo
                )
                StatRow(
                    label: "REM Sleep",
                    value: score.components.formattedRemSleep,
                    color: StrainLabTheme.sleepPurple
                )
                StatRow(
                    label: "Efficiency",
                    value: "\(Int(score.components.efficiency * 100))%"
                )
            }
        }
        .strainLabCard()
    }

    private func componentsSection(_ score: SleepScore) -> some View {
        VStack(alignment: .leading, spacing: StrainLabTheme.paddingS) {
            Text("SCORE BREAKDOWN")
                .font(StrainLabTheme.labelFont)
                .foregroundStyle(StrainLabTheme.textTertiary)

            ComponentScoreRow(title: "Duration", score: score.components.durationScore)
            ComponentScoreRow(title: "Efficiency", score: score.components.efficiencyScore)
            ComponentScoreRow(title: "Stage Quality", score: score.components.stageScore)
        }
        .strainLabCard()
    }

    private func formatMinutes(_ minutes: Double) -> String {
        let hours = Int(minutes / 60)
        let mins = Int(minutes.truncatingRemainder(dividingBy: 60))
        return "\(hours)h \(mins)m"
    }
}

struct DurationProgressBar: View {
    let actual: Double
    let need: Double

    private var progress: Double {
        min(actual / need, 1.2)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(StrainLabTheme.sleepPurple.opacity(0.2))

                RoundedRectangle(cornerRadius: 6)
                    .fill(StrainLabTheme.sleepPurple)
                    .frame(width: geometry.size.width * min(progress, 1.0))

                Rectangle()
                    .fill(StrainLabTheme.textPrimary)
                    .frame(width: 2, height: 20)
                    .offset(x: geometry.size.width * (1.0 / 1.2) - 1)
            }
        }
        .frame(height: 12)
    }
}

struct StagesChart: View {
    let deep: Double
    let rem: Double
    let light: Double

    private var total: Double { deep + rem + light }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                if total > 0 {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.indigo)
                        .frame(width: geometry.size.width * (deep / total))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(StrainLabTheme.sleepPurple)
                        .frame(width: geometry.size.width * (rem / total))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(StrainLabTheme.sleepPurple.opacity(0.4))
                        .frame(width: geometry.size.width * (light / total))
                }
            }
        }
        .frame(height: 24)
    }
}

struct ComponentScoreRow: View {
    let title: String
    let score: Double

    var body: some View {
        HStack {
            Text(title)
                .font(StrainLabTheme.bodyFont)
                .foregroundStyle(StrainLabTheme.textSecondary)

            Spacer()

            Text("\(Int(score))%")
                .font(StrainLabTheme.bodyFont)
                .foregroundStyle(scoreColor)
        }
    }

    private var scoreColor: Color {
        if score >= 80 {
            return StrainLabTheme.recoveryGreen
        } else if score >= 60 {
            return StrainLabTheme.recoveryYellow
        } else {
            return StrainLabTheme.recoveryRed
        }
    }
}

#Preview {
    NavigationStack {
        SleepDetailView(score: SleepScore(
            date: Date(),
            score: 82,
            components: SleepScore.Components(
                durationScore: 88,
                efficiencyScore: 85,
                stageScore: 72,
                totalDurationMinutes: 432,
                sleepNeedMinutes: 450,
                efficiency: 0.91,
                deepSleepMinutes: 62,
                remSleepMinutes: 85
            )
        ))
    }
}
