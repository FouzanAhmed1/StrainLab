import SwiftUI
import Charts
import StrainLabKit

struct StrainDetailView: View {
    let score: StrainScore?
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
                    zoneBreakdownSection(score)
                    workoutSection(score)
                } else {
                    ProgressView()
                        .frame(height: 300)
                }
            }
            .padding(.horizontal, StrainLabTheme.paddingM)
            .padding(.bottom, StrainLabTheme.paddingXL)
        }
        .strainLabBackground()
        .navigationTitle("Strain")
        .navigationBarTitleDisplayMode(.large)
    }

    private func scoreSection(_ score: StrainScore) -> some View {
        VStack(spacing: StrainLabTheme.paddingM) {
            StrainRing(score: score.score)
                .frame(width: 180, height: 180)

            Text(score.category.displayName)
                .font(StrainLabTheme.headlineFont)
                .foregroundStyle(StrainLabTheme.strainBlue)

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
            Text("Understanding Strain")
                .font(StrainLabTheme.headlineFont)
                .foregroundStyle(StrainLabTheme.textPrimary)

            Text("Strain is calculated on a 0 to 21 scale based on time spent in different heart rate zones. Higher zones contribute exponentially more strain, reflecting the increased cardiovascular load.")
                .font(StrainLabTheme.bodyFont)
                .foregroundStyle(StrainLabTheme.textSecondary)

            VStack(alignment: .leading, spacing: StrainLabTheme.paddingXS) {
                ZoneExplanationRow(zone: 1, range: "50-60%", description: "Light warm up", weight: "0.5x")
                ZoneExplanationRow(zone: 2, range: "60-70%", description: "Fat burning", weight: "1x")
                ZoneExplanationRow(zone: 3, range: "70-80%", description: "Aerobic", weight: "2x")
                ZoneExplanationRow(zone: 4, range: "80-90%", description: "Threshold", weight: "4x")
                ZoneExplanationRow(zone: 5, range: "90-100%", description: "Max effort", weight: "8x")
            }
        }
        .padding(StrainLabTheme.paddingM)
        .background(StrainLabTheme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusM))
    }

    private func zoneBreakdownSection(_ score: StrainScore) -> some View {
        VStack(alignment: .leading, spacing: StrainLabTheme.paddingM) {
            Text("ZONE BREAKDOWN")
                .font(StrainLabTheme.labelFont)
                .foregroundStyle(StrainLabTheme.textTertiary)

            ZoneChart(zoneMinutes: score.components.zoneMinutes)

            VStack(spacing: StrainLabTheme.paddingS) {
                StatRow(label: "Total Activity", value: "\(Int(score.components.activityMinutes)) min")
                StatRow(label: "Zone 5 (Peak)", value: "\(Int(score.components.zoneMinutes.zone5)) min", color: StrainLabTheme.recoveryRed)
                StatRow(label: "Zone 4 (Hard)", value: "\(Int(score.components.zoneMinutes.zone4)) min", color: StrainLabTheme.recoveryYellow)
                StatRow(label: "Zone 3 (Moderate)", value: "\(Int(score.components.zoneMinutes.zone3)) min", color: StrainLabTheme.strainBlue)
            }
        }
        .strainLabCard()
    }

    private func workoutSection(_ score: StrainScore) -> some View {
        VStack(alignment: .leading, spacing: StrainLabTheme.paddingM) {
            Text("WORKOUTS")
                .font(StrainLabTheme.labelFont)
                .foregroundStyle(StrainLabTheme.textTertiary)

            if score.components.workoutContributions.isEmpty {
                HStack {
                    Image(systemName: "figure.run")
                        .foregroundStyle(StrainLabTheme.textTertiary)
                    Text("No workouts recorded today")
                        .font(StrainLabTheme.bodyFont)
                        .foregroundStyle(StrainLabTheme.textSecondary)
                }
                .padding(.vertical, StrainLabTheme.paddingM)
            } else {
                ForEach(score.components.workoutContributions) { workout in
                    WorkoutRow(workout: workout)
                }
            }
        }
        .strainLabCard()
    }

    private func categoryDescription(_ category: StrainScore.Category) -> String {
        switch category {
        case .light:
            return "Recovery day level activity. Good for active recovery."
        case .moderate:
            return "Moderate training load. Building fitness without overreaching."
        case .high:
            return "High training load. Ensure adequate recovery afterward."
        case .allOut:
            return "Maximum effort day. Prioritize recovery tomorrow."
        }
    }
}

struct ZoneExplanationRow: View {
    let zone: Int
    let range: String
    let description: String
    let weight: String

    var body: some View {
        HStack {
            Text("Zone \(zone)")
                .font(StrainLabTheme.captionFont)
                .foregroundStyle(zoneColor)
                .frame(width: 50, alignment: .leading)

            Text(range)
                .font(StrainLabTheme.captionFont)
                .foregroundStyle(StrainLabTheme.textSecondary)
                .frame(width: 60, alignment: .leading)

            Text(description)
                .font(StrainLabTheme.captionFont)
                .foregroundStyle(StrainLabTheme.textTertiary)

            Spacer()

            Text(weight)
                .font(StrainLabTheme.captionFont)
                .foregroundStyle(StrainLabTheme.textSecondary)
        }
    }

    private var zoneColor: Color {
        switch zone {
        case 1: return .gray
        case 2: return .blue.opacity(0.6)
        case 3: return StrainLabTheme.strainBlue
        case 4: return StrainLabTheme.recoveryYellow
        case 5: return StrainLabTheme.recoveryRed
        default: return .gray
        }
    }
}

struct ZoneChart: View {
    let zoneMinutes: StrainScore.Components.ZoneMinutes

    var body: some View {
        Chart {
            BarMark(x: .value("Zone", "Z1"), y: .value("Minutes", zoneMinutes.zone1))
                .foregroundStyle(Color.gray)
            BarMark(x: .value("Zone", "Z2"), y: .value("Minutes", zoneMinutes.zone2))
                .foregroundStyle(Color.blue.opacity(0.6))
            BarMark(x: .value("Zone", "Z3"), y: .value("Minutes", zoneMinutes.zone3))
                .foregroundStyle(StrainLabTheme.strainBlue)
            BarMark(x: .value("Zone", "Z4"), y: .value("Minutes", zoneMinutes.zone4))
                .foregroundStyle(StrainLabTheme.recoveryYellow)
            BarMark(x: .value("Zone", "Z5"), y: .value("Minutes", zoneMinutes.zone5))
                .foregroundStyle(StrainLabTheme.recoveryRed)
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .foregroundStyle(StrainLabTheme.textSecondary)
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine()
                    .foregroundStyle(StrainLabTheme.surfaceHighlight)
                AxisValueLabel()
                    .foregroundStyle(StrainLabTheme.textTertiary)
            }
        }
        .frame(height: 120)
    }
}

struct WorkoutRow: View {
    let workout: StrainScore.Components.WorkoutContribution

    var body: some View {
        HStack {
            Image(systemName: iconForActivity(workout.activityType))
                .font(.system(size: 20))
                .foregroundStyle(StrainLabTheme.strainBlue)
                .frame(width: 32)

            VStack(alignment: .leading) {
                Text(workout.activityType)
                    .font(StrainLabTheme.bodyFont)
                    .foregroundStyle(StrainLabTheme.textPrimary)

                Text("Strain: \(String(format: "%.1f", workout.strainContribution))")
                    .font(StrainLabTheme.captionFont)
                    .foregroundStyle(StrainLabTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(StrainLabTheme.textTertiary)
        }
        .padding(.vertical, StrainLabTheme.paddingS)
    }

    private func iconForActivity(_ type: String) -> String {
        switch type.lowercased() {
        case "running": return "figure.run"
        case "cycling": return "figure.outdoor.cycle"
        case "swimming": return "figure.pool.swim"
        case "strength training": return "dumbbell.fill"
        case "yoga": return "figure.yoga"
        case "hiit": return "flame.fill"
        default: return "figure.mixed.cardio"
        }
    }
}

#Preview {
    NavigationStack {
        StrainDetailView(score: StrainScore(
            date: Date(),
            score: 14.2,
            category: .high,
            components: StrainScore.Components(
                activityMinutes: 65,
                zoneMinutes: StrainScore.Components.ZoneMinutes(
                    zone1: 8, zone2: 15, zone3: 22, zone4: 14, zone5: 6
                ),
                workoutContributions: [
                    StrainScore.Components.WorkoutContribution(
                        workoutId: UUID(),
                        activityType: "Running",
                        strainContribution: 12.4
                    )
                ]
            )
        ))
    }
}
