//  SyncModels.swift
//  SpectraCrop
//
//  Created by SpectraCrop Development Team
//  Copyright © 2026 SpectraCrop. All rights reserved.
//

import Foundation

// MARK: - Sync Reading Request

struct SyncReadingsRequest: Codable {
    let readings: [ReadingDTO]
}

// MARK: - Reading DTO for API

struct ReadingDTO: Codable {
    let id: String?
    let externalId: String?
    let recordedAt: Int64?
    let syncTime: Int64?
    let deletedTime: Int64?
    let description: String?
    let longitude: Double?
    let latitude: Double?
    let altitude: Double?
    let dataBlock0: String?
    let dataBlock1: String?
    let dataBlock2: String?
    let dataBlock3: String?
    let dataBlock4: String?
    let dataBlock5: String?
    let dataBlock6: String?
    let f0: UInt16
    let fMax: UInt16
    let timeToFMax: Int
    let fvDivFMax: Double
    let vj: Double
    let m0: Double
    let pi: Double
    let ppPredict: Double?
    let absoluteDifference: Double?
    let covariance: Double?
    let correlation: Double?
    let qualityFailed: Bool?
    
    // Convert from Reading model
    init(from reading: Reading) {
        self.id = reading.id.uuidString
        self.externalId = reading.externalId
        self.recordedAt = Int64(reading.recordedAt.timeIntervalSince1970 * 1000)
        self.syncTime = reading.syncTime?.millisecondsSince1970
        self.deletedTime = reading.deletedTime?.millisecondsSince1970
        self.description = reading.description
        self.latitude = reading.location?.latitude
        self.longitude = reading.location?.longitude
        self.altitude = reading.altitude
        
        // Placeholder for data blocks (not used in current app)
        self.dataBlock0 = nil
        self.dataBlock1 = nil
        self.dataBlock2 = nil
        self.dataBlock3 = nil
        self.dataBlock4 = nil
        self.dataBlock5 = nil
        self.dataBlock6 = nil
        
        self.f0 = reading.f0
        self.fMax = reading.fMax
        self.timeToFMax = reading.timeToFMax
        self.fvDivFMax = reading.fvDivFMax
        self.vj = reading.vj
        self.m0 = reading.m0
        self.pi = reading.pi
        self.ppPredict = reading.ppPredict
        self.absoluteDifference = reading.absoluteDifference
        self.covariance = reading.covariance
        self.correlation = reading.correlation
        self.qualityFailed = reading.qualityFailed
    }
    
    // Convert to Reading model
    func toReading() -> Reading {
        let recordedAt = self.recordedAt != nil ? Date(timeIntervalSince1970: Double(self.recordedAt!) / 1000) : Date()
        let syncTime = self.syncTime != nil ? Date(timeIntervalSince1970: Double(self.syncTime!) / 1000) : nil
        let deletedTime = self.deletedTime != nil ? Date(timeIntervalSince1970: Double(self.deletedTime!) / 1000) : nil
        
        let location: CLLocationCoordinate2D? = 
            if let lat = latitude, let lon = longitude {
                CLLocationCoordinate2D(latitude: lat, longitude: lon)
            } else {
                nil
            }
        
        return Reading(
            id: UUID(uuidString: id ?? UUID().uuidString) ?? UUID(),
            externalId: externalId,
            recordedAt: recordedAt,
            syncTime: syncTime,
            deletedTime: deletedTime,
            description: description,
            location: location,
            altitude: altitude,
            f0: f0,
            fMax: fMax,
            timeToFMax: timeToFMax,
            fvDivFMax: fvDivFMax,
            vj: vj,
            m0: m0,
            pi: pi,
            ppPredict: ppPredict,
            absoluteDifference: absoluteDifference,
            covariance: covariance,
            correlation: correlation,
            qualityFailed: qualityFailed,
            status: syncTime != nil ? .synced : .local
        )
    }
}

// MARK: - Download Readings Request

struct DownloadReadingsRequest: Codable {
    let skip: Int
    let limit: Int
    let minimumModified: Int64?
}

// MARK: - Page DTO

struct PageDTO<T: Codable>: Codable {
    let items: [T]
    let totalCount: Int
    let hasMore: Bool
}

// MARK: - Sync Response

struct SyncResponse: Codable {
    let success: Bool
    let message: String?
    let uploadedCount: Int?
    let downloadedCount: Int?
}

// MARK: - API Error

struct APIError: Codable, Error {
    let code: Int
    let message: String
    let details: String?
    
    init(code: Int, message: String, details: String? = nil) {
        self.code = code
        self.message = message
        self.details = details
    }
}

// MARK: - Date Extension

extension Date {
    var millisecondsSince1970: Int64 {
        return Int64(self.timeIntervalSince1970 * 1000)
    }
    
    static func fromMilliseconds(_ milliseconds: Int64) -> Date {
        return Date(timeIntervalSince1970: Double(milliseconds) / 1000)
    }
}
