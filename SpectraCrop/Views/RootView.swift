//  RootView.swift
//  SpectraCrop
//
//  Created by SpectraCrop Development Team
//  Copyright © 2026 SpectraCrop. All rights reserved.
//

import SwiftUI

// MARK: - RootView

struct RootView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        Group {
            if authManager.isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .onAppear {
            // Attempt to relogin if we have a session
            if !authManager.isLoggedIn {
                Task {
                    await authManager.relogin()
                }
            }
        }
    }
}

// MARK: - MainTabView

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject var locationManager: LocationManager
    
    var body: some View {
        TabView {
            // New Reading Tab
            NavigationStack {
                NewReadingView()
            }
            .tabItem {
                Label("New", systemImage: "plus.circle.fill")
            }
            
            // List Tab
            NavigationStack {
                ReadingListView()
            }
            .tabItem {
                Label("List", systemImage: "list.bullet")
            }
            
            // Map Tab
            NavigationStack {
                MapView()
            }
            .tabItem {
                Label("Map", systemImage: "map.fill")
            }
            
            // User Tab
            NavigationStack {
                UserProfileView()
            }
            .tabItem {
                Label("User", systemImage: "person.circle.fill")
            }
        }
        .tint(Color("AccentColor"))
        .onAppear {
            // Start Bluetooth scan when app becomes active
            if authManager.isLoggedIn {
                bluetoothManager.startScan()
            }
        }
    }
}

// MARK: - LoginView

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var username = ""
    @State private var password = ""
    @State private var isShowingRegister = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        Form {
            Section {
                TextField("Username", text: $username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                SecureField("Password", text: $password)
            }
            
            if let errorMessage = errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            
            Section {
                Button("Login") {
                    login()
                }
                .disabled(username.isEmpty || password.isEmpty || isLoading)
                
                Button("Create Account") {
                    isShowingRegister = true
                }
            }
        }
        .navigationTitle("SpectraCrop")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingRegister) {
            NavigationStack {
                RegisterView()
            }
        }
        .onAppear {
            // Clear any previous error when view appears
            errorMessage = nil
        }
    }
    
    private func login() {
        isLoading = true
        errorMessage = nil
        
        Task {
            await authManager.login(username: username, password: password)
            
            await MainActor.run {
                isLoading = false
                
                if let error = authManager.error {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - RegisterView

struct RegisterView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        Form {
            Section {
                TextField("Username", text: $username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                SecureField("Password", text: $password)
                
                SecureField("Confirm Password", text: $confirmPassword)
            }
            
            if let errorMessage = errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            
            Section {
                Button("Create Account") {
                    register()
                }
                .disabled(username.isEmpty || password.isEmpty || confirmPassword.isEmpty || isLoading)
            }
        }
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
    
    private func register() {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            await authManager.register(username: username, password: password)
            
            await MainActor.run {
                isLoading = false
                
                if let error = authManager.error {
                    errorMessage = error.localizedDescription
                } else if authManager.isLoggedIn {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("RootView (Logged In)") {
    let authManager = MockAuthManager()
    authManager.currentUser = User(id: UUID(), username: "test", sessionId: UUID().uuidString)
    
    return RootView()
        .environmentObject(authManager)
        .environmentObject(MockDataManager())
        .environmentObject(MockBluetoothManager())
        .environmentObject(MockLocationManager())
}

#Preview("LoginView") {
    LoginView()
        .environmentObject(MockAuthManager())
}
