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
        .tint(Color.primaryBlue)
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
        ZStack {
            Color.appBackground
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        TextField("Username", text: $username)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)
                            .glassCardStyle()
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)
                            .glassCardStyle()
                    }
                    .padding(.top, 40)
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.primaryRed)
                            .padding()
                            .glassCardStyle()
                            .padding(.horizontal)
                    }
                    
                    VStack(spacing: 16) {
                        Button("Login") {
                            HapticFeedback.light()
                            login()
                        }
                        .disabled(username.isEmpty || password.isEmpty || isLoading)
                        .buttonStyle(GlassPrimaryButtonStyle())
                        .padding(.horizontal)
                        
                        Button("Create Account") {
                            HapticFeedback.light()
                            isShowingRegister = true
                        }
                        .buttonStyle(GlassSecondaryButtonStyle())
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 40)
                    
                    Spacer()
                }
                .padding(.top, 20)
            }
        }
        .navigationTitle("SpectraCrop")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingRegister) {
            NavigationStack {
                RegisterView()
            }
            .presentationDetents([.medium, .large])
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
        ZStack {
            Color.appBackground
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        TextField("Username", text: $username)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)
                            .glassCardStyle()
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)
                            .glassCardStyle()
                        
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)
                            .glassCardStyle()
                    }
                    .padding(.top, 40)
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.primaryRed)
                            .padding()
                            .glassCardStyle()
                            .padding(.horizontal)
                    }
                    
                    VStack(spacing: 16) {
                        Button("Create Account") {
                            HapticFeedback.light()
                            register()
                        }
                        .disabled(username.isEmpty || password.isEmpty || confirmPassword.isEmpty || isLoading)
                        .buttonStyle(GlassPrimaryButtonStyle())
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 40)
                    
                    Spacer()
                }
                .padding(.top, 20)
            }
        }
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    HapticFeedback.light()
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
