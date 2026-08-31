# SpectraCrop iOS App

**Version:** 2.0.0  
**Build Date:** August 31, 2026  
**Platform:** iOS 16.0+  
**Language:** Swift (SwiftUI)

---

## 📋 Overview

SpectraCrop is an agricultural iOS application that connects to Bluetooth LE hardware devices to capture and analyze spectral readings from crops. The app allows farmers and agricultural researchers to monitor crop health, track readings over time, and sync data to a cloud backend.

### Key Features

- **Spectral Readings** - Capture F0, FMax, Fv/FMax, and other spectral metrics
- **Bluetooth LE** - Direct communication with SpectraCrop hardware
- **Geospatial Mapping** - Attach GPS coordinates to readings and view on maps
- **Data Sync** - Cloud synchronization across devices
- **Quality Analysis** - Automatic quality assessment of readings
- **User Accounts** - Secure authentication and data ownership

---

## 🚀 Getting Started

### Prerequisites

- Xcode 26+ (for iOS 26 SDK support)
- macOS 14+ (Sonoma or later)
- Apple Developer Account (for App Store distribution)
- SpectraCrop Hardware Device (for Bluetooth testing)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-org/spectracrop.git
   cd spectracrop
   ```

2. **Open in Xcode:**
   ```bash
   open SpectraCrop/SpectraCrop.xcodeproj
   ```

3. **Set up signing:**
   - Configure your Apple Developer Team in Xcode
   - Update bundle identifier: `com.spectracrop.ios`

4. **Create Core Data Model:**
   - The app uses Core Data for local storage
   - The data model should be automatically created when the app first runs
   - If issues occur, create a new Data Model file named `SpectraCrop.xcdatamodeld`
   - Add entity: `ReadingEntity` with all required attributes

5. **Update Privacy Policy URL:**
   - Edit `Info.plist` and update `NSPrivacyPolicyURL` to your hosted privacy policy
   - Or update it in the project settings

6. **Build and Run:**
   - Select target: `SpectraCrop`
   - Select scheme: `SpectraCrop`
   - Build and run on iOS 16+ simulator or device

---

## 📂 Project Structure

```
SpectraCrop/
├── SpectraCropApp.swift          # App entry point
├── Sources/
│   ├── Models/                  # Data models
│   │   ├── Reading.swift         # Reading data model
│   │   ├── User.swift            # User data model
│   │   └── SyncModels.swift      # API DTOs
│   │
│   ├── ViewModels/              # View models (MVVM)
│   │   └── (View models for each feature)
│   │
│   ├── Views/                   # SwiftUI Views
│   │   ├── RootView.swift        # Main navigation
│   │   ├── LoginView.swift       # Authentication
│   │   ├── ReadingListView.swift # Reading list
│   │   ├── NewReadingView.swift  # New reading creation
│   │   ├── MapView.swift         # Geospatial mapping
│   │   └── UserProfileView.swift # User profile
│   │
│   ├── Services/                # Business logic
│   │   ├── APIClient.swift       # Network layer
│   │   ├── AuthManager.swift     # Authentication
│   │   ├── DataManager.swift     # Data management
│   │   ├── BluetoothManager.swift # Bluetooth LE
│   │   └── LocationManager.swift # Location services
│   │
│   └── Utilities/               # Helper classes
│       ├── DeviceInfo.swift      # Device information
│       ├── KeychainService.swift # Secure storage
│       └── PersistenceController.swift # Core Data
│
├── Resources/
│   └── Assets.xcassets/        # Images, colors, etc.
│
├── PrivacyInfo.xcprivacy        # Privacy manifest
├── Info.plist                  # App configuration
└── SpectraCrop.xcodeproj        # Xcode project
```

---

## 🔧 Configuration

### Privacy Policy

The app requires a privacy policy to be hosted at a public URL. Update the following:

1. **In `Info.plist`:**
   ```xml
   <key>NSPrivacyPolicyURL</key>
   <string>https://yourdomain.com/privacy</string>
   ```

2. **Privacy Manifest:**
   - `PrivacyInfo.xcprivacy` is included in the project
   - Declares all data types collected by the app
   - Must match actual app behavior

3. **App Store Connect:**
   - Configure App Privacy Labels to match `PrivacyInfo.xcprivacy`

### API Configuration

The app communicates with the backend API at:
```
https://siriu5.dk/api/
```

To change the API endpoint, modify `APIClient.swift`:
```swift
private let baseURL = URL(string: "YOUR_API_ENDPOINT")!
```

### Capabilities

The app requires the following capabilities:

1. **Background Modes:**
   - Enable "Uses Bluetooth LE accessories"

2. **Location:**
   - Enable "When In Use" usage description
   - Enable "Always" usage description

3. **Bluetooth:**
   - Enable "Uses Bluetooth LE accessories"
   - Usage descriptions are in `Info.plist`

---

## 📱 Features

### Authentication

- **Login/Registration** - Secure user authentication
- **Session Persistence** - Automatic relogin with saved session
- **Account Management** - Delete account functionality

### Readings

- **Manual Entry** - Enter spectral data manually
- **Automatic Capture** - Read from Bluetooth device
- **Quality Assessment** - Automatic quality checks
- **List View** - Browse all readings with sorting/filtering
- **Detail View** - View all spectral data
- **Delete** - Remove unwanted readings

### Mapping

- **Geospatial Display** - View readings on interactive map
- **Location Tagging** - Attach GPS coordinates to readings
- **Marker Display** - Quality indicators on map

### Data Sync

- **Automatic Sync** - Sync when app becomes active
- **Manual Sync** - On-demand synchronization
- **Offline Support** - Local storage with cloud backup

---

## 🔒 Security

### Data Protection

- **Keychain Storage** - Sensitive data (session ID, device ID) stored securely
- **Secure Transmission** - All API calls use HTTPS
- **Input Validation** - All user inputs are validated

### Privacy Compliance

- **Privacy Manifest** - Full disclosure of data collection
- **Privacy Policy** - Publicly accessible policy
- **App Privacy Labels** - Transparent data practices
- **No Tracking** - App does not track users for advertising

---

## 📊 Architecture

### MVVM Pattern

```
View (SwiftUI) <-> ViewModel <-> Service <-> Model (Data)
```

- **Views:** SwiftUI components (in `Views/`)
- **ViewModels:** Business logic for views (in `ViewModels/`)
- **Services:** Shared business logic (in `Services/`)
- **Models:** Data structures (in `Models/`)

### Dependency Injection

Services are injected as environment objects:

```swift
@main
struct SpectraCropApp: App {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
        }
    }
}
```

### Singleton Services

Services use singleton pattern for shared state:

- `AuthManager.shared` - Authentication state
- `DataManager.shared` - Reading data state
- `BluetoothManager.shared` - Bluetooth device state
- `LocationManager.shared` - Location state
- `PersistenceController.shared` - Core Data stack

---

## 🔌 Bluetooth LE

### Device Connection

The app connects to SpectraCrop hardware devices using Bluetooth LE.

**Service UUID:** `00035B03-58E6-07DD-021A-08123A000300`

**Characteristics:**
- Write: `00035B03-58E6-07DD-021A-08123A000301`
- Notify: `00035B03-58E6-07DD-021A-08123A000302`

### Data Format

The device sends spectral data in binary format. The app parses this data into the following fields:

- F0 (UInt16)
- FMax (UInt16)
- TimeToFMax (Int)
- FvDivFMax (Double)
- Vj (Double)
- M0 (Double)
- PI (Double)
- PPredict (Double?)
- AbsoluteDifference (Double?)
- Covariance (Double?)
- Correlation (Double?)

---

## 🧪 Testing

### Unit Tests

Run unit tests:
```bash
xcodebuild test -scheme SpectraCrop -destination 'platform=iOS Simulator,name=iPhone 15'
```

### UI Tests

UI tests are located in the `Tests/` directory.

### Manual Testing

Test on various devices and iOS versions (16.0+).

---

## 🚀 Deployment

### App Store Submission

1. **Configure in App Store Connect:**
   - Create app entry
   - Configure App Privacy Labels
   - Upload screenshots
   - Add privacy policy URL

2. **Archive and Upload:**
   ```bash
   xcodebuild archive -scheme SpectraCrop -archivePath ./SpectraCrop.xcarchive
   xcodebuild -exportArchive -archivePath ./SpectraCrop.xcarchive -exportPath ./Export -exportOptionsPlist ExportOptions.plist
   ```

3. **Submit for Review:**
   - Upload build in App Store Connect
   - Fill in all metadata
   - Submit for App Store review

### Requirements

- **iOS Version:** 16.0+
- **SDK:** iOS 26 SDK (Xcode 26+)
- **Device Support:** iPhone and iPad
- **Orientation:** All orientations supported

---

## 📚 Documentation

- **Privacy Compliance:** See `PRIVACY_CHANGES.md`
- **Rebuild Guide:** See `SWIFTUI_REBUILD_GUIDE.md`
- **API Documentation:** See backend API documentation
- **Bluetooth Protocol:** See hardware specification

---

## 📞 Support

- **Developer:** SpectraCrop Development Team
- **Email:** support@spectracrop.com
- **Website:** https://spectracrop.com
- **Documentation:** https://docs.spectracrop.com

---

## 📜 License

Proprietary software. All rights reserved.

Copyright © 2026 SpectraCrop. All rights reserved.

---

## 🎯 Version History

| Version | Date | Description |
|---------|------|-------------|
| 2.0.0 | Aug 2026 | Complete SwiftUI rebuild, privacy compliance |
| 1.1.14 | 2023 | Legacy Xamarin.Forms version |
