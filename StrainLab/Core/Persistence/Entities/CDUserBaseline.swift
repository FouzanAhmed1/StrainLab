import Foundation
import CoreData

@objc(CDUserBaseline)
public class CDUserBaseline: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var hrvBaseline7Day: Double
    @NSManaged public var rhrBaseline7Day: Double
    @NSManaged public var sleepNeedMinutes: Double
    @NSManaged public var maxHeartRate: Double
}

extension CDUserBaseline {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDUserBaseline> {
        return NSFetchRequest<CDUserBaseline>(entityName: "CDUserBaseline")
    }
}
