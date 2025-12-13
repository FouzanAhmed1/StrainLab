import Foundation
import CoreData

@objc(CDRecoveryScore)
public class CDRecoveryScore: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var score: Double
    @NSManaged public var category: String?
    @NSManaged public var hrvDeviation: Double
    @NSManaged public var rhrDeviation: Double
    @NSManaged public var sleepQuality: Double
    @NSManaged public var hrvBaseline: Double
    @NSManaged public var rhrBaseline: Double
    @NSManaged public var currentHRV: Double
    @NSManaged public var currentRHR: Double
}

extension CDRecoveryScore {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDRecoveryScore> {
        return NSFetchRequest<CDRecoveryScore>(entityName: "CDRecoveryScore")
    }
}
