import Foundation

/// Represents a daily readiness insight combining recovery, strain, and sleep data
public struct DailyInsight: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public let date: Date
    public let headline: String
    public let recommendation: String
    public let confidence: Confidence
    public let factors: [Factor]

    // MARK: - Confidence Level

    public enum Confidence: String, Codable, Sendable {
        case high       // All data available, clear signal
        case moderate   // Some data missing or mixed signals
        case low        // Limited data or conflicting signals

        public var displayName: String {
            switch self {
            case .high: return "High confidence"
            case .moderate: return "Moderate confidence"
            case .low: return "Limited data"
            }
        }
    }

    // MARK: - Factor

    public struct Factor: Codable, Identifiable, Sendable, Equatable {
        public let id: UUID
        public let type: FactorType
        public let status: Status
        public let description: String

        public enum FactorType: String, Codable, Sendable {
            case hrv = "HRV"
            case restingHeartRate = "Resting HR"
            case sleep = "Sleep"
            case strain = "Recent Strain"
        }

        public enum Status: String, Codable, Sendable {
            case positive
            case neutral
            case negative
        }

        public init(type: FactorType, status: Status, description: String) {
            self.id = UUID()
            self.type = type
            self.status = status
            self.description = description
        }
    }

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        headline: String,
        recommendation: String,
        confidence: Confidence,
        factors: [Factor] = []
    ) {
        self.id = id
        self.date = date
        self.headline = headline
        self.recommendation = recommendation
        self.confidence = confidence
        self.factors = factors
    }

    // MARK: - Short Form (for Watch complications)

    /// Returns a shortened version of the headline suitable for Watch display (~40 chars max)
    public var shortHeadline: String {
        if headline.count <= 40 {
            return headline
        }
        // Truncate intelligently at word boundary
        let truncated = String(headline.prefix(37))
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[..<lastSpace]) + "..."
        }
        return truncated + "..."
    }

    /// Returns a very short insight phrase for complications (~20 chars)
    public var complicationText: String {
        switch (confidence, factors.first(where: { $0.type == .hrv })?.status) {
        case (_, .positive):
            return "Ready to push"
        case (.high, .neutral):
            return "Balanced day"
        case (_, .negative):
            return "Take it easy"
        case (.low, _):
            return "Collecting data"
        default:
            return "Check readiness"
        }
    }
}

// MARK: - Preset Insights

extension DailyInsight {
    /// Default insight when no data is available
    public static var noData: DailyInsight {
        DailyInsight(
            headline: "Getting to know you",
            recommendation: "Wear your Apple Watch to start collecting data",
            confidence: .low,
            factors: []
        )
    }

    /// Insight when still calibrating baselines
    public static func calibrating(daysRemaining: Int) -> DailyInsight {
        DailyInsight(
            headline: "Building your baseline",
            recommendation: "Keep wearing your watch \(daysRemaining) more days to personalize",
            confidence: .low,
            factors: []
        )
    }

    /// Placeholder insight for previews and loading states
    public static var placeholder: DailyInsight {
        DailyInsight(
            headline: "HRV is strong and sleep was solid",
            recommendation: "Today is a good day to push harder",
            confidence: .high,
            factors: [
                Factor(type: .hrv, status: .positive, description: "HRV is 12% above your baseline"),
                Factor(type: .sleep, status: .positive, description: "Sleep was excellent (7h 45m)")
            ]
        )
    }
}
