import SwiftUI

/// Simple 7-bar trend visualization for Watch
/// Shows historical data as vertical bars
struct WatchTrendChart: View {
    let data: [Double]
    let maxValue: Double
    let color: Color
    let barCount: Int

    init(
        data: [Double],
        maxValue: Double = 100,
        color: Color,
        barCount: Int = 7
    ) {
        self.data = data
        self.maxValue = maxValue
        self.color = color
        self.barCount = barCount
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: barSpacing(for: geometry.size.width)) {
                ForEach(normalizedData.indices, id: \.self) { index in
                    let value = normalizedData[index]
                    let isLatest = index == normalizedData.count - 1

                    RoundedRectangle(cornerRadius: 2)
                        .fill(isLatest ? color : color.opacity(0.5))
                        .frame(
                            width: barWidth(for: geometry.size.width),
                            height: max(4, CGFloat(value) * geometry.size.height)
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    /// Normalize data to 0-1 range and pad to barCount
    private var normalizedData: [Double] {
        let recentData = Array(data.suffix(barCount))

        // Pad with zeros if not enough data
        let paddedData: [Double]
        if recentData.count < barCount {
            paddedData = Array(repeating: 0.0, count: barCount - recentData.count) + recentData
        } else {
            paddedData = recentData
        }

        return paddedData.map { min(1, max(0, $0 / maxValue)) }
    }

    private func barWidth(for totalWidth: CGFloat) -> CGFloat {
        let totalSpacing = barSpacing(for: totalWidth) * CGFloat(barCount - 1)
        return (totalWidth - totalSpacing) / CGFloat(barCount)
    }

    private func barSpacing(for totalWidth: CGFloat) -> CGFloat {
        totalWidth > 100 ? 6 : 4
    }
}

// MARK: - Strain Gauge

/// Visual gauge showing current strain vs target range
struct WatchStrainGauge: View {
    let current: Double
    let targetRange: ClosedRange<Double>
    let maxValue: Double

    init(
        current: Double,
        targetRange: ClosedRange<Double>,
        maxValue: Double = 21
    ) {
        self.current = current
        self.targetRange = targetRange
        self.maxValue = maxValue
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(WatchTheme.surface)

                // Target zone highlight
                RoundedRectangle(cornerRadius: 4)
                    .fill(WatchTheme.strainBlue.opacity(0.3))
                    .frame(width: targetZoneWidth(for: geometry.size.width))
                    .offset(x: targetZoneOffset(for: geometry.size.width))

                // Current progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(progressColor)
                    .frame(width: progressWidth(for: geometry.size.width))

                // Target markers
                HStack {
                    // Min target marker
                    Rectangle()
                        .fill(WatchTheme.strainBlue)
                        .frame(width: 2, height: geometry.size.height + 4)
                        .offset(x: markerOffset(for: targetRange.lowerBound, width: geometry.size.width))

                    Spacer()
                }
            }
        }
        .frame(height: 12)
    }

    private var progressColor: Color {
        if current < targetRange.lowerBound {
            return WatchTheme.strainBlue.opacity(0.7)
        } else if current > targetRange.upperBound {
            return WatchTheme.recoveryYellow
        } else {
            return WatchTheme.recoveryGreen
        }
    }

    private func progressWidth(for totalWidth: CGFloat) -> CGFloat {
        let progress = min(1, max(0, current / maxValue))
        return totalWidth * CGFloat(progress)
    }

    private func targetZoneWidth(for totalWidth: CGFloat) -> CGFloat {
        let rangeSize = (targetRange.upperBound - targetRange.lowerBound) / maxValue
        return totalWidth * CGFloat(rangeSize)
    }

    private func targetZoneOffset(for totalWidth: CGFloat) -> CGFloat {
        let offset = targetRange.lowerBound / maxValue
        return totalWidth * CGFloat(offset)
    }

    private func markerOffset(for value: Double, width: CGFloat) -> CGFloat {
        let offset = value / maxValue
        return width * CGFloat(offset)
    }
}

// MARK: - Preview

#Preview("Trend Chart") {
    VStack(spacing: 20) {
        VStack(alignment: .leading, spacing: 4) {
            Text("7-Day Recovery")
                .font(WatchTheme.captionFont)
                .foregroundStyle(WatchTheme.textSecondary)

            WatchTrendChart(
                data: [65, 72, 68, 75, 70, 82, 78],
                color: WatchTheme.recoveryGreen
            )
            .frame(height: 40)
        }
        .padding()
        .background(WatchTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: WatchTheme.cornerRadiusM))

        VStack(alignment: .leading, spacing: 8) {
            Text("Strain Progress")
                .font(WatchTheme.captionFont)
                .foregroundStyle(WatchTheme.textSecondary)

            WatchStrainGauge(
                current: 10.5,
                targetRange: 14...18
            )

            WatchStrainGauge(
                current: 15.2,
                targetRange: 14...18
            )

            WatchStrainGauge(
                current: 19.5,
                targetRange: 14...18
            )
        }
        .padding()
        .background(WatchTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: WatchTheme.cornerRadiusM))
    }
    .padding()
    .watchBackground()
}
