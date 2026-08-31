//  DeviceInfo.swift
//  SpectraCrop
//
//  Created by SpectraCrop Development Team
//  Copyright © 2026 SpectraCrop. All rights reserved.
//

import Foundation
import UIKit

// MARK: - DeviceInfo

struct DeviceInfo {
    
    // MARK: - Device Identifier
    
    static var deviceId: String? {
        // Try to get from Keychain first
        if let storedId = KeychainService.get(key: "deviceId") {
            return storedId
        }
        
        // Generate new device ID using UIDevice identifierForVendor
        // This is reset when the app is reinstalled or on a new device
        let vendorId = UIDevice.current.identifierForVendor?.uuidString
        
        // If vendor ID is not available, generate a random UUID
        let id = vendorId ?? UUID().uuidString
        
        // Store in Keychain
        KeychainService.save(key: "deviceId", value: id)
        
        return id
    }
    
    // MARK: - Device Properties
    
    static var deviceName: String {
        return UIDevice.current.name
    }
    
    static var deviceModel: String {
        return UIDevice.current.model
    }
    
    static var systemName: String {
        return UIDevice.current.systemName
    }
    
    static var systemVersion: String {
        return UIDevice.current.systemVersion
    }
    
    static var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "Unknown"
    }
    
    static var appBuild: String {
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return build
        }
        return "Unknown"
    }
    
    static var appName: String {
        if let name = Bundle.main.infoDictionary?["CFBundleName"] as? String {
            return name
        }
        return "SpectraCrop"
    }
}

// MARK: - Keychain Service for Secure Storage

final class KeychainService {
    
    // MARK: - Singleton
    
    static let shared = KeychainService()
    private init() {}
    
    // MARK: - Keys
    
    private static let serviceName = "com.spectracrop.ios"
    
    // MARK: - Save
    
    static func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        return status == errSecSuccess
    }
    
    // MARK: - Get
    
    static func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    // MARK: - Delete
    
    static func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Clear All
    
    static func clearAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - UserDefaults Extension for Non-Sensitive Data

extension UserDefaults {
    
    // MARK: - Keys
    
    private enum Keys {
        static let hasOnboarded = "hasOnboarded"
        static let lastSyncDate = "lastSyncDate"
        static let selectedTab = "selectedTab"
    }
    
    // MARK: - Onboarding
    
    var hasOnboarded: Bool {
        get { return bool(forKey: Keys.hasOnboarded) }
        set { set(newValue, forKey: Keys.hasOnboarded) }
    }
    
    // MARK: - Sync
    
    var lastSyncDate: Date? {
        get { return object(forKey: Keys.lastSyncDate) as? Date }
        set { set(newValue, forKey: Keys.lastSyncDate) }
    }
    
    // MARK: - UI State
    
    var selectedTab: Int {
        get { return integer(forKey: Keys.selectedTab) }
        set { set(newValue, forKey: Keys.selectedTab) }
    }
}
