//  PersistenceController.swift
//  SpectraCrop
//
//  Created by SpectraCrop Development Team
//  Copyright © 2026 SpectraCrop. All rights reserved.
//

import Foundation
import CoreData

// MARK: - PersistenceController

final class PersistenceController {
    
    // MARK: - Singleton
    
    static let shared = PersistenceController()
    
    // MARK: - Core Data Stack
    
    let container: NSPersistentContainer
    let context: NSManagedObjectContext
    
    // MARK: - Initialization
    
    private init() {
        container = NSPersistentContainer(name: "SpectraCrop")
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data load error: \(error.localizedDescription)")
            }
        }
        
        context = container.viewContext
        context.automaticallyMergesChangesFromParent = true
    }
    
    // MARK: - Save
    
    func save() throws {
        if context.hasChanges {
            try context.save()
        }
    }
    
    // MARK: - Reading CRUD
    
    func saveReading(_ reading: Reading) throws {
        let entity = ReadingEntity(context: context)
        entity.id = reading.id
        entity.externalId = reading.externalId
        entity.recordedAt = reading.recordedAt
        entity.syncTime = reading.syncTime
        entity.deletedTime = reading.deletedTime
        entity.readingDescription = reading.description
        entity.latitude = reading.location?.latitude ?? 0
        entity.longitude = reading.location?.longitude ?? 0
        entity.altitude = reading.altitude ?? 0
        entity.f0 = Int32(reading.f0)
        entity.fMax = Int32(reading.fMax)
        entity.timeToFMax = Int32(reading.timeToFMax)
        entity.fvDivFMax = reading.fvDivFMax
        entity.vj = reading.vj
        entity.m0 = reading.m0
        entity.pi = reading.pi
        entity.ppPredict = reading.ppPredict ?? 0
        entity.absoluteDifference = reading.absoluteDifference ?? 0
        entity.covariance = reading.covariance ?? 0
        entity.correlation = reading.correlation ?? 0
        entity.qualityFailed = reading.qualityFailed ?? false
        entity.status = reading.status.rawValue
        
        try save()
    }
    
    func updateReading(_ reading: Reading) throws {
        let request: NSFetchRequest<ReadingEntity> = ReadingEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", reading.id as CVarArg)
        
        if let entity = try context.fetch(request).first {
            entity.id = reading.id
            entity.externalId = reading.externalId
            entity.recordedAt = reading.recordedAt
            entity.syncTime = reading.syncTime
            entity.deletedTime = reading.deletedTime
            entity.readingDescription = reading.description
            entity.latitude = reading.location?.latitude ?? 0
            entity.longitude = reading.location?.longitude ?? 0
            entity.altitude = reading.altitude ?? 0
            entity.f0 = Int32(reading.f0)
            entity.fMax = Int32(reading.fMax)
            entity.timeToFMax = Int32(reading.timeToFMax)
            entity.fvDivFMax = reading.fvDivFMax
            entity.vj = reading.vj
            entity.m0 = reading.m0
            entity.pi = reading.pi
            entity.ppPredict = reading.ppPredict ?? 0
            entity.absoluteDifference = reading.absoluteDifference ?? 0
            entity.covariance = reading.covariance ?? 0
            entity.correlation = reading.correlation ?? 0
            entity.qualityFailed = reading.qualityFailed ?? false
            entity.status = reading.status.rawValue
            
            try save()
        }
    }
    
    func deleteReading(_ reading: Reading) throws {
        let request: NSFetchRequest<ReadingEntity> = ReadingEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", reading.id as CVarArg)
        
        if let entity = try context.fetch(request).first {
            context.delete(entity)
            try save()
        }
    }
    
    func fetchReadings(limit: Int, offset: Int) throws -> [Reading] {
        let request: NSFetchRequest<ReadingEntity> = ReadingEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "recordedAt", ascending: false)]
        request.fetchLimit = limit
        request.fetchOffset = offset
        
        let entities = try context.fetch(request)
        
        return entities.map { entity in
            Reading(
                id: entity.id ?? UUID(),
                externalId: entity.externalId,
                recordedAt: entity.recordedAt ?? Date(),
                syncTime: entity.syncTime,
                deletedTime: entity.deletedTime,
                description: entity.readingDescription,
                location: CLLocationCoordinate2D(latitude: entity.latitude, longitude: entity.longitude),
                altitude: entity.altitude == 0 ? nil : entity.altitude,
                f0: UInt16(entity.f0),
                fMax: UInt16(entity.fMax),
                timeToFMax: Int(entity.timeToFMax),
                fvDivFMax: entity.fvDivFMax,
                vj: entity.vj,
                m0: entity.m0,
                pi: entity.pi,
                ppPredict: entity.ppPredict == 0 ? nil : entity.ppPredict,
                absoluteDifference: entity.absoluteDifference == 0 ? nil : entity.absoluteDifference,
                covariance: entity.covariance == 0 ? nil : entity.covariance,
                correlation: entity.correlation == 0 ? nil : entity.correlation,
                qualityFailed: entity.qualityFailed,
                status: ReadingStatus(rawValue: entity.status ?? "local") ?? .local
            )
        }
    }
    
    func fetchAllReadings() throws -> [Reading] {
        let request: NSFetchRequest<ReadingEntity> = ReadingEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "recordedAt", ascending: false)]
        
        let entities = try context.fetch(request)
        
        return entities.map { entity in
            Reading(
                id: entity.id ?? UUID(),
                externalId: entity.externalId,
                recordedAt: entity.recordedAt ?? Date(),
                syncTime: entity.syncTime,
                deletedTime: entity.deletedTime,
                description: entity.readingDescription,
                location: CLLocationCoordinate2D(latitude: entity.latitude, longitude: entity.longitude),
                altitude: entity.altitude == 0 ? nil : entity.altitude,
                f0: UInt16(entity.f0),
                fMax: UInt16(entity.fMax),
                timeToFMax: Int(entity.timeToFMax),
                fvDivFMax: entity.fvDivFMax,
                vj: entity.vj,
                m0: entity.m0,
                pi: entity.pi,
                ppPredict: entity.ppPredict == 0 ? nil : entity.ppPredict,
                absoluteDifference: entity.absoluteDifference == 0 ? nil : entity.absoluteDifference,
                covariance: entity.covariance == 0 ? nil : entity.covariance,
                correlation: entity.correlation == 0 ? nil : entity.correlation,
                qualityFailed: entity.qualityFailed,
                status: ReadingStatus(rawValue: entity.status ?? "local") ?? .local
            )
        }
    }
    
    func countReadings() throws -> Int {
        let request: NSFetchRequest<ReadingEntity> = ReadingEntity.fetchRequest()
        return try context.count(for: request)
    }
    
    func deleteAllReadings() throws {
        let request: NSFetchRequest<NSFetchRequestResult> = ReadingEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        try context.execute(deleteRequest)
        try save()
    }
}

// MARK: - Core Data Model Extensions

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
