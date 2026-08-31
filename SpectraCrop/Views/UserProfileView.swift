//  UserProfileView.swift
//  SpectraCrop
//
//  Created by SpectraCrop Development Team
//  Copyright © 2026 SpectraCrop. All rights reserved.
//

import SwiftUI

// MARK: - UserProfileView

struct UserProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var dataManager: DataManager
    
    @State private var isShowingSettings = false
    @State private var isShowingLogoutAlert = false
    @State private var isShowingDeleteAccountAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                // User Section
                Section {
                    if let user = authManager.currentUser {
                        UserInfoView(user: user)
                    }
                }
                
                // Stats Section
                StatsSection()
                    .environmentObject(dataManager)
                
                // Actions Section
                Section {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                    
                    Button {
                        Task {
                            await dataManager.syncReadings()
                        }
                    } label: {
                        Label("Sync Now", systemImage: "arrow.clockwise")
                    }
                    .disabled(!authManager.isLoggedIn)
                }
                
                // Sign Out Section
                Section {
                    Button(role: .destructive) {
                        isShowingLogoutAlert = true
                    } label: {
                        Label("Sign Out", systemImage: "arrow.left.square")
                    }
                    
                    Button(role: .destructive) {
                        isShowingDeleteAccountAlert = true
                    } label: {
                        Label("Delete Account", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingSettings) {
                NavigationStack {
                    SettingsView()
                        .environmentObject(authManager)
                }
            }
            .alert("Sign Out", isPresented: $isShowingLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    authManager.logout()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $isShowingDeleteAccountAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Account", role: .destructive) {
                    Task {
                        await authManager.deleteAccount()
                    }
                }
            } message: {
                Text("This will permanently delete your account and all your data. This cannot be undone.")
            }
        }
    }
}

// MARK: - UserInfoView

private struct UserInfoView: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 16) {
                // Avatar placeholder
                Circle()
                    .fill(Color.blue)
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.title)
                    }
                
                VStack(alignment: .leading) {
                    Text(user.username)
                        .font(.title)
                    
                    Text("Account created: \(user.createdAt.formatted(.relative(presentation: .named)))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if let lastLogin = user.lastLoginAt {
                Text("Last login: \(lastLogin.formatted())")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

// MARK: - StatsSection

private struct StatsSection: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        Section(header: Text("Statistics")) {
            HStack {
                StatView(value: String(dataManager.readings.count), label: "Readings")
                
                Spacer()
                
                let qualityCount = dataManager.readings.filter { $0.qualitySuccess }.count
                StatView(value: String(qualityCount), label: "Good Quality")
            }
            
            HStack {
                let syncedCount = dataManager.readings.filter { $0.status == .synced }.count
                StatView(value: String(syncedCount), label: "Synced")
                
                Spacer()
                
                let unsyncedCount = dataManager.readings.filter { $0.status == .local }.count
                StatView(value: String(unsyncedCount), label: "Pending Sync")
            }
        }
    }
}

// MARK: - StatView

private struct StatView: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - SettingsView

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section {
                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    Label("Privacy Policy", systemImage: "shield.fill")
                }
                
                NavigationLink {
                    AppInfoView()
                } label: {
                    Label("App Info", systemImage: "info.circle.fill")
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - PrivacyPolicyView

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Privacy Policy")
                    .font(.title)
                    .padding(.bottom)
                
                Text("Last updated: August 31, 2026")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
                
                // This would load from the PRIVACY_POLICY.md file
                // or from a web view
                Text("The privacy policy explains how we collect, use, and protect your data.")
                    .font(.body)
                
                // In production, load from file or web
                // Text(markdownContent)
                // OR
                // WebView(url: privacyPolicyURL)
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - AppInfoView

struct AppInfoView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    Text("App Name")
                    Spacer()
                    Text("SpectraCrop")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Version")
                    Spacer()
                    Text(DeviceInfo.appVersion)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Build")
                    Spacer()
                    Text(DeviceInfo.appBuild)
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                HStack {
                    Text("Device Model")
                    Spacer()
                    Text(DeviceInfo.deviceModel)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("System Version")
                    Spacer()
                    Text(DeviceInfo.systemVersion)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("App Info")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Previews

#Preview("UserProfileView (Logged In)") {
    NavigationStack {
        UserProfileView()
            .environmentObject(MockAuthManager())
            .environmentObject(MockDataManager())
    }
}

#Preview("SettingsView") {
    NavigationStack {
        SettingsView()
            .environmentObject(MockAuthManager())
    }
}

#Preview("PrivacyPolicyView") {
    NavigationStack {
        PrivacyPolicyView()
    }
}

#Preview("AppInfoView") {
    NavigationStack {
        AppInfoView()
    }
}
