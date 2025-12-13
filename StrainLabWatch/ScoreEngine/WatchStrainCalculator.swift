import Foundation
import StrainLabKit

/// Lightweight strain calculator for Apple Watch
/// Simplified version of iOS StrainScoreCalculator for real-time tracking
public struct WatchStrainCalculator: Sendable {

    // Zone weights (exponential importance for higher zones)
    private let zoneWeights: [Double] = [0.5, 1.0, 2.0, 4.0, 8.0]

    // Zone thresholds as percentage of max HR
    private let zoneThresholds: [Double] = [0.5, 0.6, 0.7, 0.8, 0.9]

    public init() {}

    /// Calculate strain score from heart rate samples
    public func calculate(
        heartRateSamples: [HeartRateSample],
        maxHeartRate: Double
    ) -> StrainScore {
        guard !heartRateSamples.isEmpty else {
            return StrainScore(
                score: 0,
                category: .light,
                date: Date(),
                components: StrainScore.Components(
                    activityMinutes: 0,
                    zoneMinutes: StrainScore.ZoneMinutes(zone1: 0, zone2: 0, zone3: 0, zone4: 0, zone5: 0),
                    workoutContributions: []
                )
            )
        }

        // Calculate zone minutes
        let zoneMinutes = calculateZoneMinutes(samples: heartRateSamples, maxHR: maxHeartRate)

        // Calculate raw strain using weighted zone formula
        let rawStrain = calculateRawStrain(zoneMinutes: zoneMinutes)

        // Convert to 0-21 scale using logarithmic function
        let strain = convertToStrainScale(rawStrain: rawStrain)

        // Calculate total activity minutes
        let activityMinutes = calculateActivityMinutes(samples: heartRateSamples)

        // Determine category
        let category = categorizeStrain(strain)

        return StrainScore(
            score: strain,
            category: category,
            date: Date(),
            components: StrainScore.Components(
                activityMinutes: activityMinutes,
                zoneMinutes: zoneMinutes,
                workoutContributions: []
            )
        )
    }

    /// Calculate real-time strain value (for live workout display)
    public func calculateLiveStrain(
        heartRateSamples: [HeartRateSample],
        maxHeartRate: Double
    ) -> Double {
        let zoneMinutes = calculateZoneMinutes(samples: heartRateSamples, maxHR: maxHeartRate)
        let rawStrain = calculateRawStrain(zoneMinutes: zoneMinutes)
        return convertToStrainScale(rawStrain: rawStrain)
    }

    // MARK: - Private Methods

    private func calculateZoneMinutes(
        samples: [HeartRateSample],
        maxHR: Double
    ) -> StrainScore.ZoneMinutes {
        var zone1: Double = 0
        var zone2: Double = 0
        var zone3: Double = 0
        var zone4: Double = 0
        var zone5: Double = 0

        // Sort samples by timestamp
        let sortedSamples = samples.sorted { $0.timestamp < $1.timestamp }

        for i in 0..<sortedSamples.count {
            let sample = sortedSamples[i]
            let hrPercent = sample.beatsPerMinute / maxHR

            // Calculate time interval (assume 1 minute if we can't calculate)
            let intervalMinutes: Double
            if i < sortedSamples.count - 1 {
                let nextSample = sortedSamples[i + 1]
                intervalMinutes = min(5, nextSample.timestamp.timeIntervalSince(sample.timestamp) / 60)
            } else {
                intervalMinutes = 1
            }

            // Assign to zone based on HR percentage
            if hrPercent >= zoneThresholds[4] {
                zone5 += intervalMinutes
            } else if hrPercent >= zoneThresholds[3] {
                zone4 += intervalMinutes
            } else if hrPercent >= zoneThresholds[2] {
                zone3 += intervalMinutes
            } else if hrPercent >= zoneThresholds[1] {
                zone2 += intervalMinutes
            } else if hrPercent >= zoneThresholds[0] {
                zone1 += intervalMinutes
            }
            // Below zone 1 doesn't contribute
        }

        return StrainScore.ZoneMinutes(
            zone1: zone1,
            zone2: zone2,
            zone3: zone3,
            zone4: zone4,
            zone5: zone5
        )
    }

    private func calculateRawStrain(zoneMinutes: StrainScore.ZoneMinutes) -> Double {
        return (zoneMinutes.zone1 * zoneWeights[0]) +
               (zoneMinutes.zone2 * zoneWeights[1]) +
               (zoneMinutes.zone3 * zoneWeights[2]) +
               (zoneMinutes.zone4 * zoneWeights[3]) +
               (zoneMinutes.zone5 * zoneWeights[4])
    }

    private func convertToStrainScale(rawStrain: Double) -> Double {
        // Logarithmic conversion: strain = 21 * (1 - exp(-rawStrain/200))
        // This provides diminishing returns at high intensities
        let strain = 21.0 * (1.0 - exp(-rawStrain / 200.0))
        return min(21, max(0, strain))
    }

    private func calculateActivityMinutes(samples: [HeartRateSample]) -> Double {
        guard samples.count >= 2 else { return 0 }

        let sortedSamples = samples.sorted { $0.timestamp < $1.timestamp }
        guard let first = sortedSamples.first, let last = sortedSamples.last else { return 0 }

        return last.timestamp.timeIntervalSince(first.timestamp) / 60
    }

    private func categorizeStrain(_ strain: Double) -> StrainScore.Category {
        if strain >= 18 {
            return .allOut
        } else if strain >= 14 {
            return .high
        } else if strain >= 10 {
            return .moderate
        } else {
            return .light
        }
    }
}
