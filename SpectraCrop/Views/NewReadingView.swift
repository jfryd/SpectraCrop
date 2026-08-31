//  NewReadingView.swift
//  SpectraCrop
//
//  Created by SpectraCrop Development Team
//  Copyright © 2026 SpectraCrop. All rights reserved.
//

import SwiftUI
import CoreLocation

// MARK: - NewReadingView

struct NewReadingView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject var locationManager: LocationManager
    @State private var isShowingManual = false
    @State private var isShowingAutomatic = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Bluetooth Device Section
            BluetoothDeviceSection()
                .environmentObject(bluetoothManager)
            
            // Location Section
            LocationSection()
                .environmentObject(locationManager)
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 16) {
                Button {
                    isShowingManual = true
                } label: {
                    Label("Manual Entry", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button {
                    isShowingAutomatic = true
                } label: {
                    Label("From Device", systemImage: "antenna.radiowaves.left.and.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(!bluetoothManager.isEnabled || bluetoothManager.connectedDevice == nil)
            }
            .padding(.horizontal)
        }
        .navigationTitle("New Reading")
        .sheet(isPresented: $isShowingManual) {
            NavigationStack {
                NewManualReadingView()
                    .environmentObject(dataManager)
                    .environmentObject(locationManager)
            }
        }
        .sheet(isPresented: $isShowingAutomatic) {
            NavigationStack {
                NewAutomaticReadingView()
                    .environmentObject(dataManager)
                    .environmentObject(bluetoothManager)
                    .environmentObject(locationManager)
            }
        }
        .onAppear {
            // Start Bluetooth scan when view appears
            bluetoothManager.startScan()
        }
        .onDisappear {
            // Stop Bluetooth scan when view disappears
            bluetoothManager.stopScan()
        }
    }
}

// MARK: - BluetoothDeviceSection

private struct BluetoothDeviceSection: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Bluetooth Device")
                    .font(.headline)
                
                Spacer()
                
                if bluetoothManager.isScanning {
                    ProgressView()
                } else if let error = bluetoothManager.error {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                } else if bluetoothManager.connectedDevice != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            if let device = bluetoothManager.connectedDevice {
                VStack(alignment: .leading) {
                    Text(device.name)
                        .font(.subheadline)
                    
                    HStack {
                        Image(systemName: "signal")
                        Text("Signal: \(device.rssi) dBm")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .cornerRadius(8)
            } else if !bluetoothManager.devices.isEmpty {
                VStack(alignment: .leading) {
                    ForEach(bluetoothManager.devices) { device in
                        Button {
                            bluetoothManager.connect(to: device)
                        } label: {
                            HStack {
                                Text(device.name)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text("\(device.rssi) dBm")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.bordered)
                        .padding(.vertical, 4)
                    }
                }
            } else if !bluetoothManager.isEnabled {
                Text("Bluetooth is disabled")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("No devices found")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - LocationSection

private struct LocationSection: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var useCurrentLocation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Location")
                    .font(.headline)
                
                Spacer()
                
                if let _ = locationManager.currentLocation, useCurrentLocation {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            Toggle("Use Current Location", isOn: $useCurrentLocation)
                .disabled(!locationManager.isEnabled)
            
            if !locationManager.isEnabled {
                Text("Enable location permissions in Settings")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - NewManualReadingView

struct NewManualReadingView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var description = ""
    @State private var useCurrentLocation = false
    @State private var latitude = 0.0
    @State private var longitude = 0.0
    @State private var altitude = 0.0
    
    // Spectral values
    @State private var f0: String = "100"
    @State private var fMax: String = "500"
    @State private var timeToFMax: String = "1000"
    @State private var fvDivFMax: String = "0.75"
    @State private var vj: String = "1.0"
    @State private var m0: String = "2.0"
    @State private var pi: String = "3.0"
    
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var body: some View {
        Form {
            Section(header: Text("Description")) {
                TextField("Description (Optional)", text: $description)
            }
            
            Section(header: Text("Location")) {
                Toggle("Use Current Location", isOn: $useCurrentLocation)
                    .onChange(of: useCurrentLocation) { newValue in
                        if newValue {
                            Task {
                                await locationManager.requestLocation()
                            }
                        }
                    }
                
                if useCurrentLocation, let location = locationManager.currentLocation {
                    HStack {
                        Text("Latitude")
                        Spacer()
                        Text(String(format: "%.6f", location.latitude))
                    }
                    
                    HStack {
                        Text("Longitude")
                        Spacer()
                        Text(String(format: "%.6f", location.longitude))
                    }
                } else {
                    TextField("Latitude", value: $latitude, format: .number)
                        .keyboardType(.decimalPad)
                    
                    TextField("Longitude", value: $longitude, format: .number)
                        .keyboardType(.decimalPad)
                    
                    TextField("Altitude", value: $altitude, format: .number)
                        .keyboardType(.decimalPad)
                }
            }
            
            Section(header: Text("Spectral Data")) {
                TextField("F0", text: $f0)
                    .keyboardType(.numberPad)
                
                TextField("FMax", text: $fMax)
                    .keyboardType(.numberPad)
                
                TextField("Time to FMax (ms)", text: $timeToFMax)
                    .keyboardType(.numberPad)
                
                TextField("Fv/FMax", text: $fvDivFMax)
                    .keyboardType(.decimalPad)
                
                TextField("Vj", text: $vj)
                    .keyboardType(.decimalPad)
                
                TextField("M0", text: $m0)
                    .keyboardType(.decimalPad)
                
                TextField("PI", text: $pi)
                    .keyboardType(.decimalPad)
            }
            
            if let errorMessage = errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            
            Section {
                Button("Save Reading") {
                    saveReading()
                }
                .disabled(isSaving)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Manual Reading")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
    
    private func saveReading() {
        guard let f0Value = UInt16(f0),
              let fMaxValue = UInt16(fMax),
              let timeToFMaxValue = Int(timeToFMax),
              let fvDivFMaxValue = Double(fvDivFMax),
              let vjValue = Double(vj),
              let m0Value = Double(m0),
              let piValue = Double(pi) else {
            errorMessage = "Please enter valid values"
            return
        }
        
        let location: CLLocationCoordinate2D? = useCurrentLocation ? 
            locationManager.currentLocation : 
            (latitude != 0 || longitude != 0) ? CLLocationCoordinate2D(latitude: latitude, longitude: longitude) : nil
        
        let reading = Reading(
            description: description.isEmpty ? nil : description,
            location: location,
            altitude: altitude == 0 ? nil : altitude,
            f0: f0Value,
            fMax: fMaxValue,
            timeToFMax: timeToFMaxValue,
            fvDivFMax: fvDivFMaxValue,
            vj: vjValue,
            m0: m0Value,
            pi: piValue
        )
        
        dataManager.addReading(reading)
        dismiss()
    }
}

// MARK: - NewAutomaticReadingView

struct NewAutomaticReadingView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var description = ""
    @State private var useCurrentLocation = true
    @State private var isConnecting = false
    @State private var isReading = false
    @State private var readingProgress: Double = 0
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            // Connection Status
            if let device = bluetoothManager.connectedDevice {
                VStack(spacing: 8) {
                    Text(device.name)
                        .font(.title3)
                    
                    if isReading {
                        ProgressView(value: readingProgress, total: 1.0)
                        Text("Reading from device...")
                            .font(.subheadline)
                    } else {
                        Text("Connected")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            } else {
                Text("Not connected to device")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Options
            VStack(spacing: 16) {
                Toggle("Use Current Location", isOn: $useCurrentLocation)
                    .padding(.horizontal)
                
                TextField("Description (Optional)", text: $description)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            // Action Button
            Button {
                startReading()
            } label: {
                if isReading {
                    Label("Cancel", systemImage: "xmark")
                        .frame(maxWidth: .infinity)
                } else {
                    Label("Start Reading", systemImage: "record.circle")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(bluetoothManager.connectedDevice == nil)
            .padding(.horizontal)
        }
        .navigationTitle("From Device")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .onAppear {
            if useCurrentLocation {
                Task {
                    await locationManager.requestLocation()
                }
            }
        }
    }
    
    private func startReading() {
        if isReading {
            // Cancel reading
            isReading = false
            readingProgress = 0
        } else {
            // Start reading from device
            isReading = true
            readingProgress = 0
            
            // Simulate reading process
            Task {
                // In a real implementation, this would:
                // 1. Send command to device to start reading
                // 2. Receive data packets
                // 3. Parse spectral data
                // 4. Create Reading object
                
                // For now, simulate the process
                for i in 1...10 {
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    await MainActor.run {
                        readingProgress = Double(i) / 10.0
                    }
                }
                
                // Create a reading with mock data
                let location: CLLocationCoordinate2D? = useCurrentLocation ? 
                    locationManager.currentLocation : nil
                
                let reading = Reading(
                    description: description.isEmpty ? nil : description,
                    location: location,
                    f0: 100,
                    fMax: 500,
                    timeToFMax: Int.random(in: 1000...2000),
                    fvDivFMax: Double.random(in: 0.6...0.8),
                    vj: Double.random(in: 0.5...1.5),
                    m0: Double.random(in: 1.0...3.0),
                    pi: Double.random(in: 2.0...4.0)
                )
                
                await MainActor.run {
                    dataManager.addReading(reading)
                    isReading = false
                    readingProgress = 0
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("NewReadingView") {
    NavigationStack {
        NewReadingView()
            .environmentObject(MockDataManager())
            .environmentObject(MockBluetoothManager())
            .environmentObject(MockLocationManager())
    }
}
