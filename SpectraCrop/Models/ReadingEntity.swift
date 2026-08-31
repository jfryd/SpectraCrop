//  ReadingEntity.swift
//  SpectraCrop
//
//  Created by SpectraCrop Development Team
//  Copyright © 2026 SpectraCrop. All rights reserved.
//

import Foundation
import CoreData

@objc(ReadingEntity)
public class ReadingEntity: NSManagedObject {

}

extension ReadingEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReadingEntity> {
        return NSFetchRequest<ReadingEntity>(entityName: "ReadingEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var externalId: String?
    @NSManaged public var recordedAt: Date?
    @NSManaged public var syncTime: Date?
    @NSManaged public var deletedTime: Date?
    @NSManaged public var readingDescription: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var altitude: Double
    @NSManaged public var f0: Int32
    @NSManaged public var fMax: Int32
    @NSManaged public var timeToFMax: Int32
    @NSManaged public var fvDivFMax: Double
    @NSManaged public var vj: Double
    @NSManaged public var m0: Double
    @NSManaged public var pi: Double
    @NSManaged public var ppPredict: Double
    @NSManaged public var absoluteDifference: Double
    @NSManaged public var covariance: Double
    @NSManaged public var correlation: Double
    @NSManaged public var qualityFailed: Bool
    @NSManaged public var status: String?
}
