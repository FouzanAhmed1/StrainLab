import Foundation
import CoreData
import StrainLabKit

public actor CoreDataManager {
    public static let shared = CoreDataManager()

    private let container: NSPersistentContainer

    private init() {
        container = NSPersistentContainer.strainLabContainer()

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load CoreData: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    private func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }

    public func saveHeartRateSamples(_ samples: [HeartRateSample]) async throws {
        let context = newBackgroundContext()
        try await context.perform {
            for sample in samples {
                let entity = CDHeartRateSample(context: context)
                entity.id = sample.id
                entity.timestamp = sample.timestamp
                entity.beatsPerMinute = sample.beatsPerMinute
                entity.source = sample.source.rawValue
            }
            try context.save()
        }
    }

    public func saveHRVSamples(_ samples: [HRVSample]) async throws {
        let context = newBackgroundContext()
        try await context.perform {
            for sample in samples {
                let entity = CDHRVSample(context: context)
                entity.id = sample.id
                entity.timestamp = sample.timestamp
                entity.sdnnMilliseconds = sample.sdnnMilliseconds
                if let intervals = sample.rrIntervalsMs {
                    entity.rrIntervalsData = try? JSONEncoder().encode(intervals)
                }
            }
            try context.save()
        }
    }

    public func saveRecoveryScore(_ score: RecoveryScore) async throws {
        let context = newBackgroundContext()
        try await context.perform {
            let entity = CDRecoveryScore(context: context)
            entity.id = score.id
            entity.date = score.date
            entity.score = score.score
            entity.category = score.category.rawValue
            entity.hrvDeviation = score.components.hrvDeviation
            entity.rhrDeviation = score.components.rhrDeviation
            entity.sleepQuality = score.components.sleepQuality
            entity.hrvBaseline = score.components.hrvBaseline
            entity.rhrBaseline = score.components.rhrBaseline
            entity.currentHRV = score.components.currentHRV
            entity.currentRHR = score.components.currentRHR
            try context.save()
        }
    }

    public func saveStrainScore(_ score: StrainScore) async throws {
        let context = newBackgroundContext()
        try await context.perform {
            let entity = CDStrainScore(context: context)
            entity.id = score.id
            entity.date = score.date
            entity.score = score.score
            entity.category = score.category.rawValue
            entity.activityMinutes = score.components.activityMinutes
            entity.zone1Minutes = score.components.zoneMinutes.zone1
            entity.zone2Minutes = score.components.zoneMinutes.zone2
            entity.zone3Minutes = score.components.zoneMinutes.zone3
            entity.zone4Minutes = score.components.zoneMinutes.zone4
            entity.zone5Minutes = score.components.zoneMinutes.zone5
            try context.save()
        }
    }

    public func saveSleepScore(_ score: SleepScore) async throws {
        let context = newBackgroundContext()
        try await context.perform {
            let entity = CDSleepScore(context: context)
            entity.id = score.id
            entity.date = score.date
            entity.score = score.score
            entity.durationScore = score.components.durationScore
            entity.efficiencyScore = score.components.efficiencyScore
            entity.stageScore = score.components.stageScore
            entity.totalDurationMinutes = score.components.totalDurationMinutes
            entity.sleepNeedMinutes = score.components.sleepNeedMinutes
            entity.efficiency = score.components.efficiency
            entity.deepSleepMinutes = score.components.deepSleepMinutes
            entity.remSleepMinutes = score.components.remSleepMinutes
            try context.save()
        }
    }

    public func saveUserBaseline(_ baseline: UserBaseline) async throws {
        let context = newBackgroundContext()
        try await context.perform {
            let entity = CDUserBaseline(context: context)
            entity.id = baseline.id
            entity.date = baseline.date
            entity.hrvBaseline7Day = baseline.hrvBaseline7Day
            entity.rhrBaseline7Day = baseline.rhrBaseline7Day
            entity.sleepNeedMinutes = baseline.sleepNeedMinutes
            entity.maxHeartRate = baseline.maxHeartRate
            try context.save()
        }
    }

    public func fetchRecoveryScores(from startDate: Date, to endDate: Date) async throws -> [RecoveryScore] {
        let context = container.viewContext
        let request: NSFetchRequest<CDRecoveryScore> = CDRecoveryScore.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        return try await context.perform {
            let entities = try context.fetch(request)
            return entities.compactMap { entity -> RecoveryScore? in
                guard let id = entity.id,
                      let date = entity.date,
                      let categoryRaw = entity.category,
                      let category = RecoveryScore.Category(rawValue: categoryRaw) else { return nil }

                return RecoveryScore(
                    id: id,
                    date: date,
                    score: entity.score,
                    category: category,
                    components: RecoveryScore.Components(
                        hrvDeviation: entity.hrvDeviation,
                        rhrDeviation: entity.rhrDeviation,
                        sleepQuality: entity.sleepQuality,
                        hrvBaseline: entity.hrvBaseline,
                        rhrBaseline: entity.rhrBaseline,
                        currentHRV: entity.currentHRV,
                        currentRHR: entity.currentRHR
                    )
                )
            }
        }
    }

    public func fetchStrainScores(from startDate: Date, to endDate: Date) async throws -> [StrainScore] {
        let context = container.viewContext
        let request: NSFetchRequest<CDStrainScore> = CDStrainScore.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        return try await context.perform {
            let entities = try context.fetch(request)
            return entities.compactMap { entity -> StrainScore? in
                guard let id = entity.id,
                      let date = entity.date,
                      let categoryRaw = entity.category,
                      let category = StrainScore.Category(rawValue: categoryRaw) else { return nil }

                return StrainScore(
                    id: id,
                    date: date,
                    score: entity.score,
                    category: category,
                    components: StrainScore.Components(
                        activityMinutes: entity.activityMinutes,
                        zoneMinutes: StrainScore.Components.ZoneMinutes(
                            zone1: entity.zone1Minutes,
                            zone2: entity.zone2Minutes,
                            zone3: entity.zone3Minutes,
                            zone4: entity.zone4Minutes,
                            zone5: entity.zone5Minutes
                        ),
                        workoutContributions: []
                    )
                )
            }
        }
    }

    public func fetchSleepScores(from startDate: Date, to endDate: Date) async throws -> [SleepScore] {
        let context = container.viewContext
        let request: NSFetchRequest<CDSleepScore> = CDSleepScore.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        return try await context.perform {
            let entities = try context.fetch(request)
            return entities.compactMap { entity -> SleepScore? in
                guard let id = entity.id, let date = entity.date else { return nil }

                return SleepScore(
                    id: id,
                    date: date,
                    score: entity.score,
                    components: SleepScore.Components(
                        durationScore: entity.durationScore,
                        efficiencyScore: entity.efficiencyScore,
                        stageScore: entity.stageScore,
                        totalDurationMinutes: entity.totalDurationMinutes,
                        sleepNeedMinutes: entity.sleepNeedMinutes,
                        efficiency: entity.efficiency,
                        deepSleepMinutes: entity.deepSleepMinutes,
                        remSleepMinutes: entity.remSleepMinutes
                    )
                )
            }
        }
    }

    public func fetchLatestUserBaseline() async throws -> UserBaseline? {
        let context = container.viewContext
        let request: NSFetchRequest<CDUserBaseline> = CDUserBaseline.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        request.fetchLimit = 1

        return try await context.perform {
            let entities = try context.fetch(request)
            guard let entity = entities.first,
                  let id = entity.id,
                  let date = entity.date else { return nil }

            return UserBaseline(
                id: id,
                date: date,
                hrvBaseline7Day: entity.hrvBaseline7Day,
                rhrBaseline7Day: entity.rhrBaseline7Day,
                sleepNeedMinutes: entity.sleepNeedMinutes,
                maxHeartRate: entity.maxHeartRate
            )
        }
    }

    public func fetchHRVValues(days: Int) async throws -> [Double] {
        let context = container.viewContext
        let request: NSFetchRequest<CDHRVSample> = CDHRVSample.fetchRequest()
        let startDate = Date().daysAgo(days)
        request.predicate = NSPredicate(format: "timestamp >= %@", startDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]

        return try await context.perform {
            let entities = try context.fetch(request)
            return entities.map { $0.sdnnMilliseconds }
        }
    }

    public func fetchRHRValues(days: Int) async throws -> [Double] {
        let context = container.viewContext
        let request: NSFetchRequest<CDHeartRateSample> = CDHeartRateSample.fetchRequest()
        let startDate = Date().daysAgo(days)
        request.predicate = NSPredicate(format: "timestamp >= %@", startDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]

        return try await context.perform {
            let entities = try context.fetch(request)
            let lowActivitySamples = entities.filter { $0.beatsPerMinute < 80 }
            return lowActivitySamples.map { $0.beatsPerMinute }
        }
    }
}
