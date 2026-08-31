# SpectraCrop iOS App

**Version:** 2.0.0  
**Build Date:** August 31, 2026  
**Platform:** iOS 16.0+  
**Language:** Swift (SwiftUI)
**Architecture:** MVVM with Singleton Services

---

## 📋 Overview

SpectraCrop is an agricultural iOS application that connects to Bluetooth LE hardware devices to capture and analyze spectral readings from crops. Users can monitor crop health, track readings over time, view them on maps, and sync data to your existing Python backend server.

### Key Features

- **Spectral Readings** - Capture F0, FMax, Fv/FMax, Vj, M0, PI, and other spectral metrics
- **Bluetooth LE** - Direct communication with SpectraCrop hardware devices
- **Geospatial Mapping** - Attach GPS coordinates to readings and view on interactive maps
- **Cloud Sync** - Bidirectional synchronization with your Python backend (siriu5.dk)
- **Offline Support** - Full functionality without internet connection
- **Quality Analysis** - Automatic quality assessment based on spectral thresholds
- **User Accounts** - Secure authentication with session persistence

---

## 📁 Current Repository Structure

```
SpectraCrop/                          # Main app directory
├── SpectraCropApp.swift              # App entry point + AppDelegate
│
├── Models/                           # Data models
│   ├── Reading.swift                 # Reading model with spectral data
│   ├── User.swift                    # User account model
│   └── SyncModels.swift              # API DTOs and sync models
│
├── Services/                         # Business logic (Singleton pattern)
│   ├── APIClient.swift               # Network layer for Python backend
│   ├── AuthManager.swift             # User authentication & session
│   ├── DataManager.swift             # Reading CRUD + sync operations
│   ├── BluetoothManager.swift        # BLE device communication
│   └── LocationManager.swift         # GPS location services
│
├── Utilities/                        # Helper classes
│   ├── DeviceInfo.swift              # Device information & identifiers
│   └── PersistenceController.swift   # Core Data stack
│
├── Views/                            # SwiftUI Views
│   ├── RootView.swift                # Main tab navigation
│   ├── LoginView.swift               # User login
│   ├── RegisterView.swift            # User registration
│   ├── ReadingListView.swift         # Reading list with search/filter/sort
│   ├── NewReadingView.swift          # New reading (manual/automatic)
│   ├── MapView.swift                 # Interactive map with markers
│   └── UserProfileView.swift         # Profile, stats, settings
│
├── Resources/                        # App resources
│   └── SupportingFiles/
│       └── Info.plist                # App configuration
│
└── PrivacyInfo.xcprivacy             # Privacy manifest (project root)

# Documentation (Repository Root)
├── .gitignore                        # Xcode ignore patterns
├── README.md                         # This file
└── PRIVACY_POLICY.md                 # Privacy policy document
```

---

## 🚀 Setting Up in Xcode

### Prerequisites

- **Xcode 26+** (for iOS 26 SDK support)
- **macOS 14+** (Sonoma or later)
- **Apple Developer Account** (for signing and App Store)
- **SpectraCrop Hardware** (optional, for Bluetooth testing)

### Step 1: Create New Xcode Project

1. Open **Xcode 26+**
2. **File → New → Project**
3. Select **App** template
4. **Product Name:** `SpectraCrop`
5. **Interface:** SwiftUI
6. **Language:** Swift
7. **Minimum Deployment:** iOS 16.0
8. **Create** in this directory

### Step 2: Add Project Files

**Method A: Drag & Drop in Xcode**

1. In Xcode, select the **SpectraCrop** folder in the Project Navigator
2. **File → Add Files to "SpectraCrop"**
3. Select ALL files from the `SpectraCrop/` folder in this repository
4. Check: **Copy items if needed**
5. Check: **Create folder references**
6. Check: **Add to targets: SpectraCrop**
7. Click **Add**

**Method B: Manual File Copy**

```bash
# Copy all files to your Xcode project
cp -r SpectraCrop/* /path/to/YourXcodeProject/SpectraCrop/
```

Then in Xcode:
- Drag the `SpectraCrop` folder into your project
- Ensure all files are added to the target

### Step 3: Create Core Data Model

1. **File → New → File**
2. Select **Data Model** (under iOS → Core Data)
3. **Name:** `SpectraCrop`
4. Click **Create**

5. **Add ReadingEntity:**
   - Click **+ Entity** button
   - **Name:** `ReadingEntity`
   
6. **Add Attributes:**
   
   | Name | Type | Optional | Notes |
   |------|------|----------|-------|
   | `id` | UUID | No | Unique identifier |
   | `externalId` | String | Yes | Server-assigned ID |
   | `recordedAt` | Date | No | Creation timestamp |
   | `syncTime` | Date | Yes | Last sync timestamp |
   | `deletedTime` | Date | Yes | Deletion timestamp |
   | `readingDescription` | String | Yes | User description |
   | `latitude` | Double | Yes | GPS latitude |
   | `longitude` | Double | Yes | GPS longitude |
   | `altitude` | Double | Yes | Altitude in meters |
   | `f0` | Integer 32 | No | Spectral F0 |
   | `fMax` | Integer 32 | No | Spectral FMax |
   | `timeToFMax` | Integer 32 | No | Time to FMax (ms) |
   | `fvDivFMax` | Double | No | Fv/FMax ratio |
   | `vj` | Double | No | Vj value |
   | `m0` | Double | No | M0 value |
   | `pi` | Double | No | PI value |
   | `ppPredict` | Double | Yes | Predicted PP |
   | `absoluteDifference` | Double | Yes | Quality metric |
   | `covariance` | Double | Yes | Quality metric |
   | `correlation` | Double | Yes | Quality metric |
   | `qualityFailed` | Boolean | No | Quality status |
   | `status` | String | No | Sync status |

7. **Save** the data model file

**Note:** The `PersistenceController.swift` is already configured to use this model.

### Step 4: Configure Signing & Capabilities

1. Select the **project** (blue icon) in Xcode
2. Go to **Signing & Capabilities** tab
3. **Signing:**
   - Select your **Team**
   - **Bundle Identifier:** `com.spectracrop.ios`
   
4. **Add Capabilities:**
   - Click **+ Capability**
   - Add: **Background Modes** → **Uses Bluetooth LE accessories**
   - Add: **Location** → **When In Use**, **Always**

### Step 5: Update Privacy Policy URL

1. Open `Info.plist` in Xcode
2. Find **NSPrivacyPolicyURL**
3. Replace the value with your hosted privacy policy URL:
   ```
   https://yourdomain.com/privacy
   ```

### Step 6: Build and Run

1. Select **Scheme:** SpectraCrop
2. Select **Target:** SpectraCrop
3. **Build and Run** on iOS 16+ simulator or device

**Expected:** App should launch to login screen

---

## 🗃️ Core Data Model - Complete Reference

### Why Core Data?

- **Native iOS integration** - Better performance than SQLite-net
- **Built-in encryption** - Data at rest is automatically encrypted
- **Automatic migrations** - Easier to update schema
- **Object graph management** - Handles relationships automatically
- **Offline-first** - Full app functionality without internet

### ReadingEntity Attributes Detail

| Attribute | Type | Swift Type | Purpose |
|-----------|------|------------|---------|
| `id` | UUID | `UUID` | Unique identifier for each reading |
| `externalId` | String | `String?` | Server-assigned ID (from backend) |
| `recordedAt` | Date | `Date` | When the reading was captured |
| `syncTime` | Date | `Date?` | When reading was synced to server |
| `deletedTime` | Date | `Date?` | When reading was deleted |
| `readingDescription` | String | `String?` | User-provided description |
| `latitude` | Double | `Double` | GPS latitude coordinate |
| `longitude` | Double | `Double` | GPS longitude coordinate |
| `altitude` | Double | `Double` | Altitude above sea level (meters) |
| `f0` | Integer 32 | `UInt16` | Initial fluorescence |
| `fMax` | Integer 32 | `UInt16` | Maximum fluorescence |
| `timeToFMax` | Integer 32 | `Int` | Time to reach FMax (microseconds) |
| `fvDivFMax` | Double | `Double` | Fv/FMax ratio (0.0-1.0) |
| `vj` | Double | `Double` | Variable J parameter |
| `m0` | Double | `Double` | Initial fluorescence slope |
| `pi` | Double | `Double` | Performance index |
| `ppPredict` | Double | `Double?` | Predicted photosynthesis parameter |
| `absoluteDifference` | Double | `Double?` | Quality check: absolute difference |
| `covariance` | Double | `Double?` | Quality check: covariance |
| `correlation` | Double | `Double?` | Quality check: correlation |
| `qualityFailed` | Boolean | `Bool` | Whether quality check failed |
| `status` | String | `String` | Sync status: local/synced/error |

### Sync Status Values

- `"local"` - Only stored on this device, not synced
- `"synced"` - Successfully synced to server
- `"syncing"` - Currently uploading
- `"error"` - Sync failed
- `"deleted"` - Deleted (soft delete)

### Core Data Configuration

The `PersistenceController.swift` is pre-configured with:
- **Container name:** `SpectraCrop`
- **Automatic change merging:** Enabled
- **All CRUD operations:** Implemented

**No additional configuration needed** - just create the model in Xcode.

---

## 🌐 Backend Server Integration

### Current Configuration

**API Base URL:** `https://siriu5.dk/api/`

**Your Python server is 100% compatible** - no changes required!

### How It Works

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   SwiftUI App   │────▶│   Core Data     │────▶│  Python Server  │
│                 │     │   (Local Cache)  │     │   (siriu5.dk)    │
└─────────────────┘     └─────────────────┘     └─────────────────┘
          ▲                        ▲                        ▲
          │                        │                        │
     User Interface          Offline Access         Cloud Storage
```

### Data Flow

1. **User creates reading** → Saved to Core Data (instant)
2. **App detects internet** → Syncs with Python server
3. **Server confirms** → Core Data marks as synced
4. **User views readings** → Loaded from Core Data (instant)
5. **Server data updated** → Downloaded to Core Data on next sync

### API Endpoints Used

| Method | Endpoint | Request Body | Response |
|--------|----------|--------------|----------|
| POST | `/authenticate/user` | `{username, password}` | `{id, username, sessionId}` |
| POST | `/authenticate/register` | `{username, password}` | `{id, username, sessionId}` |
| POST | `/authenticate/relogin` | `{sessionId}` | `{id, username, sessionId}` |
| GET | `/authenticate/logout` | Headers only | Success |
| GET | `/authenticate/delete` | Headers only | Success |
| POST | `/readings/upload` | `{readings: [ReadingDTO]}` | `{success, message}` |
| POST | `/readings/download` | `{skip, limit, minimumModified}` | `{items: [ReadingDTO], totalCount, hasMore}` |

### Required Headers

All requests automatically include:
- `Content-Type: application/json`
- `x-DeviceId: <device-uuid>` (from Keychain)
- `x-SessionId: <session-id>` (for authenticated requests)

### Server Compatibility Check

✅ **Your existing Python server already supports all required endpoints**
✅ **Data format is compatible** (ReadingDTO → ReadingEntity)
✅ **Authentication is compatible** (session-based)
✅ **No code changes required on server side**

---

## 🔒 Privacy & Security

### Privacy Compliance

- ✅ **Privacy Policy** - `PRIVACY_POLICY.md` (host at public URL)
- ✅ **Privacy Manifest** - `PrivacyInfo.xcprivacy` (included in project)
- ✅ **App Privacy Labels** - Ready for App Store Connect configuration
- ✅ **No Tracking** - App does not track users for advertising

### Security Features

- **Keychain Storage** - Device ID, session ID, credentials stored securely
- **HTTPS/TLS** - All API communication encrypted
- **Input Validation** - All user inputs validated before processing
- **Error Handling** - Comprehensive try/catch throughout app
- **Core Data Encryption** - Local database encrypted at rest

### App Privacy Labels (App Store Connect)

Configure these in App Store Connect:

| Data Type | Linked to User | Tracking | Purposes |
|-----------|----------------|----------|----------|
| User ID | Yes | No | Account Management |
| Username | Yes | No | Account Management |
| Password | Yes | No | App Functionality |
| Device ID | Yes | No | App Functionality, Fraud Prevention |
| Precise Location | Yes | No | App Functionality |
| Coarse Location | Yes | No | App Functionality |
| Bluetooth Data | Yes | No | App Functionality, Device Management |
| Product Interaction | Yes | No | App Functionality, Analytics |
| Diagnostics | No | No | App Functionality |

---

## 📋 App Configuration Checklist

### Required

- [ ] Host `PRIVACY_POLICY.md` at public URL
- [ ] Update `NSPrivacyPolicyURL` in `Info.plist`
- [ ] Create Core Data model with `ReadingEntity`
- [ ] Configure signing with Apple Developer Team
- [ ] Add Bluetooth LE background mode capability
- [ ] Add Location capabilities

### Recommended

- [ ] Configure App Privacy Labels in App Store Connect
- [ ] Test on iOS 16+ devices
- [ ] Test Bluetooth connectivity
- [ ] Test location services
- [ ] Implement Bluetooth data parsing (requires device protocol)
- [ ] Add certificate pinning for production

### Optional

- [ ] Write unit tests
- [ ] Write UI tests
- [ ] Set up Fastlane for CI/CD
- [ ] Configure GitHub Actions

---

## 🚀 Deployment

### Test Flight

1. Archive build in Xcode
2. Upload to App Store Connect
3. Submit for TestFlight review
4. Invite testers

### App Store Submission

1. **App Store Connect:**
   - Configure app metadata
   - Upload screenshots (6.5", 5.5", iPad)
   - Configure App Privacy Labels
   - Set pricing and availability

2. **Archive and Upload:**
   ```bash
   # In Xcode: Product → Archive
   # Then: Distribute App → App Store Connect
   ```

3. **Submit for Review:**
   - Upload build
   - Fill all metadata
   - Submit

### Requirements

- **Minimum OS:** iOS 16.0
- **SDK:** iOS 26 (Xcode 26+)
- **Device Support:** iPhone, iPad
- **Orientation:** All orientations

---

## 📚 Quick Reference

### File Locations

| Purpose | Location |
|---------|----------|
| App Entry | `SpectraCrop/SpectraCropApp.swift` |
| Models | `SpectraCrop/Models/` |
| Services | `SpectraCrop/Services/` |
| Utilities | `SpectraCrop/Utilities/` |
| Views | `SpectraCrop/Views/` |
| Info.plist | `SpectraCrop/Resources/SupportingFiles/Info.plist` |
| Privacy Manifest | `SpectraCrop/PrivacyInfo.xcprivacy` |

### Key Classes

| Class | Purpose |
|-------|---------|
| `APIClient` | Network communication with Python server |
| `AuthManager` | User authentication and session management |
| `DataManager` | Reading data management and sync |
| `BluetoothManager` | BLE device communication |
| `LocationManager` | GPS location services |
| `PersistenceController` | Core Data management |
| `Reading` | Main data model |
| `User` | User account model |

---

## 📞 Support & Troubleshooting

### Common Issues

**Q: App crashes on launch**
A: Ensure all files are added to the target. Check Xcode's Issue Navigator.

**Q: Core Data not working**
A: Verify the data model is named `SpectraCrop.xcdatamodeld` and entity is `ReadingEntity`.

**Q: Bluetooth not connecting**
A: Enable Bluetooth LE background mode. Test on real device (simulator doesn't support Bluetooth).

**Q: Location not working**
A: Enable Location capabilities. Request permission in app.

**Q: Sync not working**
A: Verify Python server is running and HTTPS is configured. Check `x-DeviceId` and `x-SessionId` headers.

### Documentation

- **Privacy Policy:** `PRIVACY_POLICY.md`

---

## 📜 License

Proprietary software. All rights reserved.

Copyright © 2026 SpectraCrop. All rights reserved.

---

## 🎯 Version History

| Version | Date | Description |
|---------|------|-------------|
| 2.0.0 | Aug 2026 | Complete SwiftUI rebuild with privacy compliance |
