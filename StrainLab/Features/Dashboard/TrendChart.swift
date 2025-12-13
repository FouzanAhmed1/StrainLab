import SwiftUI
import Charts

struct TrendChart: View {
    let data: [DailyTrend]
    @State private var selectedMetric: TrendMetric = .recovery

    var body: some View {
        VStack(alignment: .leading, spacing: StrainLabTheme.paddingM) {
            HStack {
                Text("TRENDS")
                    .font(StrainLabTheme.labelFont)
                    .foregroundStyle(StrainLabTheme.textTertiary)

                Spacer()

                Picker("Metric", selection: $selectedMetric) {
                    ForEach(TrendMetric.allCases, id: \.self) { metric in
                        Text(metric.shortTitle).tag(metric)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }

            Chart {
                ForEach(data) { trend in
                    LineMark(
                        x: .value("Date", trend.date, unit: .day),
                        y: .value("Score", value(for: trend))
                    )
                    .foregroundStyle(selectedMetric.color)
                    .symbol(Circle().strokeBorder(lineWidth: 2))
                    .symbolSize(40)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", trend.date, unit: .day),
                        y: .value("Score", value(for: trend))
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [selectedMetric.color.opacity(0.3), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYScale(domain: selectedMetric.yDomain)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                        .foregroundStyle(StrainLabTheme.surfaceHighlight)
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        .foregroundStyle(StrainLabTheme.textTertiary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                        .foregroundStyle(StrainLabTheme.surfaceHighlight)
                    AxisValueLabel()
                        .foregroundStyle(StrainLabTheme.textTertiary)
                }
            }
            .frame(height: 180)

            averageRow
        }
        .strainLabCard()
    }

    private func value(for trend: DailyTrend) -> Double {
        switch selectedMetric {
        case .recovery: return trend.recoveryScore
        case .strain: return trend.strainScore
        case .sleep: return trend.sleepScore
        }
    }

    private var averageRow: some View {
        HStack {
            Text("7 day average")
                .font(StrainLabTheme.captionFont)
                .foregroundStyle(StrainLabTheme.textSecondary)

            Spacer()

            Text(formattedAverage)
                .font(StrainLabTheme.headlineFont)
                .foregroundStyle(selectedMetric.color)
        }
    }

    private var formattedAverage: String {
        let values = data.map { value(for: $0) }
        let avg = values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)

        switch selectedMetric {
        case .recovery, .sleep:
            return "\(Int(avg))%"
        case .strain:
            return String(format: "%.1f", avg)
        }
    }
}

enum TrendMetric: String, CaseIterable {
    case recovery
    case strain
    case sleep

    var shortTitle: String {
        switch self {
        case .recovery: return "Rec"
        case .strain: return "Str"
        case .sleep: return "Slp"
        }
    }

    var color: Color {
        switch self {
        case .recovery: return StrainLabTheme.recoveryGreen
        case .strain: return StrainLabTheme.strainBlue
        case .sleep: return StrainLabTheme.sleepPurple
        }
    }

    var yDomain: ClosedRange<Double> {
        switch self {
        case .recovery, .sleep: return 0...100
        case .strain: return 0...21
        }
    }
}

#Preview {
    TrendChart(data: (0..<7).reversed().map { daysAgo in
        DailyTrend(
            date: Date().daysAgo(daysAgo),
            recoveryScore: Double.random(in: 55...85),
            strainScore: Double.random(in: 8...16),
            sleepScore: Double.random(in: 60...90)
        )
    })
    .padding()
    .strainLabBackground()
}
