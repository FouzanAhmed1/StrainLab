import Foundation
import CoreData

@objc(CDSleepScore)
public class CDSleepScore: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var score: Double
    @NSManaged public var durationScore: Double
    @NSManaged public var efficiencyScore: Double
    @NSManaged public var stageScore: Double
    @NSManaged public var totalDurationMinutes: Double
    @NSManaged public var sleepNeedMinutes: Double
    @NSManaged public var efficiency: Double
    @NSManaged public var deepSleepMinutes: Double
    @NSManaged public var remSleepMinutes: Double
}

extension CDSleepScore {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDSleepScore> {
        return NSFetchRequest<CDSleepScore>(entityName: "CDSleepScore")
    }
}
