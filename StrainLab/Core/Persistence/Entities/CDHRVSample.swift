import Foundation
import CoreData

@objc(CDHRVSample)
public class CDHRVSample: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var timestamp: Date?
    @NSManaged public var sdnnMilliseconds: Double
    @NSManaged public var rrIntervalsData: Data?
}

extension CDHRVSample {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDHRVSample> {
        return NSFetchRequest<CDHRVSample>(entityName: "CDHRVSample")
    }

    public var rrIntervals: [Double]? {
        guard let data = rrIntervalsData else { return nil }
        return try? JSONDecoder().decode([Double].self, from: data)
    }
}
