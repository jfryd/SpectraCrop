//  AuthManager.swift
//  SpectraCrop
//
//  Created by SpectraCrop Development Team
//  Copyright © 2026 SpectraCrop. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

// MARK: - AuthManager Protocol

protocol AuthManagerProtocol: ObservableObject {
    var currentUser: User? { get }
    var isLoggedIn: Bool { get }
    var isLoading: Bool { get }
    var error: Error? { get }
    
    func initialize()
    func login(username: String, password: String) async
    func register(username: String, password: String) async
    func relogin() async
    func logout()
    func deleteAccount() async
}

// MARK: - AuthManager Implementation

final class AuthManager: AuthManagerProtocol, ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = AuthManager()
    
    // MARK: - Published Properties
    
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var error: Error?
    
    // MARK: - Computed Properties
    
    var isLoggedIn: Bool { currentUser != nil }
    
    // MARK: - Keys
    
    private enum Keys {
        static let currentUser = "currentUser"
        static let sessionId = "sessionId"
    }
    
    // MARK: - Initialization
    
    private init() {}
    
    func initialize() {
        // Try to restore session from Keychain
        restoreSession()
    }
    
    private func restoreSession() {
        // Check if we have a session ID in Keychain
        guard let sessionId = KeychainService.get(key: Keys.sessionId) else {
            return
        }
        
        // Try to get user from Keychain
        if let userData = KeychainService.get(key: Keys.currentUser),
           let user = try? JSONDecoder().decode(User.self, from: Data(userData.utf8)) {
            self.currentUser = user
        }
    }
    
    // MARK: - Login
    
    @MainActor
    func login(username: String, password: String) async {
        isLoading = true
        error = nil
        
        do {
            let user = try await APIClient.shared.login(username: username, password: password)
            await MainActor.run {
                self.currentUser = user
                self.saveUser(user)
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Register
    
    @MainActor
    func register(username: String, password: String) async {
        isLoading = true
        error = nil
        
        do {
            let user = try await APIClient.shared.register(username: username, password: password)
            await MainActor.run {
                self.currentUser = user
                self.saveUser(user)
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    // MARK: - ReLogin
    
    @MainActor
    func relogin() async {
        guard let sessionId = currentUser?.sessionId else { return }
        
        isLoading = true
        error = nil
        
        do {
            let user = try await APIClient.shared.relogin(sessionId: sessionId)
            await MainActor.run {
                self.currentUser = user
                self.saveUser(user)
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Logout
    
    func logout() {
        Task {
            do {
                try await APIClient.shared.logout()
            } catch {
                print("Logout error: \(error)")
            }
            
            await MainActor.run {
                clearSession()
            }
        }
    }
    
    // MARK: - Delete Account
    
    @MainActor
    func deleteAccount() async {
        isLoading = true
        error = nil
        
        do {
            try await APIClient.shared.deleteAccount()
            clearSession()
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    // MARK: - Session Management
    
    private func saveUser(_ user: User) {
        // Save user to Keychain
        if let userData = try? JSONEncoder().encode(user),
           let userString = String(data: userData, encoding: .utf8) {
            KeychainService.save(key: Keys.currentUser, value: userString)
        }
        
        // Save session ID separately
        KeychainService.save(key: Keys.sessionId, value: user.sessionId)
    }
    
    private func clearSession() {
        currentUser = nil
        KeychainService.delete(key: Keys.currentUser)
        KeychainService.delete(key: Keys.sessionId)
    }
}

// MARK: - Mock AuthManager for Testing

#if DEBUG
class MockAuthManager: AuthManagerProtocol, ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var error: Error?
    
    var isLoggedIn: Bool { currentUser != nil }
    
    func initialize() {}
    
    func login(username: String, password: String) async {
        await MainActor.run {
            isLoading = true
        }
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        await MainActor.run {
            currentUser = User(id: UUID(), username: username, sessionId: UUID().uuidString)
            isLoading = false
        }
    }
    
    func register(username: String, password: String) async {
        await login(username: username, password: password)
    }
    
    func relogin() async {}
    
    func logout() {
        currentUser = nil
    }
    
    func deleteAccount() async {
        await MainActor.run {
            currentUser = nil
        }
    }
}
#endif
