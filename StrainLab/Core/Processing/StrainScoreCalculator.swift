import Foundation
import StrainLabKit

public struct StrainScoreCalculator: StrainScoreCalculating, Sendable {

    private let zoneThresholds: [Double] = [0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
    private let zoneWeights: [Double] = [0.5, 1.0, 2.0, 4.0, 8.0]

    public init() {}

    public func calculate(
        heartRateSamples: [HeartRateSample],
        maxHeartRate: Double,
        workouts: [WorkoutSession]
    ) -> StrainScore {
        guard maxHeartRate > 0 else {
            return createEmptyScore()
        }

        let zoneMinutes = calculateZoneMinutes(samples: heartRateSamples, maxHR: maxHeartRate)

        let activityMinutes = zoneMinutes.zone1 + zoneMinutes.zone2 +
                             zoneMinutes.zone3 + zoneMinutes.zone4 + zoneMinutes.zone5

        let rawStrain = (zoneMinutes.zone1 * zoneWeights[0]) +
                       (zoneMinutes.zone2 * zoneWeights[1]) +
                       (zoneMinutes.zone3 * zoneWeights[2]) +
                       (zoneMinutes.zone4 * zoneWeights[3]) +
                       (zoneMinutes.zone5 * zoneWeights[4])

        let normalizedStrain = convertToStrainScale(rawStrain)

        let workoutContributions = workouts.map { workout in
            calculateWorkoutContribution(workout: workout, maxHR: maxHeartRate)
        }

        let category = StrainScore.Category.from(score: normalizedStrain)

        return StrainScore(
            date: Date(),
            score: normalizedStrain,
            category: category,
            components: StrainScore.Components(
                activityMinutes: activityMinutes,
                zoneMinutes: zoneMinutes,
                workoutContributions: workoutContributions
            )
        )
    }

    /// Calculate time spent in each heart rate zone
    private func calculateZoneMinutes(
        samples: [HeartRateSample],
        maxHR: Double
    ) -> StrainScore.Components.ZoneMinutes {
        var zone1: Double = 0
        var zone2: Double = 0
        var zone3: Double = 0
        var zone4: Double = 0
        var zone5: Double = 0

        let sortedSamples = samples.sorted { $0.timestamp < $1.timestamp }

        for i in 0..<sortedSamples.count {
            let sample = sortedSamples[i]
            let hrPercent = sample.beatsPerMinute / maxHR

            var sampleDuration: Double = 1.0

            if i < sortedSamples.count - 1 {
                let nextSample = sortedSamples[i + 1]
                let interval = nextSample.timestamp.timeIntervalSince(sample.timestamp) / 60.0
                sampleDuration = min(interval, 5.0)
            }

            if hrPercent >= 0.9 {
                zone5 += sampleDuration
            } else if hrPercent >= 0.8 {
                zone4 += sampleDuration
            } else if hrPercent >= 0.7 {
                zone3 += sampleDuration
            } else if hrPercent >= 0.6 {
                zone2 += sampleDuration
            } else if hrPercent >= 0.5 {
                zone1 += sampleDuration
            }
        }

        return StrainScore.Components.ZoneMinutes(
            zone1: zone1,
            zone2: zone2,
            zone3: zone3,
            zone4: zone4,
            zone5: zone5
        )
    }

    /// Convert raw weighted minutes to 0-21 strain scale
    /// Uses logarithmic function for diminishing returns at higher intensities
    /// Similar to Borg scale philosophy
    private func convertToStrainScale(_ rawStrain: Double) -> Double {
        let strain = 21.0 * (1.0 - exp(-rawStrain / 200.0))
        return min(21.0, max(0, strain))
    }

    /// Calculate individual workout contribution to daily strain
    private func calculateWorkoutContribution(
        workout: WorkoutSession,
        maxHR: Double
    ) -> StrainScore.Components.WorkoutContribution {
        let zones = calculateZoneMinutes(samples: workout.heartRateSamples, maxHR: maxHR)

        let rawStrain = (zones.zone1 * zoneWeights[0]) +
                       (zones.zone2 * zoneWeights[1]) +
                       (zones.zone3 * zoneWeights[2]) +
                       (zones.zone4 * zoneWeights[3]) +
                       (zones.zone5 * zoneWeights[4])

        return StrainScore.Components.WorkoutContribution(
            workoutId: workout.id,
            activityType: workout.activityType,
            strainContribution: convertToStrainScale(rawStrain)
        )
    }

    private func createEmptyScore() -> StrainScore {
        StrainScore(
            date: Date(),
            score: 0,
            category: .light,
            components: StrainScore.Components(
                activityMinutes: 0,
                zoneMinutes: .init(zone1: 0, zone2: 0, zone3: 0, zone4: 0, zone5: 0),
                workoutContributions: []
            )
        )
    }

    /// Calculate maximum heart rate estimate using age
    /// Formula: 220 - age (Haskell formula)
    /// Alternative: 208 - (0.7 * age) (Tanaka formula, more accurate for older adults)
    public static func estimateMaxHeartRate(age: Int) -> Double {
        return Double(220 - age)
    }

    /// Get zone description for UI
    public static func zoneDescription(_ zone: Int) -> String {
        switch zone {
        case 1: return "Zone 1 (50-60%): Light activity, warm up"
        case 2: return "Zone 2 (60-70%): Fat burning, easy aerobic"
        case 3: return "Zone 3 (70-80%): Aerobic endurance"
        case 4: return "Zone 4 (80-90%): Anaerobic threshold"
        case 5: return "Zone 5 (90-100%): Maximum effort"
        default: return "Unknown zone"
        }
    }
}
