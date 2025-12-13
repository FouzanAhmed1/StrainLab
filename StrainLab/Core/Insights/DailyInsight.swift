import Foundation

/// Represents a daily readiness insight combining recovery, strain, and sleep data
public struct DailyInsight: Identifiable, Sendable {
    public let id: UUID
    public let date: Date
    public let headline: String
    public let recommendation: String
    public let confidence: Confidence
    public let factors: [Factor]

    public enum Confidence: String, Sendable {
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

    public struct Factor: Identifiable, Sendable {
        public let id: UUID
        public let type: FactorType
        public let status: Status
        public let description: String

        public enum FactorType: String, Sendable {
            case hrv = "HRV"
            case restingHeartRate = "Resting HR"
            case sleep = "Sleep"
            case strain = "Recent Strain"
        }

        public enum Status: Sendable {
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

    public init(
        date: Date = Date(),
        headline: String,
        recommendation: String,
        confidence: Confidence,
        factors: [Factor] = []
    ) {
        self.id = UUID()
        self.date = date
        self.headline = headline
        self.recommendation = recommendation
        self.confidence = confidence
        self.factors = factors
    }
}

// MARK: - Preset Insights

extension DailyInsight {
    /// Default insight when no data is available
    static var noData: DailyInsight {
        DailyInsight(
            headline: "Getting to know you",
            recommendation: "Wear your Apple Watch to start collecting data",
            confidence: .low,
            factors: []
        )
    }

    /// Insight when still calibrating baselines
    static func calibrating(daysRemaining: Int) -> DailyInsight {
        DailyInsight(
            headline: "Building your baseline",
            recommendation: "Keep wearing your watch — \(daysRemaining) more days to personalize",
            confidence: .low,
            factors: []
        )
    }
}
