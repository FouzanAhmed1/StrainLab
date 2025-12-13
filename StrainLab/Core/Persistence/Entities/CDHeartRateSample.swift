import Foundation
import CoreData

@objc(CDHeartRateSample)
public class CDHeartRateSample: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var timestamp: Date?
    @NSManaged public var beatsPerMinute: Double
    @NSManaged public var source: String?
}

extension CDHeartRateSample {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDHeartRateSample> {
        return NSFetchRequest<CDHeartRateSample>(entityName: "CDHeartRateSample")
    }
}
