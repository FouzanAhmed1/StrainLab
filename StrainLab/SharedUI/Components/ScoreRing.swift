import SwiftUI

public struct ScoreRing: View {
    let score: Double
    let maxScore: Double
    let color: Color
    let lineWidth: CGFloat
    let showLabel: Bool
    let label: String?

    @State private var animatedProgress: Double = 0

    public init(
        score: Double,
        maxScore: Double = 100,
        color: Color,
        lineWidth: CGFloat = 12,
        showLabel: Bool = true,
        label: String? = nil
    ) {
        self.score = score
        self.maxScore = maxScore
        self.color = color
        self.lineWidth = lineWidth
        self.showLabel = showLabel
        self.label = label
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(
                    color.opacity(0.15),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.4), radius: lineWidth / 2, x: 0, y: 0)

            if showLabel {
                VStack(spacing: 2) {
                    Text("\(Int(score))")
                        .font(StrainLabTheme.displayFont)
                        .foregroundStyle(StrainLabTheme.textPrimary)

                    if let label = label {
                        Text(label)
                            .font(StrainLabTheme.captionFont)
                            .foregroundStyle(StrainLabTheme.textSecondary)
                            .textCase(.uppercase)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(StrainLabTheme.ringAnimation.delay(0.1)) {
                animatedProgress = score / maxScore
            }
        }
        .onChange(of: score) { _, newValue in
            withAnimation(StrainLabTheme.springAnimation) {
                animatedProgress = newValue / maxScore
            }
        }
    }
}

public struct StrainRing: View {
    let score: Double

    @State private var animatedProgress: Double = 0

    public init(score: Double) {
        self.score = score
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(
                    StrainLabTheme.strainBlue.opacity(0.15),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    StrainLabTheme.strainBlue,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: StrainLabTheme.strainBlue.opacity(0.4), radius: 5, x: 0, y: 0)

            VStack(spacing: 2) {
                Text(String(format: "%.1f", score))
                    .font(StrainLabTheme.displaySmallFont)
                    .foregroundStyle(StrainLabTheme.textPrimary)

                Text("/ 21")
                    .font(StrainLabTheme.captionFont)
                    .foregroundStyle(StrainLabTheme.textSecondary)
            }
        }
        .onAppear {
            withAnimation(StrainLabTheme.ringAnimation.delay(0.1)) {
                animatedProgress = score / 21.0
            }
        }
        .onChange(of: score) { _, newValue in
            withAnimation(StrainLabTheme.springAnimation) {
                animatedProgress = newValue / 21.0
            }
        }
    }
}

public struct SleepBar: View {
    let score: Double
    let duration: String

    @State private var animatedProgress: Double = 0

    public var body: some View {
        VStack(alignment: .leading, spacing: StrainLabTheme.paddingS) {
            HStack {
                Text("SLEEP")
                    .font(StrainLabTheme.labelFont)
                    .foregroundStyle(StrainLabTheme.textTertiary)

                Spacer()

                Text(duration)
                    .font(StrainLabTheme.headlineFont)
                    .foregroundStyle(StrainLabTheme.textPrimary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(StrainLabTheme.sleepPurple.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(StrainLabTheme.sleepPurple)
                        .frame(width: geometry.size.width * animatedProgress)
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(Int(score))%")
                    .font(StrainLabTheme.bodyFont)
                    .foregroundStyle(StrainLabTheme.textPrimary)

                Spacer()

                Text("Performance")
                    .font(StrainLabTheme.captionFont)
                    .foregroundStyle(StrainLabTheme.textSecondary)
            }
        }
        .onAppear {
            withAnimation(StrainLabTheme.springAnimation.delay(0.2)) {
                animatedProgress = score / 100.0
            }
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        ScoreRing(score: 78, color: StrainLabTheme.recoveryGreen, label: "Recovery")
            .frame(width: 180, height: 180)

        StrainRing(score: 12.4)
            .frame(width: 140, height: 140)

        SleepBar(score: 85, duration: "7h 32m")
            .padding(.horizontal)
    }
    .padding()
    .strainLabBackground()
}
