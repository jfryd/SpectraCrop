//  Reading.swift
//  SpectraCrop
//
//  Created by SpectraCrop Development Team
//  Copyright © 2026 SpectraCrop. All rights reserved.
//

import Foundation
import CoreLocation
import SwiftUI

// MARK: - Reading Model

struct Reading: Identifiable, Codable, Equatable {
    let id: UUID
    var externalId: String?
    var recordedAt: Date
    var syncTime: Date?
    var deletedTime: Date?
    
    // User-provided metadata
    var description: String?
    var location: CLLocationCoordinate2D?
    var altitude: Double?
    
    // Spectral data
    var f0: UInt16
    var fMax: UInt16
    var timeToFMax: Int
    var timeToFMaxMs: Int { timeToFMax / 1000 }
    var fvDivFMax: Double
    var fvDivFMaxNormal: Int { Int((fvDivFMax / 0.85) * 100) }
    var vj: Double
    var m0: Double
    var pi: Double
    var ppPredict: Double?
    var absoluteDifference: Double?
    var covariance: Double?
    var correlation: Double?
    
    // Quality metrics
    var qualityFailed: Bool?
    var qualitySuccess: Bool { !qualityFailed! }
    
    // Computed properties
    var date: Date { recordedAt }
    var dateString: String { Formatter.date.string(from: recordedAt) }
    var timeString: String { Formatter.time.string(from: recordedAt) }
    
    // Status
    var status: ReadingStatus
    
    // Selection state (for UI)
    var isSelected: Bool = false
    
    // MARK: - Initializers
    
    init(id: UUID = UUID(),
         externalId: String? = nil,
         recordedAt: Date = Date(),
         syncTime: Date? = nil,
         deletedTime: Date? = nil,
         description: String? = nil,
         location: CLLocationCoordinate2D? = nil,
         altitude: Double? = nil,
         f0: UInt16 = 0,
         fMax: UInt16 = 0,
         timeToFMax: Int = 0,
         fvDivFMax: Double = 0,
         vj: Double = 0,
         m0: Double = 0,
         pi: Double = 0,
         ppPredict: Double? = nil,
         absoluteDifference: Double? = nil,
         covariance: Double? = nil,
         correlation: Double? = nil,
         qualityFailed: Bool? = nil,
         status: ReadingStatus = .local) {
        self.id = id
        self.externalId = externalId
        self.recordedAt = recordedAt
        self.syncTime = syncTime
        self.deletedTime = deletedTime
        self.description = description
        self.location = location
        self.altitude = altitude
        self.f0 = f0
        self.fMax = fMax
        self.timeToFMax = timeToFMax
        self.fvDivFMax = fvDivFMax
        self.vj = vj
        self.m0 = m0
        self.pi = pi
        self.ppPredict = ppPredict
        self.absoluteDifference = absoluteDifference
        self.covariance = covariance
        self.correlation = correlation
        self.qualityFailed = qualityFailed
        self.status = status
    }
    
    // MARK: - CodingKeys for backward compatibility
    
    enum CodingKeys: String, CodingKey {
        case id
        case externalId
        case recordedAt
        case syncTime
        case deletedTime
        case description
        case latitude
        case longitude
        case altitude
        case f0
        case fMax
        case timeToFMax
        case fvDivFMax
        case vj
        case m0
        case pi
        case ppPredict
        case absoluteDifference
        case covariance
        case correlation
        case qualityFailed
        case status
    }
    
    // MARK: - Decodable
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        externalId = try container.decodeIfPresent(String.self, forKey: .externalId)
        recordedAt = try container.decodeIfPresent(Date.self, forKey: .recordedAt) ?? Date()
        syncTime = try container.decodeIfPresent(Date.self, forKey: .syncTime)
        deletedTime = try container.decodeIfPresent(Date.self, forKey: .deletedTime)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        
        // Handle location from separate latitude/longitude or as coordinate
        if let latitude = try container.decodeIfPresent(Double.self, forKey: .latitude),
           let longitude = try container.decodeIfPresent(Double.self, forKey: .longitude) {
            location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        } else {
            location = nil
        }
        
        altitude = try container.decodeIfPresent(Double.self, forKey: .altitude)
        f0 = try container.decodeIfPresent(UInt16.self, forKey: .f0) ?? 0
        fMax = try container.decodeIfPresent(UInt16.self, forKey: .fMax) ?? 0
        timeToFMax = try container.decodeIfPresent(Int.self, forKey: .timeToFMax) ?? 0
        fvDivFMax = try container.decodeIfPresent(Double.self, forKey: .fvDivFMax) ?? 0
        vj = try container.decodeIfPresent(Double.self, forKey: .vj) ?? 0
        m0 = try container.decodeIfPresent(Double.self, forKey: .m0) ?? 0
        pi = try container.decodeIfPresent(Double.self, forKey: .pi) ?? 0
        ppPredict = try container.decodeIfPresent(Double.self, forKey: .ppPredict)
        absoluteDifference = try container.decodeIfPresent(Double.self, forKey: .absoluteDifference)
        covariance = try container.decodeIfPresent(Double.self, forKey: .covariance)
        correlation = try container.decodeIfPresent(Double.self, forKey: .correlation)
        qualityFailed = try container.decodeIfPresent(Bool.self, forKey: .qualityFailed)
        status = try container.decodeIfPresent(ReadingStatus.self, forKey: .status) ?? .local
    }
    
    // MARK: - Encodable
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(externalId, forKey: .externalId)
        try container.encode(recordedAt, forKey: .recordedAt)
        try container.encodeIfPresent(syncTime, forKey: .syncTime)
        try container.encodeIfPresent(deletedTime, forKey: .deletedTime)
        try container.encodeIfPresent(description, forKey: .description)
        
        // Encode location as separate latitude/longitude
        if let location = location {
            try container.encode(location.latitude, forKey: .latitude)
            try container.encode(location.longitude, forKey: .longitude)
        }
        
        try container.encodeIfPresent(altitude, forKey: .altitude)
        try container.encode(f0, forKey: .f0)
        try container.encode(fMax, forKey: .fMax)
        try container.encode(timeToFMax, forKey: .timeToFMax)
        try container.encode(fvDivFMax, forKey: .fvDivFMax)
        try container.encode(vj, forKey: .vj)
        try container.encode(m0, forKey: .m0)
        try container.encode(pi, forKey: .pi)
        try container.encodeIfPresent(ppPredict, forKey: .ppPredict)
        try container.encodeIfPresent(absoluteDifference, forKey: .absoluteDifference)
        try container.encodeIfPresent(covariance, forKey: .covariance)
        try container.encodeIfPresent(correlation, forKey: .correlation)
        try container.encodeIfPresent(qualityFailed, forKey: .qualityFailed)
        try container.encode(status, forKey: .status)
    }
}

// MARK: - Reading Status

enum ReadingStatus: String, Codable {
    case local       // Only on this device
    case synced      // Synced to server
    case syncing     // Currently syncing
    case error       // Sync error
    case deleted     // Deleted
}

// MARK: - Reading Thresholds (from original app)

enum ReadingThresholds {
    static let lowFvDivFMaxNormal: Int = 50
    static let midFvDivFMaxNormal: Int = 80
    static let validTimeToFMax: Int = 700000
    static let validFvDivFMax: Double = 0.68
    static let validAbsoluteDifference: Double = 120
    static let validCorrelation: Double = 0.99
    static let maxFvDivFmax: Double = 0.86
}

// MARK: - Quality Check

extension Reading {
    func checkQuality() -> Bool {
        guard let correlation = correlation else { return false }
        guard let absoluteDifference = absoluteDifference else { return false }
        
        let timeCheck = timeToFMax <= ReadingThresholds.validTimeToFMax
        let fvCheck = fvDivFMax >= ReadingThresholds.validFvDivFMax
        let diffCheck = absoluteDifference <= ReadingThresholds.validAbsoluteDifference
        let corrCheck = correlation >= ReadingThresholds.validCorrelation
        
        return timeCheck && fvCheck && diffCheck && corrCheck
    }
    
    var qualityColor: Color {
        if qualitySuccess {
            return .green
        } else if qualityFailed == true {
            return .red
        } else {
            return .orange
        }
    }
}

// MARK: - Formatter

private enum Formatter {
    static let date: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}
