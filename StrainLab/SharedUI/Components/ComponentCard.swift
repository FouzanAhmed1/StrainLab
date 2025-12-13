import SwiftUI

public struct ComponentCard: View {
    let title: String
    let currentValue: String
    let baselineValue: String?
    let deviation: Double?
    let deviationIsGood: Bool
    let icon: String?

    public init(
        title: String,
        currentValue: String,
        baselineValue: String? = nil,
        deviation: Double? = nil,
        deviationIsGood: Bool = true,
        icon: String? = nil
    ) {
        self.title = title
        self.currentValue = currentValue
        self.baselineValue = baselineValue
        self.deviation = deviation
        self.deviationIsGood = deviationIsGood
        self.icon = icon
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: StrainLabTheme.paddingS) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundStyle(StrainLabTheme.textTertiary)
                }

                Text(title.uppercased())
                    .font(StrainLabTheme.labelFont)
                    .foregroundStyle(StrainLabTheme.textTertiary)
            }

            HStack(alignment: .firstTextBaseline) {
                Text(currentValue)
                    .font(StrainLabTheme.titleFont)
                    .foregroundStyle(StrainLabTheme.textPrimary)

                Spacer()

                if let deviation = deviation {
                    DeviationBadge(
                        deviation: deviation,
                        isGood: deviationIsGood
                    )
                }
            }

            if let baseline = baselineValue {
                Text("7 day avg: \(baseline)")
                    .font(StrainLabTheme.captionFont)
                    .foregroundStyle(StrainLabTheme.textTertiary)
            }
        }
        .strainLabCard()
    }
}

public struct DeviationBadge: View {
    let deviation: Double
    let isGood: Bool

    private var color: Color {
        if isGood {
            return StrainLabTheme.recoveryGreen
        } else {
            return StrainLabTheme.recoveryRed
        }
    }

    public var body: some View {
        HStack(spacing: 2) {
            Image(systemName: deviation > 0 ? "arrow.up" : "arrow.down")
                .font(.system(size: 10, weight: .bold))

            Text(String(format: "%.1f%%", abs(deviation)))
                .font(StrainLabTheme.captionFont)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}

public struct InsightCard: View {
    let text: String
    let type: InsightType

    public enum InsightType {
        case positive
        case neutral
        case warning

        var icon: String {
            switch self {
            case .positive: return "checkmark.circle.fill"
            case .neutral: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            }
        }

        var color: Color {
            switch self {
            case .positive: return StrainLabTheme.recoveryGreen
            case .neutral: return StrainLabTheme.strainBlue
            case .warning: return StrainLabTheme.recoveryYellow
            }
        }
    }

    public var body: some View {
        HStack(alignment: .top, spacing: StrainLabTheme.paddingS) {
            Image(systemName: type.icon)
                .foregroundStyle(type.color)
                .font(.system(size: 16))

            Text(text)
                .font(StrainLabTheme.bodyFont)
                .foregroundStyle(StrainLabTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(StrainLabTheme.paddingM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(type.color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusM))
    }
}

public struct StatRow: View {
    let label: String
    let value: String
    let color: Color?

    public init(label: String, value: String, color: Color? = nil) {
        self.label = label
        self.value = value
        self.color = color
    }

    public var body: some View {
        HStack {
            Text(label)
                .font(StrainLabTheme.bodyFont)
                .foregroundStyle(StrainLabTheme.textSecondary)

            Spacer()

            Text(value)
                .font(StrainLabTheme.bodyFont)
                .foregroundStyle(color ?? StrainLabTheme.textPrimary)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ComponentCard(
            title: "HRV",
            currentValue: "52 ms",
            baselineValue: "48 ms",
            deviation: 8.3,
            deviationIsGood: true,
            icon: "waveform.path.ecg"
        )

        ComponentCard(
            title: "Resting HR",
            currentValue: "58 bpm",
            baselineValue: "55 bpm",
            deviation: 5.4,
            deviationIsGood: false,
            icon: "heart.fill"
        )

        InsightCard(
            text: "Your HRV is above baseline, indicating good recovery.",
            type: .positive
        )

        InsightCard(
            text: "Consider reducing intensity today.",
            type: .warning
        )
    }
    .padding()
    .strainLabBackground()
}
