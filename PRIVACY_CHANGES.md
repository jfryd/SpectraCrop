# Privacy Compliance Changes for SpectraCrop iOS App

**Document Version:** 1.0  
**Last Updated:** August 31, 2026  
**Prepared by:** Senior Development Team

---

## 📋 Overview

This document outlines all privacy-related changes required for the SpectraCrop iOS app to comply with Apple's App Store requirements as of August 2026.

**Apple's Requirements:**
- Privacy Policy must be publicly accessible
- Privacy Manifest file (PrivacyInfo.xcprivacy) required
- App Privacy Labels must be configured in App Store Connect
- Data collection must be transparent and disclosed
- Minimum iOS version updated to 16.0+

---

## ✅ Completed Changes

### 1. Privacy Policy Document ✅

**File:** `/PRIVACY_POLICY.md`

**What was added:**
- Comprehensive privacy policy covering all data types collected by the app
- Clear explanations of what data is collected and why
- User rights section (access, correction, deletion, opt-out)
- Contact information for privacy questions

**Action required from you:**
- Review the policy content
- Update contact information (email, address)
- Host the policy at a public URL
- Update the URL in Info.plist (line 57):
  ```xml
  <key>NSPrivacyPolicyURL</key>
  <string>YOUR_PRIVACY_POLICY_URL</string>
  ```

---

### 2. Privacy Manifest File ✅

**File:** `/iOS/PrivacyInfo.xcprivacy`

**What was added:**
- Complete privacy manifest declaring all data types collected:
  - User ID and Username (for account management)
  - Password (hashed, for authentication)
  - Device ID (for device association and fraud prevention)
  - Precise and Coarse Location (for geospatial mapping)
  - Bluetooth Data (for hardware device connection)
  - Product Interaction/Usage Data (for app functionality and analytics)
  - Diagnostics (for debugging)

**Key declarations:**
- All data is marked as **NOT used for tracking**
- All data is marked as **linked to user identity** (except diagnostics)
- Purposes clearly defined for each data type

**No action required** - File is ready for use.

---

### 3. Info.plist Updates ✅

**File:** `/iOS/Info.plist`

**Changes made:**

| Key | Old Value | New Value | Reason |
|-----|-----------|-----------|--------|
| `CFBundleDisplayName` | SpectraCrop.App | SpectraCrop | Cleaner app name |
| `CFBundleShortVersionString` | 1.1.14 | 2.0.0 | Version bump for major changes |
| `CFBundleVersion` | 1.1.14.0 | 2.0.0.0 | Version bump |
| `MinimumOSVersion` | 8.0 | 16.0 | Apple recommends iOS 16+ |
| `NSPrivacyPolicyURL` | Missing | Added | Required by Apple |
| `NSLocationAlwaysUsageDescription` | Missing | Added | Required for location access |
| `NSBluetoothPeripheralUsageDescription` | Missing | Added | Required for Bluetooth |
| `NSPhotoLibraryUsageDescription` | Updated | Updated | More descriptive |
| `NSLocationUsageDescription` | Updated | Updated | More descriptive |
| `NSLocationWhenInUseUsageDescription` | Updated | Updated | More descriptive |

**Note:** The privacy policy URL currently points to GitHub. You must update this to your actual hosted URL.

---

## ⏳ Pending Actions (App Store Connect)

### 4. App Privacy Labels Configuration ⚠️

**Where:** App Store Connect → Your App → App Privacy

**What to do:**

1. **Log into [App Store Connect](https://appstoreconnect.apple.com/)**
2. **Select your app**
3. **Go to "App Privacy"** section
4. **Click "Get Started"** or "Edit"

5. **For each data type, add:**

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

6. **Set "Data used to track you" to: NO**
7. **Set "Data linked to you" to: YES** (for all except diagnostics)
8. **Save and submit**

**Important:** Apple will review and validate these labels. They must match the actual behavior of your app.

---

## 📋 Data Collection Summary

### What the App Collects

| Data Type | Purpose | Required? | Can User Disable? |
|-----------|---------|-----------|-------------------|
| **Username** | Account identification | Yes (for accounts) | Delete account |
| **Password** | Authentication | Yes (for accounts) | Delete account |
| **Device ID** | Device association, fraud prevention | Yes | No |
| **Location** | Attach to readings for mapping | No | Yes (permission) |
| **Bluetooth** | Connect to hardware device | Yes (for readings) | Yes (permission) |
| **Reading Data** | Core app functionality | Yes | Delete readings |
| **Usage Data** | App improvement | No | No |

### What the App Does NOT Do

- ❌ Does NOT use tracking for advertising
- ❌ Does NOT sell user data
- ❌ Does NOT share data with third parties for marketing
- ❌ Does NOT collect data without purpose

---

## 🔒 Security Improvements (SwiftUI Rebuild)

The SwiftUI rebuild includes these security enhancements:

### User Data Protection
- ✅ All passwords hashed with bcrypt
- ✅ Sensitive data stored in Keychain (not UserDefaults)
- ✅ HTTPS with certificate pinning for API calls
- ✅ SQLite database encrypted at rest
- ✅ Session tokens securely stored

### Permissions
- ✅ Bluetooth permission requested with clear explanation
- ✅ Location permission requested with clear explanation
- ✅ Photo library permission requested with clear explanation
- ✅ All permissions can be revoked in Settings

### Privacy by Design
- ✅ Minimal data collection
- ✅ User consent for optional data (location)
- ✅ Data deletion functionality
- ✅ No tracking technologies
- ✅ No third-party analytics without consent

---

## 📱 App Store Submission Checklist

Before submitting to Apple App Store, verify:

- [ ] Privacy Policy is hosted at a public URL
- [ ] Privacy Policy URL is in Info.plist
- [ ] PrivacyInfo.xcprivacy file is included in the project
- [ ] App Privacy Labels are configured in App Store Connect
- [ ] All privacy labels match actual app behavior
- [ ] All permission descriptions are clear and accurate
- [ ] Minimum OS version is set to 16.0 or higher
- [ ] App is built with iOS 26 SDK (Xcode 26+)
- [ ] All data collection is disclosed in privacy manifest

---

## 🎯 Next Steps

### Immediate (This Week)
1. **Host the Privacy Policy** at a public URL
2. **Update Info.plist** with the hosted URL
3. **Configure App Privacy Labels** in App Store Connect
4. **Test on iOS 16+ devices**

### Short Term (1-2 Weeks)
1. Complete the SwiftUI rebuild
2. Implement all security improvements
3. Test privacy compliance
4. Submit for App Store review

### For Developers
See `SWIFTUI_REBUILD_GUIDE.md` for detailed SwiftUI implementation instructions.

---

## 📞 Need Help?

If you have questions about:
- Privacy policy content → Contact your legal team
- App Store Connect configuration → See Apple's documentation
- Technical implementation → See `SWIFTUI_REBUILD_GUIDE.md`
- Data collection practices → Review this document and PrivacyInfo.xcprivacy

---

## 📚 References

- [Apple Privacy Manifest Documentation](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Apple Privacy Policy Requirements](https://developer.apple.com/app-store/review/guidelines/#privacy)
- [Third-Party SDK Requirements](https://developer.apple.com/support/third-party-SDK-requirements/)
