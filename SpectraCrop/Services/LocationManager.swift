//  LocationManager.swift
//  SpectraCrop
//
//  Created by SpectraCrop Development Team
//  Copyright © 2026 SpectraCrop. All rights reserved.
//

import Foundation
import SwiftUI
import CoreLocation
import Combine

// MARK: - LocationManager Protocol

protocol LocationManagerProtocol: ObservableObject {
    var currentLocation: CLLocationCoordinate2D? { get }
    var isRequesting: Bool { get }
    var isEnabled: Bool { get }
    var error: Error? { get }
    
    func initialize()
    func requestLocation() async
    func startMonitoring()
    func stopMonitoring()
}

// MARK: - LocationManager Implementation

final class LocationManager: NSObject, LocationManagerProtocol, ObservableObject, CLLocationManagerDelegate {
    
    // MARK: - Singleton
    
    static let shared = LocationManager()
    
    // MARK: - Published Properties
    
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var isRequesting = false
    @Published var isEnabled = false
    @Published var error: Error?
    
    // MARK: - Private Properties
    
    private let locationManager = CLLocationManager()
    private var completion: ((Result<CLLocationCoordinate2D, Error>) -> Void)?
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func initialize() {
        checkAuthorization()
    }
    
    private func checkAuthorization() {
        let status = CLLocationManager.authorizationStatus()
        
        DispatchQueue.main.async {
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.isEnabled = true
            case .denied, .restricted:
                self.isEnabled = false
                self.error = LocationError.denied
            case .notDetermined:
                self.isEnabled = false
            @unknown default:
                self.isEnabled = false
            }
        }
    }
    
    // MARK: - Location Request
    
    @MainActor
    func requestLocation() async {
        isRequesting = true
        error = nil
        
        let status = CLLocationManager.authorizationStatus()
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .notDetermined:
            // Request permission first
            locationManager.requestWhenInUseAuthorization()
        default:
            error = LocationError.denied
            isRequesting = false
        }
    }
    
    func startMonitoring() {
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    func stopMonitoring() {
        locationManager.stopMonitoringSignificantLocationChanges()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        DispatchQueue.main.async {
            self.currentLocation = location.coordinate
            self.isRequesting = false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.error = error
            self.isRequesting = false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkAuthorization()
    }
}

// MARK: - Location Error

enum LocationError: Error {
    case denied
    case disabled
    case timeout
    
    var localizedDescription: String {
        switch self {
        case .denied: return "Location permission denied"
        case .disabled: return "Location services are disabled"
        case .timeout: return "Location request timed out"
        }
    }
}

// MARK: - Mock LocationManager for Testing

#if DEBUG
class MockLocationManager: LocationManagerProtocol, ObservableObject {
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var isRequesting = false
    @Published var isEnabled = true
    @Published var error: Error?
    
    func initialize() {}
    
    func requestLocation() async {
        await MainActor.run {
            isRequesting = true
        }
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        await MainActor.run {
            currentLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
            isRequesting = false
        }
    }
    
    func startMonitoring() {}
    
    func stopMonitoring() {}
}
#endif
