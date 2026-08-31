//  DataManager.swift
//  SpectraCrop
//
//  Created by SpectraCrop Development Team
//  Copyright © 2026 SpectraCrop. All rights reserved.
//

import Foundation
import SwiftUI
import CoreData

// MARK: - DataManager Protocol

protocol DataManagerProtocol: ObservableObject {
    var readings: [Reading] { get }
    var isLoading: Bool { get }
    var isSyncing: Bool { get }
    var error: Error? { get }
    var lastSyncDate: Date? { get }
    var hasMore: Bool { get }
    
    func initialize()
    func addReading(_ reading: Reading)
    func updateReading(_ reading: Reading)
    func deleteReading(_ reading: Reading)
    func deleteReadings(_ readings: [Reading])
    func syncReadings() async
    func loadMoreReadings() async
    func refreshReadings() async
}

// MARK: - DataManager Implementation

final class DataManager: DataManagerProtocol, ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = DataManager()
    
    // MARK: - Published Properties
    
    @Published var readings: [Reading] = []
    @Published var isLoading = false
    @Published var isSyncing = false
    @Published var error: Error?
    @Published var lastSyncDate: Date?
    @Published var hasMore = true
    
    // MARK: - Private Properties
    
    private let persistenceController = PersistenceController.shared
    private var skipCount = 0
    private let pageSize = 20
    
    // MARK: - Initialization
    
    private init() {}
    
    func initialize() {
        // Load readings from local database
        loadLocalReadings()
    }
    
    private func loadLocalReadings() {
        Task {
            await MainActor.run {
                isLoading = true
            }
            
            do {
                let readings = try persistenceController.fetchReadings(limit: pageSize, offset: 0)
                await MainActor.run {
                    self.readings = readings
                    self.isLoading = false
                    self.hasMore = readings.count >= pageSize
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - CRUD Operations
    
    func addReading(_ reading: Reading) {
        Task {
            do {
                try persistenceController.saveReading(reading)
                await MainActor.run {
                    self.readings.insert(reading, at: 0)
                }
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
        }
    }
    
    func updateReading(_ reading: Reading) {
        Task {
            do {
                try persistenceController.updateReading(reading)
                await MainActor.run {
                    if let index = self.readings.firstIndex(where: { $0.id == reading.id }) {
                        self.readings[index] = reading
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
        }
    }
    
    func deleteReading(_ reading: Reading) {
        Task {
            do {
                try persistenceController.deleteReading(reading)
                await MainActor.run {
                    self.readings.removeAll { $0.id == reading.id }
                }
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
        }
    }
    
    func deleteReadings(_ readings: [Reading]) {
        Task {
            do {
                for reading in readings {
                    try persistenceController.deleteReading(reading)
                }
                await MainActor.run {
                    for reading in readings {
                        self.readings.removeAll { $0.id == reading.id }
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
        }
    }
    
    // MARK: - Sync Operations
    
    @MainActor
    func syncReadings() async {
        guard AuthManager.shared.isLoggedIn else { return }
        
        isSyncing = true
        error = nil
        
        do {
            // Upload local unsynced readings
            let unsyncedReadings = readings.filter { $0.status == .local }
            if !unsyncedReadings.isEmpty {
                let _ = try await APIClient.shared.uploadReadings(unsyncedReadings)
                
                // Mark as synced
                for reading in unsyncedReadings {
                    var updatedReading = reading
                    updatedReading.status = .synced
                    updatedReading.syncTime = Date()
                    try persistenceController.updateReading(updatedReading)
                    if let index = readings.firstIndex(where: { $0.id == reading.id }) {
                        readings[index] = updatedReading
                    }
                }
            }
            
            // Download readings from server
            let page = try await APIClient.shared.downloadReadings(
                skip: 0,
                limit: 100,
                minimumModified: lastSyncDate
            )
            
            // Process downloaded readings
            let downloadedReadings = page.items.map { $0.toReading() }
            
            for reading in downloadedReadings {
                // Check if reading already exists
                if !readings.contains(where: { $0.externalId == reading.externalId }) {
                    try persistenceController.saveReading(reading)
                    readings.append(reading)
                }
            }
            
            // Update last sync date
            lastSyncDate = Date()
            UserDefaults.standard.lastSyncDate = Date()
            
            isSyncing = false
            
        } catch {
            self.error = error
            isSyncing = false
        }
    }
    
    // MARK: - Pagination
    
    @MainActor
    func loadMoreReadings() async {
        guard hasMore, !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            let newReadings = try persistenceController.fetchReadings(
                limit: pageSize,
                offset: skipCount
            )
            
            readings.append(contentsOf: newReadings)
            skipCount += pageSize
            hasMore = newReadings.count >= pageSize
            isLoading = false
            
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    @MainActor
    func refreshReadings() async {
        skipCount = 0
        hasMore = true
        await loadLocalReadings()
    }
}

// MARK: - Mock DataManager for Testing

#if DEBUG
class MockDataManager: DataManagerProtocol, ObservableObject {
    @Published var readings: [Reading] = []
    @Published var isLoading = false
    @Published var isSyncing = false
    @Published var error: Error?
    @Published var lastSyncDate: Date?
    @Published var hasMore = false
    
    func initialize() {
        // Load mock data
        readings = (0..<10).map { index in
            Reading(
                recordedAt: Calendar.current.date(byAdding: .day, value: -index, to: Date())!,
                description: "Reading \(index + 1)",
                f0: UInt16(100 + index * 10),
                fMax: UInt16(500 + index * 20),
                timeToFMax: Int(1000 + index * 100),
                fvDivFMax: Double(0.7 + Double(index) * 0.01),
                vj: Double(1.0 + Double(index) * 0.1),
                m0: Double(2.0 + Double(index) * 0.1),
                pi: Double(3.0 + Double(index) * 0.1),
                qualityFailed: false
            )
        }
    }
    
    func addReading(_ reading: Reading) {
        readings.insert(reading, at: 0)
    }
    
    func updateReading(_ reading: Reading) {}
    
    func deleteReading(_ reading: Reading) {
        readings.removeAll { $0.id == reading.id }
    }
    
    func deleteReadings(_ readings: [Reading]) {
        readings.forEach { deleteReading($0) }
    }
    
    func syncReadings() async {}
    
    func loadMoreReadings() async {}
    
    func refreshReadings() async {}
}
#endif
