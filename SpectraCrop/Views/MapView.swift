//  MapView.swift
//  SpectraCrop
//
//  Created by SpectraCrop Development Team
//  Copyright © 2026 SpectraCrop. All rights reserved.
//

import SwiftUI
import MapKit

// MARK: - MapView

struct MapView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var locationManager: LocationManager
    
    @State private var region: MKCoordinateRegion
    @State private var selectedReading: Reading?
    
    // For map interactions
    @State private var position: MapCameraPosition = .automatic
    @State private var mapSelection: UUID?
    
    init() {
        // Default to a reasonable region
        let center = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        _region = State(initialValue: MKCoordinateRegion(
            center: center,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        ))
    }
    
    var body: some View {
        Map(position: $position, selection: $mapSelection) {
            // Show user location if available
            if let userLocation = locationManager.currentLocation {
                Marker("Your Location", coordinate: userLocation)
                    .tint(.blue)
            }
            
            // Show all readings with locations
            ForEach(dataManager.readings.filter { $0.location != nil }) { reading in
                if let location = reading.location {
                    Annotation(coordinate: location) {
                        ReadingMapMarker(
                            reading: reading,
                            isSelected: mapSelection == reading.id
                        )
                    }
                    .tag(reading.id)
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .navigationTitle("Map")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    // Center on user location
                    if let userLocation = locationManager.currentLocation {
                        position = .region(MKCoordinateRegion(
                            center: userLocation,
                            latitudinalMeters: 1000,
                            longitudinalMeters: 1000
                        ))
                    }
                } label: {
                    Image(systemName: "location.fill")
                }
            }
        }
        .onAppear {
            // Try to center on user location
            if let userLocation = locationManager.currentLocation {
                position = .region(MKCoordinateRegion(
                    center: userLocation,
                    latitudinalMeters: 1000,
                    longitudinalMeters: 1000
                ))
            }
        }
        .sheet(item: $mapSelection) { readingId in
            if let reading = dataManager.readings.first(where: { $0.id == readingId }) {
                NavigationStack {
                    ReadingDetailView(reading: reading)
                        .environmentObject(dataManager)
                }
            }
        }
    }
}

// MARK: - ReadingMapMarker

private struct ReadingMapMarker: View {
    let reading: Reading
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            // Quality indicator
            Circle()
                .fill(reading.qualityColor)
                .frame(width: 24, height: 24)
                .overlay {
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                }
            
            // Date
            if isSelected {
                Text(reading.dateString)
                    .font(.caption2)
                    .padding(4)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(4)
            }
        }
    }
}

// MARK: - ReadingDetailView

struct ReadingDetailView: View {
    let reading: Reading
    @EnvironmentObject var dataManager: DataManager
    @Environment(\dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading) {
                    Text(reading.dateString)
                        .font(.title)
                    
                    if let description = reading.description {
                        Text(description)
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Quality Badge
                HStack {
                    Circle()
                        .fill(reading.qualityColor)
                        .frame(width: 20, height: 20)
                    
                    Text(reading.qualitySuccess ? "Good Quality" : "Poor Quality")
                        .font(.subheadline)
                }
                
                Divider()
                
                // Location
                if let location = reading.location {
                    SectionView(title: "Location") {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Latitude:")
                                Text(String(format: "%.6f", location.latitude))
                            }
                            
                            HStack {
                                Text("Longitude:")
                                Text(String(format: "%.6f", location.longitude))
                            }
                            
                            if let altitude = reading.altitude {
                                HStack {
                                    Text("Altitude:")
                                    Text(String(format: "%.2f m", altitude))
                                }
                            }
                        }
                        .font(.subheadline)
                    }
                }
                
                // Spectral Data
                SectionView(title: "Spectral Data") {
                    VStack(alignment: .leading, spacing: 8) {
                        DataRow(label: "F0", value: String(reading.f0))
                        DataRow(label: "FMax", value: String(reading.fMax))
                        DataRow(label: "Time to FMax", value: "\(reading.timeToFMaxMs) ms")
                        DataRow(label: "Fv/FMax", value: String(format: "%.4f", reading.fvDivFMax))
                        DataRow(label: "Fv/FMax Normal", value: "\(reading.fvDivFMaxNormal)")
                        DataRow(label: "Vj", value: String(format: "%.4f", reading.vj))
                        DataRow(label: "M0", value: String(format: "%.4f", reading.m0))
                        DataRow(label: "PI", value: String(format: "%.4f", reading.pi))
                        
                        if let ppPredict = reading.ppPredict {
                            DataRow(label: "PPredict", value: String(format: "%.4f", ppPredict))
                        }
                        
                        if let absoluteDifference = reading.absoluteDifference {
                            DataRow(label: "Absolute Difference", value: String(format: "%.4f", absoluteDifference))
                        }
                        
                        if let covariance = reading.covariance {
                            DataRow(label: "Covariance", value: String(format: "%.4f", covariance))
                        }
                        
                        if let correlation = reading.correlation {
                            DataRow(label: "Correlation", value: String(format: "%.4f", correlation))
                        }
                    }
                }
                
                // Metadata
                SectionView(title: "Metadata") {
                    VStack(alignment: .leading, spacing: 8) {
                        DataRow(label: "Status", value: reading.status.rawValue.capitalized)
                        DataRow(label: "Recorded", value: reading.recordedAt.formatted())
                        
                        if let syncTime = reading.syncTime {
                            DataRow(label: "Synced", value: syncTime.formatted())
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Reading Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        deleteReading()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
    }
    
    private func deleteReading() {
        dataManager.deleteReading(reading)
        dismiss()
    }
}

// MARK: - SectionView

private struct SectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 4)
            
            content
        }
    }
}

// MARK: - DataRow

private struct DataRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(.body, design: .monospaced))
        }
    }
}

// MARK: - Previews

#Preview("MapView") {
    MapView()
        .environmentObject(MockDataManager())
        .environmentObject(MockLocationManager())
}

#Preview("ReadingDetailView") {
    let reading = Reading(
        recordedAt: Date(),
        description: "Test Reading",
        location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        altitude: 10.0,
        f0: 100,
        fMax: 500,
        timeToFMax: 1500,
        fvDivFMax: 0.75,
        vj: 1.2,
        m0: 2.5,
        pi: 3.14,
        ppPredict: 0.8,
        absoluteDifference: 5.0,
        covariance: 2.0,
        correlation: 0.99,
        qualityFailed: false
    )
    
    return NavigationStack {
        ReadingDetailView(reading: reading)
            .environmentObject(MockDataManager())
    }
}
