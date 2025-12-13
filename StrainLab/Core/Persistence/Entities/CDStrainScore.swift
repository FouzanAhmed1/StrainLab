import Foundation
import CoreData

@objc(CDStrainScore)
public class CDStrainScore: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var score: Double
    @NSManaged public var category: String?
    @NSManaged public var activityMinutes: Double
    @NSManaged public var zone1Minutes: Double
    @NSManaged public var zone2Minutes: Double
    @NSManaged public var zone3Minutes: Double
    @NSManaged public var zone4Minutes: Double
    @NSManaged public var zone5Minutes: Double
}

extension CDStrainScore {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDStrainScore> {
        return NSFetchRequest<CDStrainScore>(entityName: "CDStrainScore")
    }
}
