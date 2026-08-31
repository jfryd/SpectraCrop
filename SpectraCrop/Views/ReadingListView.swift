//  ReadingListView.swift
//  SpectraCrop
//
//  Created by SpectraCrop Development Team
//  Copyright © 2026 SpectraCrop. All rights reserved.
//

import SwiftUI
import CoreLocation

// MARK: - ReadingListView

struct ReadingListView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authManager: AuthManager
    @State private var searchText = ""
    @State private var selectedReadings = Set<UUID>()
    @State private var isShowingDeleteAlert = false
    @State private var isShowingFilter = false
    @State private var sortOrder: ReadingSort = .dateNewest
    
    var body: some View {
        List {
            // Sync Section
            if authManager.isLoggedIn {
                SyncSection()
            }
            
            // Readings List
            ForEach(filteredReadings) { reading in
                ReadingRowView(
                    reading: reading,
                    isSelected: selectedReadings.contains(reading.id)
                )
                .onTapGesture {
                    toggleSelection(for: reading)
                }
            }
            
            // Load More
            if dataManager.hasMore {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .onAppear {
                        Task {
                            await dataManager.loadMoreReadings()
                        }
                    }
            }
        }
        .navigationTitle("Readings")
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !selectedReadings.isEmpty {
                    Button(role: .destructive) {
                        isShowingDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            
            ToolbarItemGroup(placement: .topBarLeading) {
                Button {
                    isShowingFilter = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .refreshable {
            await refreshData()
        }
        .alert("Delete Readings", isPresented: $isShowingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteSelectedReadings()
            }
        } message: {
            Text("Are you sure you want to delete the selected readings?")
        }
        .sheet(isPresented: $isShowingFilter) {
            NavigationStack {
                ReadingFilterView(
                    sortOrder: $sortOrder
                )
            }
        }
        .onAppear {
            // Load readings if not already loaded
            if dataManager.readings.isEmpty {
                Task {
                    await dataManager.refreshReadings()
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredReadings: [Reading] {
        var readings = dataManager.readings
        
        // Apply search filter
        if !searchText.isEmpty {
            readings = readings.filter { reading in
                reading.description?.lowercased().contains(searchText.lowercased()) ?? false
            }
        }
        
        // Apply sort order
        readings = sortReadings(readings, by: sortOrder)
        
        return readings
    }
    
    private func sortReadings(_ readings: [Reading], by order: ReadingSort) -> [Reading] {
        switch order {
        case .dateNewest:
            return readings.sorted { $0.recordedAt > $1.recordedAt }
        case .dateOldest:
            return readings.sorted { $0.recordedAt < $1.recordedAt }
        case .qualityBest:
            return readings.sorted { 
                $0.qualitySuccess && !$1.qualitySuccess || 
                ($0.qualitySuccess == $1.qualitySuccess && $0.recordedAt > $1.recordedAt)
            }
        case .locationNearest:
            return readings.sorted { reading1, reading2 in
                guard let loc1 = reading1.location, let loc2 = reading2.location else { return false }
                let location1 = CLLocation(latitude: loc1.latitude, longitude: loc1.longitude)
                let location2 = CLLocation(latitude: loc2.latitude, longitude: loc2.longitude)
                return location1.distance(from: currentLocation) < location2.distance(from: currentLocation)
            }
        }
    }
    
    private var currentLocation: CLLocation {
        // Use a default location or get from LocationManager
        return CLLocation(latitude: 0, longitude: 0)
    }
    
    // MARK: - Actions
    
    private func toggleSelection(for reading: Reading) {
        if selectedReadings.contains(reading.id) {
            selectedReadings.remove(reading.id)
        } else {
            selectedReadings.insert(reading.id)
        }
    }
    
    private func deleteSelectedReadings() {
        let readingsToDelete = dataManager.readings.filter { 
            selectedReadings.contains($0.id) 
        }
        
        dataManager.deleteReadings(readingsToDelete)
        selectedReadings.removeAll()
    }
    
    private func refreshData() async {
        if authManager.isLoggedIn {
            await dataManager.syncReadings()
        }
        await dataManager.refreshReadings()
    }
}

// MARK: - ReadingSort

enum ReadingSort: String, CaseIterable, Identifiable {
    case dateNewest = "Date: Newest First"
    case dateOldest = "Date: Oldest First"
    case qualityBest = "Quality: Best First"
    case locationNearest = "Location: Nearest First"
    
    var id: String { rawValue }
}

// MARK: - SyncSection

private struct SyncSection: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        Section {
            HStack {
                if dataManager.isSyncing {
                    ProgressView()
                    Text("Syncing...")
                } else if let lastSync = dataManager.lastSyncDate {
                    Text("Last sync: \(lastSync, formatter: Self.dateFormatter)")
                } else {
                    Text("Not synced yet")
                }
                
                Spacer()
                
                Button {
                    Task {
                        await dataManager.syncReadings()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - ReadingRowView

struct ReadingRowView: View {
    let reading: Reading
    let isSelected: Bool
    
    var body: some View {
        HStack(alignment: .center) {
            // Selection indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.clear)
            }
            
            // Date
            VStack(alignment: .leading) {
                Text(reading.dateString)
                    .font(.headline)
                
                if let description = reading.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Quality indicator
            Circle()
                .fill(reading.qualityColor)
                .frame(width: 20, height: 20)
            
            // Sync status
            Image(systemName: reading.status == .synced ? "checkmark" : "clock")
                .foregroundColor(reading.status == .synced ? .green : .gray)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - ReadingFilterView

struct ReadingFilterView: View {
    @Binding var sortOrder: ReadingSort
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section(header: Text("Sort By")) {
                ForEach(ReadingSort.allCases) { order in
                    Button {
                        sortOrder = order
                        dismiss()
                    } label: {
                        HStack {
                            Text(order.rawValue)
                            Spacer()
                            if sortOrder == order {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Sort & Filter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("ReadingListView") {
    NavigationStack {
        ReadingListView()
            .environmentObject(MockDataManager())
            .environmentObject(MockAuthManager())
    }
}

#Preview("ReadingRowView") {
    let reading = Reading(
        recordedAt: Date(),
        description: "Test Reading",
        f0: 100,
        fMax: 500,
        timeToFMax: 1000,
        fvDivFMax: 0.75,
        vj: 1.0,
        m0: 2.0,
        pi: 3.0,
        qualityFailed: false
    )
    
    return List {
        ReadingRowView(reading: reading, isSelected: false)
        ReadingRowView(reading: reading, isSelected: true)
    }
}
