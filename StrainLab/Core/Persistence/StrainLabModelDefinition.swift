import Foundation
import CoreData

extension NSPersistentContainer {
    static func strainLabContainer() -> NSPersistentContainer {
        let model = NSManagedObjectModel()

        let heartRateSampleEntity = NSEntityDescription()
        heartRateSampleEntity.name = "CDHeartRateSample"
        heartRateSampleEntity.managedObjectClassName = "CDHeartRateSample"
        heartRateSampleEntity.properties = [
            createAttribute(name: "id", type: .UUIDAttributeType),
            createAttribute(name: "timestamp", type: .dateAttributeType),
            createAttribute(name: "beatsPerMinute", type: .doubleAttributeType),
            createAttribute(name: "source", type: .stringAttributeType)
        ]

        let hrvSampleEntity = NSEntityDescription()
        hrvSampleEntity.name = "CDHRVSample"
        hrvSampleEntity.managedObjectClassName = "CDHRVSample"
        hrvSampleEntity.properties = [
            createAttribute(name: "id", type: .UUIDAttributeType),
            createAttribute(name: "timestamp", type: .dateAttributeType),
            createAttribute(name: "sdnnMilliseconds", type: .doubleAttributeType),
            createAttribute(name: "rrIntervalsData", type: .binaryDataAttributeType, optional: true)
        ]

        let recoveryScoreEntity = NSEntityDescription()
        recoveryScoreEntity.name = "CDRecoveryScore"
        recoveryScoreEntity.managedObjectClassName = "CDRecoveryScore"
        recoveryScoreEntity.properties = [
            createAttribute(name: "id", type: .UUIDAttributeType),
            createAttribute(name: "date", type: .dateAttributeType),
            createAttribute(name: "score", type: .doubleAttributeType),
            createAttribute(name: "category", type: .stringAttributeType),
            createAttribute(name: "hrvDeviation", type: .doubleAttributeType),
            createAttribute(name: "rhrDeviation", type: .doubleAttributeType),
            createAttribute(name: "sleepQuality", type: .doubleAttributeType),
            createAttribute(name: "hrvBaseline", type: .doubleAttributeType),
            createAttribute(name: "rhrBaseline", type: .doubleAttributeType),
            createAttribute(name: "currentHRV", type: .doubleAttributeType),
            createAttribute(name: "currentRHR", type: .doubleAttributeType)
        ]

        let strainScoreEntity = NSEntityDescription()
        strainScoreEntity.name = "CDStrainScore"
        strainScoreEntity.managedObjectClassName = "CDStrainScore"
        strainScoreEntity.properties = [
            createAttribute(name: "id", type: .UUIDAttributeType),
            createAttribute(name: "date", type: .dateAttributeType),
            createAttribute(name: "score", type: .doubleAttributeType),
            createAttribute(name: "category", type: .stringAttributeType),
            createAttribute(name: "activityMinutes", type: .doubleAttributeType),
            createAttribute(name: "zone1Minutes", type: .doubleAttributeType),
            createAttribute(name: "zone2Minutes", type: .doubleAttributeType),
            createAttribute(name: "zone3Minutes", type: .doubleAttributeType),
            createAttribute(name: "zone4Minutes", type: .doubleAttributeType),
            createAttribute(name: "zone5Minutes", type: .doubleAttributeType)
        ]

        let sleepScoreEntity = NSEntityDescription()
        sleepScoreEntity.name = "CDSleepScore"
        sleepScoreEntity.managedObjectClassName = "CDSleepScore"
        sleepScoreEntity.properties = [
            createAttribute(name: "id", type: .UUIDAttributeType),
            createAttribute(name: "date", type: .dateAttributeType),
            createAttribute(name: "score", type: .doubleAttributeType),
            createAttribute(name: "durationScore", type: .doubleAttributeType),
            createAttribute(name: "efficiencyScore", type: .doubleAttributeType),
            createAttribute(name: "stageScore", type: .doubleAttributeType),
            createAttribute(name: "totalDurationMinutes", type: .doubleAttributeType),
            createAttribute(name: "sleepNeedMinutes", type: .doubleAttributeType),
            createAttribute(name: "efficiency", type: .doubleAttributeType),
            createAttribute(name: "deepSleepMinutes", type: .doubleAttributeType),
            createAttribute(name: "remSleepMinutes", type: .doubleAttributeType)
        ]

        let userBaselineEntity = NSEntityDescription()
        userBaselineEntity.name = "CDUserBaseline"
        userBaselineEntity.managedObjectClassName = "CDUserBaseline"
        userBaselineEntity.properties = [
            createAttribute(name: "id", type: .UUIDAttributeType),
            createAttribute(name: "date", type: .dateAttributeType),
            createAttribute(name: "hrvBaseline7Day", type: .doubleAttributeType),
            createAttribute(name: "rhrBaseline7Day", type: .doubleAttributeType),
            createAttribute(name: "sleepNeedMinutes", type: .doubleAttributeType),
            createAttribute(name: "maxHeartRate", type: .doubleAttributeType)
        ]

        model.entities = [
            heartRateSampleEntity,
            hrvSampleEntity,
            recoveryScoreEntity,
            strainScoreEntity,
            sleepScoreEntity,
            userBaselineEntity
        ]

        let container = NSPersistentContainer(name: "StrainLabModel", managedObjectModel: model)

        let storeURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("StrainLabModel.sqlite")

        let description = NSPersistentStoreDescription(url: storeURL)
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]

        return container
    }

    private static func createAttribute(
        name: String,
        type: NSAttributeType,
        optional: Bool = false
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        return attribute
    }
}
