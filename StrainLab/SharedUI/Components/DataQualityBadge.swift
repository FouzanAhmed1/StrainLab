import SwiftUI

/// Badge showing data quality/confidence level
struct DataQualityBadge: View {
    let quality: DataQuality

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(indicatorColor)
                .frame(width: 8, height: 8)

            Text(quality.confidenceLevel.rawValue)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(StrainLabTheme.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(StrainLabTheme.surface)
        .clipShape(Capsule())
    }

    private var indicatorColor: Color {
        switch quality.confidenceLevel {
        case .high:
            return StrainLabTheme.recoveryGreen
        case .moderate:
            return StrainLabTheme.recoveryYellow
        case .low:
            return StrainLabTheme.textTertiary
        }
    }
}

/// Expanded data quality view with warnings
struct DataQualityDetailView: View {
    let quality: DataQuality
    let baselineStatus: BaselineStatus?

    var body: some View {
        VStack(alignment: .leading, spacing: StrainLabTheme.paddingM) {
            // Header
            HStack {
                Text("Data Quality")
                    .font(StrainLabTheme.headlineFont)
                    .foregroundStyle(StrainLabTheme.textPrimary)

                Spacer()

                DataQualityBadge(quality: quality)
            }

            // Confidence bar
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(StrainLabTheme.surface)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(confidenceGradient)
                            .frame(width: geometry.size.width * quality.overallConfidence, height: 8)
                    }
                }
                .frame(height: 8)

                Text("\(Int(quality.overallConfidence * 100))% confidence in today's scores")
                    .font(StrainLabTheme.captionFont)
                    .foregroundStyle(StrainLabTheme.textSecondary)
            }

            // Baseline status
            if let baseline = baselineStatus {
                HStack(spacing: StrainLabTheme.paddingS) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 14))
                        .foregroundStyle(StrainLabTheme.strainBlue)

                    Text(baseline.message)
                        .font(StrainLabTheme.captionFont)
                        .foregroundStyle(StrainLabTheme.textSecondary)

                    Spacer()

                    Text("\(Int(baseline.progress * 100))%")
                        .font(StrainLabTheme.captionFont)
                        .foregroundStyle(StrainLabTheme.textTertiary)
                }
                .padding(StrainLabTheme.paddingS)
                .background(StrainLabTheme.strainBlue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusS))
            }

            // Warnings
            if !quality.warnings.isEmpty {
                VStack(alignment: .leading, spacing: StrainLabTheme.paddingXS) {
                    ForEach(quality.warnings, id: \.self) { warning in
                        HStack(spacing: StrainLabTheme.paddingS) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(StrainLabTheme.recoveryYellow)

                            Text(warning)
                                .font(StrainLabTheme.captionFont)
                                .foregroundStyle(StrainLabTheme.textSecondary)
                        }
                    }
                }
            }

            // Data availability
            HStack(spacing: StrainLabTheme.paddingL) {
                DataAvailabilityIndicator(
                    label: "HRV",
                    isAvailable: quality.hrvDataAvailable,
                    count: quality.hrvSampleCount
                )

                DataAvailabilityIndicator(
                    label: "RHR",
                    isAvailable: quality.rhrDataAvailable,
                    count: quality.rhrSampleCount
                )

                DataAvailabilityIndicator(
                    label: "Sleep",
                    isAvailable: quality.sleepDataAvailable,
                    count: nil
                )

                DataAvailabilityIndicator(
                    label: "Activity",
                    isAvailable: quality.activityDataAvailable,
                    count: nil
                )
            }
        }
        .padding(StrainLabTheme.paddingM)
        .background(StrainLabTheme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusM))
    }

    private var confidenceGradient: LinearGradient {
        LinearGradient(
            colors: [StrainLabTheme.recoveryRed, StrainLabTheme.recoveryYellow, StrainLabTheme.recoveryGreen],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

struct DataAvailabilityIndicator: View {
    let label: String
    let isAvailable: Bool
    let count: Int?

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(isAvailable ? StrainLabTheme.recoveryGreen : StrainLabTheme.textTertiary)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(StrainLabTheme.textSecondary)

            if let count = count, count > 0 {
                Text("\(count)")
                    .font(.system(size: 9))
                    .foregroundStyle(StrainLabTheme.textTertiary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        DataQualityBadge(quality: DataQuality(
            hrvDataAvailable: true,
            hrvSampleCount: 5,
            rhrDataAvailable: true,
            rhrSampleCount: 20,
            sleepDataAvailable: true,
            activityDataAvailable: true,
            baselineMaturity: 0.8,
            overallConfidence: 0.85,
            warnings: []
        ))

        DataQualityDetailView(
            quality: DataQuality(
                hrvDataAvailable: true,
                hrvSampleCount: 3,
                rhrDataAvailable: true,
                rhrSampleCount: 15,
                sleepDataAvailable: false,
                activityDataAvailable: true,
                baselineMaturity: 0.5,
                overallConfidence: 0.6,
                warnings: ["No sleep data from last night", "Still calibrating your baseline"]
            ),
            baselineStatus: BaselineStatus(
                phase: .calibrating,
                message: "Calibrating your baseline",
                progress: 0.6
            )
        )
    }
    .padding()
    .background(Color.black)
}
