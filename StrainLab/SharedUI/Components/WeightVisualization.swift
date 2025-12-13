import SwiftUI

/// Shows how different factors are weighted in a calculation
struct WeightVisualization: View {
    let title: String
    let weights: [WeightItem]
    let showPercentages: Bool

    init(title: String, weights: [WeightItem], showPercentages: Bool = true) {
        self.title = title
        self.weights = weights
        self.showPercentages = showPercentages
    }

    var body: some View {
        VStack(alignment: .leading, spacing: StrainLabTheme.paddingM) {
            Text(title)
                .font(StrainLabTheme.headlineFont)
                .foregroundStyle(StrainLabTheme.textPrimary)

            // Stacked bar
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    ForEach(weights) { item in
                        Rectangle()
                            .fill(item.color)
                            .frame(width: geometry.size.width * item.weight)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .frame(height: 12)

            // Legend
            VStack(spacing: StrainLabTheme.paddingXS) {
                ForEach(weights) { item in
                    HStack(spacing: StrainLabTheme.paddingS) {
                        Circle()
                            .fill(item.color)
                            .frame(width: 8, height: 8)

                        Text(item.label)
                            .font(StrainLabTheme.captionFont)
                            .foregroundStyle(StrainLabTheme.textSecondary)

                        Spacer()

                        if showPercentages {
                            Text("\(Int(item.weight * 100))%")
                                .font(StrainLabTheme.captionFont)
                                .foregroundStyle(StrainLabTheme.textTertiary)
                        }

                        if let value = item.value {
                            Text(value)
                                .font(StrainLabTheme.captionFont)
                                .foregroundStyle(StrainLabTheme.textPrimary)
                        }
                    }
                }
            }
        }
        .padding(StrainLabTheme.paddingM)
        .background(StrainLabTheme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusM))
    }
}

struct WeightItem: Identifiable {
    let id = UUID()
    let label: String
    let weight: Double // 0-1
    let color: Color
    let value: String?

    init(label: String, weight: Double, color: Color, value: String? = nil) {
        self.label = label
        self.weight = weight
        self.color = color
        self.value = value
    }
}

/// Shows formula breakdown for transparency
struct FormulaBreakdownView: View {
    let title: String
    let components: [FormulaComponent]
    let finalScore: Double
    let finalLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: StrainLabTheme.paddingM) {
            Text(title)
                .font(StrainLabTheme.headlineFont)
                .foregroundStyle(StrainLabTheme.textPrimary)

            VStack(spacing: StrainLabTheme.paddingS) {
                ForEach(components) { component in
                    HStack {
                        Text(component.label)
                            .font(StrainLabTheme.captionFont)
                            .foregroundStyle(StrainLabTheme.textSecondary)

                        Spacer()

                        Text(component.value)
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundStyle(StrainLabTheme.textPrimary)

                        Text("× \(String(format: "%.0f%%", component.weight * 100))")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(StrainLabTheme.textTertiary)

                        Text("= \(String(format: "%.1f", component.contribution))")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundStyle(component.color)
                            .frame(width: 50, alignment: .trailing)
                    }
                }

                Divider()
                    .background(StrainLabTheme.surface)

                HStack {
                    Text(finalLabel)
                        .font(StrainLabTheme.captionFont)
                        .foregroundStyle(StrainLabTheme.textSecondary)

                    Spacer()

                    Text("\(Int(finalScore))%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(StrainLabTheme.textPrimary)
                }
            }
        }
        .padding(StrainLabTheme.paddingM)
        .background(StrainLabTheme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusM))
    }
}

struct FormulaComponent: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    let weight: Double
    let contribution: Double
    let color: Color
}

#Preview {
    VStack(spacing: 20) {
        WeightVisualization(
            title: "Recovery Score Weights",
            weights: [
                WeightItem(label: "HRV", weight: 0.35, color: StrainLabTheme.recoveryGreen, value: "52ms"),
                WeightItem(label: "Resting HR", weight: 0.25, color: StrainLabTheme.recoveryRed, value: "58bpm"),
                WeightItem(label: "Sleep", weight: 0.30, color: StrainLabTheme.sleepPurple, value: "7h 20m"),
                WeightItem(label: "Prior Strain", weight: 0.10, color: StrainLabTheme.strainBlue, value: "12.5")
            ]
        )

        FormulaBreakdownView(
            title: "How Recovery is Calculated",
            components: [
                FormulaComponent(label: "HRV Score", value: "85", weight: 0.35, contribution: 29.75, color: StrainLabTheme.recoveryGreen),
                FormulaComponent(label: "RHR Score", value: "70", weight: 0.25, contribution: 17.5, color: StrainLabTheme.recoveryRed),
                FormulaComponent(label: "Sleep Score", value: "78", weight: 0.30, contribution: 23.4, color: StrainLabTheme.sleepPurple),
                FormulaComponent(label: "Strain Factor", value: "60", weight: 0.10, contribution: 6.0, color: StrainLabTheme.strainBlue)
            ],
            finalScore: 76.65,
            finalLabel: "Total Recovery"
        )
    }
    .padding()
    .background(Color.black)
}
