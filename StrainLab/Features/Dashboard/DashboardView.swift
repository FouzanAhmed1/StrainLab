import SwiftUI
import Charts
import StrainLabKit

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var selectedPeriod: TimePeriod = .today

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: StrainLabTheme.paddingL) {
                    periodPicker

                    scoreCardsSection

                    sleepSection

                    if selectedPeriod == .week {
                        trendsSection
                    }
                }
                .padding(.horizontal, StrainLabTheme.paddingM)
                .padding(.bottom, StrainLabTheme.paddingXL)
            }
            .strainLabBackground()
            .navigationTitle("StrainLab")
            .refreshable {
                await viewModel.refresh()
            }
        }
        .task {
            await viewModel.loadData()
        }
    }

    private var periodPicker: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Text(period.title).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    private var scoreCardsSection: some View {
        HStack(spacing: StrainLabTheme.paddingM) {
            NavigationLink {
                RecoveryDetailView(score: viewModel.recoveryScore)
            } label: {
                RecoveryCard(score: viewModel.recoveryScore)
            }
            .buttonStyle(.plain)

            NavigationLink {
                StrainDetailView(score: viewModel.strainScore)
            } label: {
                StrainCard(score: viewModel.strainScore)
            }
            .buttonStyle(.plain)
        }
    }

    private var sleepSection: some View {
        NavigationLink {
            SleepDetailView(score: viewModel.sleepScore)
        } label: {
            SleepCard(score: viewModel.sleepScore)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var trendsSection: some View {
        if !viewModel.weeklyTrends.isEmpty {
            TrendChart(data: viewModel.weeklyTrends)
        }
    }
}

struct RecoveryCard: View {
    let score: RecoveryScore?

    var body: some View {
        VStack(spacing: StrainLabTheme.paddingS) {
            Text("RECOVERY")
                .font(StrainLabTheme.labelFont)
                .foregroundStyle(StrainLabTheme.textTertiary)

            if let score = score {
                ScoreRing(
                    score: score.score,
                    color: score.category.color,
                    lineWidth: 10,
                    showLabel: true
                )
                .frame(width: 110, height: 110)

                Text(score.category.displayName)
                    .font(StrainLabTheme.captionFont)
                    .foregroundStyle(score.category.color)
            } else {
                ProgressView()
                    .frame(width: 110, height: 110)
                Text("Loading")
                    .font(StrainLabTheme.captionFont)
                    .foregroundStyle(StrainLabTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .strainLabCard()
    }
}

struct StrainCard: View {
    let score: StrainScore?

    var body: some View {
        VStack(spacing: StrainLabTheme.paddingS) {
            Text("STRAIN")
                .font(StrainLabTheme.labelFont)
                .foregroundStyle(StrainLabTheme.textTertiary)

            if let score = score {
                StrainRing(score: score.score)
                    .frame(width: 110, height: 110)

                Text(score.category.displayName)
                    .font(StrainLabTheme.captionFont)
                    .foregroundStyle(StrainLabTheme.strainBlue)
            } else {
                ProgressView()
                    .frame(width: 110, height: 110)
                Text("Loading")
                    .font(StrainLabTheme.captionFont)
                    .foregroundStyle(StrainLabTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .strainLabCard()
    }
}

struct SleepCard: View {
    let score: SleepScore?

    var body: some View {
        VStack(spacing: StrainLabTheme.paddingS) {
            if let score = score {
                SleepBar(
                    score: score.score,
                    duration: score.components.formattedDuration
                )
            } else {
                HStack {
                    Text("SLEEP")
                        .font(StrainLabTheme.labelFont)
                        .foregroundStyle(StrainLabTheme.textTertiary)
                    Spacer()
                    ProgressView()
                }
            }
        }
        .strainLabCard()
    }
}

enum TimePeriod: String, CaseIterable {
    case today
    case week

    var title: String {
        switch self {
        case .today: return "Today"
        case .week: return "7 Days"
        }
    }
}

#Preview {
    DashboardView()
}
