//  SpectraCropApp.swift
//  SpectraCrop
//
//  Created by SpectraCrop Development Team
//  Copyright © 2026 SpectraCrop. All rights reserved.
//

import SwiftUI

@main
struct SpectraCropApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var bluetoothManager = BluetoothManager.shared
    @StateObject private var locationManager = LocationManager.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environmentObject(dataManager)
                .environmentObject(bluetoothManager)
                .environmentObject(locationManager)
                // Removed .preferredColorScheme(.light) to support Dark Mode
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Initialize services
        AuthManager.shared.initialize()
        DataManager.shared.initialize()
        BluetoothManager.shared.initialize()
        LocationManager.shared.initialize()
        
        // Configure appearance
        configureAppearance()
        
        return true
    }
    
    private func configureAppearance() {
        // Navigation bar appearance - use system default for full-screen experience
        // Removed custom opaque background to allow content to extend under nav bar
        
        // Tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = .systemBackground
        UITabBar.appearance().standardAppearance = tabBarAppearance
        
        // Button appearance
        UIButton.appearance().tintColor = .systemBlue
    }
}
