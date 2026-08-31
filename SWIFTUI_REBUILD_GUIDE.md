# SwiftUI Rebuild Guide for SpectraCrop

**Version:** 1.0  
**Last Updated:** August 31, 2026  
**Prepared by:** Senior Development Team

---

## 📋 Overview

This document provides a comprehensive guide for the **SwiftUI rebuild** of the SpectraCrop iOS app. The rebuild addresses all security, privacy, and code quality issues identified in the legacy Xamarin.Forms codebase.

**Legacy Codebase Issues:**
- Outdated Xamarin.Forms 2.5.0 (2018)
- No privacy compliance
- Security vulnerabilities (plain text storage, no HTTPS pinning)
- Code quality issues (static singletons, memory leaks)
- Deprecated APIs

**New SwiftUI Implementation:**
- Native SwiftUI with iOS 16+ support
- Full privacy compliance (PrivacyInfo.xcprivacy, App Privacy Labels)
- Secure storage (Keychain for sensitive data)
- Modern architecture (MVVM, dependency injection)
- Clean, maintainable code

---

## 🏗️ Project Structure

```
SpectraCrop/
├── SpectraCropApp.swift          # App entry point and configuration
├── Sources/
│   ├── Models/                  # Data models
│   │   ├── Reading.swift         # Reading data model
│   │   ├── User.swift            # User data model
│   │   └── SyncModels.swift      # API DTOs and sync models
│   │
│   ├── ViewModels/              # View models (MVVM)
│   │   ├── ReadingListViewModel.swift
│   │   ├── ReadingDetailViewModel.swift
│   │   ├── NewReadingViewModel.swift
│   │   └── UserViewModel.swift
│   │
│   ├── Views/                   # SwiftUI Views
│   │   ├── RootView.swift        # Main tab navigation
│   │   ├── LoginView.swift       # User authentication
│   │   ├── RegisterView.swift    # User registration
│   │   ├── ReadingList/          # Reading list features
│   │   │   ├── ReadingListView.swift
│   │   │   ├── ReadingRowView.swift
│   │   │   └── ReadingFilterView.swift
│   │   │
│   │   ├── ReadingDetail/       # Reading detail features
│   │   │   ├── ReadingDetailView.swift
│   │   │   └── ReadingChartView.swift
│   │   │
│   │   ├── NewReading/          # New reading features
│   │   │   ├── NewReadingView.swift
│   │   │   ├── NewManualReadingView.swift
│   │   │   └── NewAutomaticReadingView.swift
│   │   │
│   │   ├── Map/                 # Map features
│   │   │   ├── MapView.swift
│   │   │   └── ReadingMapAnnotation.swift
│   │   │
│   │   └── User/                # User profile features
│   │       ├── UserProfileView.swift
│   │       └── SettingsView.swift
│   │
│   ├── Services/                # Business logic and services
│   │   ├── APIClient.swift       # Network layer
│   │   ├── AuthManager.swift     # Authentication service
│   │   ├── DataManager.swift     # Data management service
│   │   ├── BluetoothManager.swift # Bluetooth LE service
│   │   └── LocationManager.swift # Location service
│   │
│   └── Utilities/               # Utility classes
│       ├── DeviceInfo.swift      # Device information
│       ├── KeychainService.swift # Secure storage
│       └── PersistenceController.swift # Core Data
│
├── Resources/                   # Assets and resources
│   ├── Assets.xcassets/        # Images, colors, etc.
│   └── Localizable.strings      # Localization
│
├── Tests/                      # Unit and UI tests
│   ├── UnitTests/
│   └── UITests/
│
├── SpectraCrop.xcodeproj        # Xcode project file
├── Info.plist                  # Updated with privacy settings
└── PrivacyInfo.xcprivacy        # Privacy manifest file
```

---

## 🚀 Quick Start

### 1. Create New Xcode Project

1. Open Xcode 26+
2. Create new project: **File > New > Project**
3. Select **App** template
4. Product Name: `SpectraCrop`
5. Interface: **SwiftUI**
6. Language: **Swift**
7. Minimum Deployment: **iOS 16.0**
8. Create project in `/SpectraCrop` directory

### 2. Copy Swift Files

Copy all files from `SpectraCrop/Sources/` to your new project's source directory.

### 3. Add Privacy Manifest

Copy `PrivacyInfo.xcprivacy` to your project root.

### 4. Update Info.plist

Ensure these keys are present in your Info.plist:
```xml
<key>NSPrivacyPolicyURL</key>
<string>YOUR_PRIVACY_POLICY_URL</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>Tag readings with your current location for geospatial analysis and mapping.</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>Tag readings with your current location for geospatial analysis and mapping.</string>

<key>NSBluetoothAlwaysUsageDescription</key>
<string>We use Bluetooth to connect to the SpectraCrop hardware device and receive spectral measurements.</string>

<key>NSBluetoothPeripheralUsageDescription</key>
<string>We use Bluetooth to connect to the SpectraCrop hardware device and receive spectral measurements.</string>
```

### 5. Create Core Data Model

1. Create new Data Model: **File > New > File > Data Model**
2. Name: `SpectraCrop`
3. Add entity: `ReadingEntity`
4. Add attributes (see PersistenceController.swift for required fields)

### 6. Add Capabilities

1. Background Modes: Enable **Uses Bluetooth LE accessories**
2. Location: Enable **When In Use** and **Always**

### 7. Build and Run

Build the project and resolve any issues.

---

## 🎯 Architecture Decisions

### 1. MVVM Pattern

**Why:** Clean separation of concerns, testable, maintainable

```
View (SwiftUI) <-> ViewModel (Business Logic) <-> Service (Data/Network) <-> Model (Data)
```

### 2. Singleton Services

**Rationale:** Services are shared across the app and need persistent state.

**Services as Singletons:**
- `AuthManager.shared` - User authentication state
- `DataManager.shared` - Reading data state
- `BluetoothManager.shared` - Bluetooth device state
- `LocationManager.shared` - Location state
- `PersistenceController.shared` - Core Data stack

### 3. Environment Objects

**Why:** SwiftUI's native dependency injection mechanism

```swift
@main
struct SpectraCropApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var dataManager = DataManager.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environmentObject(dataManager)
        }
    }
}
```

### 4. Protocol-Oriented Design

Each service has a protocol for testability:

```swift
protocol AuthManagerProtocol: ObservableObject {
    var currentUser: User? { get }
    var isLoggedIn: Bool { get }
    // ...
}

final class AuthManager: AuthManagerProtocol, ObservableObject {
    // Implementation
}

// For testing
class MockAuthManager: AuthManagerProtocol, ObservableObject {
    // Mock implementation
}
```

---

## 📊 Security Implementation

### 1. Secure Storage (Keychain)

**What's Stored in Keychain:**
- Device ID
- User session ID
- User credentials (password hash)

**Implementation:** See `KeychainService.swift`

### 2. HTTPS with Certificate Pinning

**Status:** To be implemented

**Implementation:**
```swift
struct PinnedSession: URLSession {
    let pinnedCertificates: [SecCertificate]
    
    func urlSession(_ session: URLSession, 
                    didReceive challenge: URLAuthenticationChallenge, 
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Validate certificate against pinned certificates
    }
}
```

### 3. Input Validation

**Implementation:**
```swift
func validateUsername(_ username: String) -> Bool {
    return username.count >= 3 && username.count <= 50
}

func validatePassword(_ password: String) -> Bool {
    return password.count >= 8
}
```

### 4. Error Handling

**All network calls use async/await with proper error handling:**
```swift
func login(username: String, password: String) async {
    do {
        let user = try await APIClient.shared.login(username: username, password: password)
        // Success
    } catch {
        // Handle error
        errorHandler.handle(error)
    }
}
```

---

## 📱 View Structure

### Root Navigation (RootView.swift)

```swift
struct RootView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        if authManager.isLoggedIn {
            MainTabView()
        } else {
            LoginView()
        }
    }
}
```

### Main Tab View

```swift
struct MainTabView: View {
    var body: some View {
        TabView {
            NewReadingView()
                .tabItem {
                    Label("New", systemImage: "plus")
                }
            
            ReadingListView()
                .tabItem {
                    Label("List", systemImage: "list.bullet")
                }
            
            MapView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }
            
            UserProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
    }
}
```

---

## 🔧 Bluetooth Implementation

### SpectraCrop BLE Protocol

**Service UUID:** `00035B03-58E6-07DD-021A-08123A000300`

**Characteristics:**
- Write: `00035B03-58E6-07DD-021A-08123A000301`
- Notify: `00035B03-58E6-07DD-021A-08123A000302`

### Data Format

The SpectraCrop device sends data in a binary format. The format needs to be documented based on the device specification.

**Expected Data Fields:**
- F0 (UInt16)
- FMax (UInt16)
- TimeToFMax (Int32)
- FvDivFMax (Float)
- Vj (Float)
- M0 (Float)
- PI (Float)
- PPredict (Float)
- AbsoluteDifference (Float)
- Covariance (Float)
- Correlation (Float)

---

## 📦 Dependencies

### No External Dependencies

The app uses only Apple frameworks:
- SwiftUI
- CoreData
- CoreBluetooth
- CoreLocation
- Security (Keychain)
- Foundation
- UIKit (for AppDelegate)

### Future Considerations

If charts are needed beyond what's possible with SwiftUI native views, consider:
- Swift Charts (native, iOS 16+)
- Charts framework from Apple

---

## 🧪 Testing Strategy

### Unit Tests

Test each service independently using mock implementations:

```swift
class AuthManagerTests: XCTestCase {
    func testLogin() async {
        let mockAPI = MockAPIClient()
        let authManager = AuthManager(apiClient: mockAPI)
        
        await authManager.login(username: "test", password: "password")
        
        XCTAssertTrue(authManager.isLoggedIn)
    }
}
```

### UI Tests

Test user flows using XCTest:

```swift
class ReadingListUITests: XCTestCase {
    func testReadingListNavigation() {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to reading list
        app.tabBars.buttons["List"].tap()
        
        // Verify reading list is shown
        XCTAssertTrue(app.tables["ReadingList"].exists)
    }
}
```

---

## 🚨 Known Issues & Limitations

### 1. Bluetooth Data Parsing

**Status:** Not implemented

The `handleIncomingData(_:)` method in `BluetoothManager.swift` needs to be implemented based on the actual SpectraCrop device protocol.

### 2. HTTPS Certificate Pinning

**Status:** Not implemented

For production, implement certificate pinning to prevent MITM attacks.

### 3. Biometric Authentication

**Status:** Not implemented

Consider adding Face ID / Touch ID for app unlock.

### 4. Offline-First Architecture

**Status:** Partially implemented

The app stores data locally and syncs when online. Full offline-first with conflict resolution could be enhanced.

---

## 🎯 Next Steps

### Priority 1: Complete Core Implementation

1. [ ] Create all SwiftUI views
2. [ ] Implement Bluetooth data parsing
3. [ ] Add certificate pinning
4. [ ] Complete Core Data model

### Priority 2: Testing

1. [ ] Write unit tests for all services
2. [ ] Write UI tests for all user flows
3. [ ] Test on various iOS devices
4. [ ] Test with actual SpectraCrop hardware

### Priority 3: App Store Submission

1. [ ] Configure App Privacy Labels in App Store Connect
2. [ ] Host Privacy Policy at public URL
3. [ ] Update Info.plist with final URLs
4. [ ] Submit for review

---

## 📞 Support

For questions about:
- **Architecture:** Review this document and the source code
- **Bluetooth Protocol:** Contact hardware team for device specification
- **API Endpoints:** Review APIClient.swift and backend documentation
- **Testing:** See the Testing Strategy section

---

## 📚 References

- [Apple SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Core Data Documentation](https://developer.apple.com/documentation/coredata)
- [Core Bluetooth Documentation](https://developer.apple.com/documentation/corebluetooth)
- [Apple Privacy Manifest](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
