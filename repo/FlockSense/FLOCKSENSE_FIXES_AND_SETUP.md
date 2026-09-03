# FlockSense — Complete Architecture, Fixes & Setup Guide

## 📋 Executive Summary
This document contains the complete technical record of all problems diagnosed, architectural improvements implemented, and verification steps performed for **FlockSense**.

---

## 🛠️ 1. Problems Diagnosed & Solved

### A. Dashboard Showing 0 Active Batches & 0 Live Birds
* **The Problem**: On the Home Dashboard, the "Active Batches" KPI showed `0`, "Live Birds" showed `0`, and the batch carousel showed `"No live flocks in shed"`, even when batches existed in Firestore.
* **Root Cause**: The application relied on Firestore `collectionGroup('batches').where('ownerId', isEqualTo: user.uid)`. In Firestore, querying collection groups with a `.where()` clause requires a custom `COLLECTION_GROUP_ASC` index in Firebase Console. Because this index was not configured in the Firebase project, Firestore threw `[cloud_firestore/failed-precondition] The query requires a COLLECTION_GROUP_ASC index...`. The `.handleError((_) => <BatchModel>[])` block silently swallowed this error and emitted an empty list `[]`.
* **Solution (Direct Subcollection Stream Architecture)**:
  - Replaced the failing collection group queries with **`BatchService.watchAllUserBatches(uid)`**.
  - Directly streams the user's farms from `/users/{uid}/farms` and dynamically binds listeners to each farm's `/users/{uid}/farms/{farmId}/batches` subcollection.
  - Automatically merges, sorts (active first), and emits the live batches in real time.
  - Requires **zero cloud indexes** in Firebase Console.
  - Works **100% offline** via Firestore's local disk cache.
  - Computes `liveBirds` using `sum + (b.currentBirds > 0 ? b.currentBirds : b.totalBirds)` so newly placed flocks display their live bird population immediately.

---

### B. Daily Records Across Multiple Farms Not Saving
* **The Problem**: Farmers with multiple farms could not save daily records properly. When switching farms or logging records, the data either failed to save or saved with mismatched IDs.
* **Root Causes**:
  1. `daily_records_dashboard_screen.dart` used a hardcoded 3-second timeout (`.timeout(Duration(seconds: 3))`) on `FarmService.getUserFarms()` and `BatchService.getBatchesByFarmId()`. On cellular/mobile networks, this timeout triggered frequently and silently fell back to an in-memory dummy batch `_defaultBatch` (`id: 'default_batch'`, `farmId: 'default_farm'`), corrupting records and failing Firestore writes.
  2. The farm dropdown `onChanged` fired `_loadBatchesForFarm(farmId)` without `await`, causing race conditions where `_selectedBatch` remained pointing to a batch from the previous farm.
  3. Saves hardcoded `DateTime.now()`, preventing farmers from backfilling or recording data for yesterday across different facilities.
  4. Firestore security rules did not allow subcollection writes under `/batches/{batchId}/dailyRecords/{recordId}`.
* **Solutions**:
  - Removed all artificial 3-second timeouts. Added `_isLoadingBatches` progress indicators and empty state cards with an **"Add Batch to Farm"** button.
  - Added safe `await` handling in the farm dropdown: resets batch state, clears previous selections, and binds the new farm's batches cleanly.
  - Introduced `_selectedRecordDate` with quick selector chips for **Today**, **Yesterday**, and a custom **Calendar Date Picker**.
  - Updated `firestore.rules` to permit owner access to all subcollections under `/users/{uid}/**`.

---

### C. Login & Phone OTP Registration Issues
* **The Problem**: Phone authentication failed during OTP entry; registering via phone did not create a Firestore profile document; Email/Password registration was inaccessible; and the Login screen lacked a phone option.
* **Root Causes**:
  1. `OtpVerificationScreen` was hardcoded to 4 digits (`List.generate(4, ...)`), whereas Firebase Phone SMS codes are 6 digits.
  2. `CreatePasswordScreen` for phone auth only called `updateDisplayName()`, omitting the Firestore user document creation.
  3. `AppRoutes.register` had been routed to `RegistrationMethodScreen`, locking out the full `RegisterScreen` (Email/Password).
  4. `LoginScreen` lacked a direct "Sign in with Phone Number" button.
* **Solutions**:
  - Upgraded `OtpVerificationScreen` to 6 responsive boxes (`46x56`), with auto-focus advancing, 6-digit validation, clipboard paste, and auto-verification.
  - Added user document initialization in `CreatePasswordScreen` (`uid`, `name`, `phone`, `role: 'owner'`, timestamps).
  - Configured `AppRoutes.register` for `RegisterScreen` and `AppRoutes.phoneAuth` for `RegistrationMethodScreen`.
  - Added **"Sign in with Phone Number"** to `LoginScreen`.

---

## 📂 2. Key Files Modified

| Component | File Path | Key Changes |
| :--- | :--- | :--- |
| **Batch Service** | [`lib/features/batches/data/batch_service.dart`](file:///c:/MyProject/repo/FlockSense/lib/features/batches/data/batch_service.dart) | Added `watchAllUserBatches(uid)` direct reactive multi-farm stream. |
| **Daily Record Service** | [`lib/features/daily_records/data/daily_record_service.dart`](file:///c:/MyProject/repo/FlockSense/lib/features/daily_records/data/daily_record_service.dart) | Added `watchAllUserDailyRecords(uid)` direct multi-batch stream without collection group index. |
| **Shed Service** | [`lib/features/sheds/data/shed_service.dart`](file:///c:/MyProject/repo/FlockSense/lib/features/sheds/data/shed_service.dart) | Added `watchAllUserSheds(uid)` direct multi-farm stream. |
| **Home Dashboard Provider** | [`lib/features/home/presentation/providers/home_dashboard_provider.dart`](file:///c:/MyProject/repo/FlockSense/lib/features/home/presentation/providers/home_dashboard_provider.dart) | Connected `allUserBatchesProvider`, `recentDailyRecordsProvider`, reactive `todayMortalityProvider`, and `liveBirds` calculations. |
| **Farm Providers** | [`lib/features/farms/presentation/providers/farm_providers.dart`](file:///c:/MyProject/repo/FlockSense/lib/features/farms/presentation/providers/farm_providers.dart) | Replaced collection group queries with `BatchService.watchAllUserBatches` and `ShedService.watchAllUserSheds`. |
| **Daily Records Dashboard** | [`lib/features/daily_records/presentation/screens/daily_records_dashboard_screen.dart`](file:///c:/MyProject/repo/FlockSense/lib/features/daily_records/presentation/screens/daily_records_dashboard_screen.dart) | Removed 3s timeouts, fixed farm dropdown switching, added date picker (Today/Yesterday/Custom), and integrated batch creation button. |
| **Home Screen** | [`lib/features/home/presentation/screens/home_screen.dart`](file:///c:/MyProject/repo/FlockSense/lib/features/home/presentation/screens/home_screen.dart) | Updated `activeBatches` filter to use `b.isActive`. |
| **OTP Verification** | [`lib/features/auth/presentation/screens/otp_verification_screen.dart`](file:///c:/MyProject/repo/FlockSense/lib/features/auth/presentation/screens/otp_verification_screen.dart) | Upgraded from 4 to 6 digits, paste handling, and responsive layout. |
| **Create Password** | [`lib/features/auth/presentation/screens/create_password_screen.dart`](file:///c:/MyProject/repo/FlockSense/lib/features/auth/presentation/screens/create_password_screen.dart) | Created Firestore user document upon phone registration. |
| **Login Screen** | [`lib/features/auth/presentation/screens/login_screen.dart`](file:///c:/MyProject/repo/FlockSense/lib/features/auth/presentation/screens/login_screen.dart) | Added "Sign in with Phone Number" button. |
| **App Routes** | [`lib/config/routes/app_routes.dart`](file:///c:/MyProject/repo/FlockSense/lib/config/routes/app_routes.dart) | Separated `/register` and `/phone-auth`. |
| **Firestore Security Rules** | [`firestore.rules`](file:///c:/MyProject/repo/FlockSense/firestore.rules) | Scoped user document subcollections and enabled full owner access. |

---

## 🧪 3. Verification Results

### Unit & Widget Tests
Executed automated test suite:
```bash
flutter test
```
**Result**:
```
00:04 +49: All tests passed!
```
All 49 unit and widget tests passed cleanly.

### Debug APK Build
```bash
flutter build apk --debug
```
**Result**:
```
Running Gradle task 'assembleDebug'...                             45.5s
√ Built build\app\outputs\flutter-apk\app-debug.apk
```

### Device Installation & Verification
* **Target Mobile Device**: Vivo V2504 / T4 Ultra (Device ID: `10BG6E03430044T`)
* **Installation**: Streamed APK install completed with status `Success`.
* **Execution**: Started `com.flocksense.app/.MainActivity`. Impeller Vulkan engine and cache services verified active.

---

## 🚀 4. Useful Commands for Future Development

### Run Tests
```powershell
flutter test
```

### Build Debug APK
```powershell
flutter build apk --debug
```

### Install Directly to Connected Phone
```powershell
& "C:\Users\Disa V\AppData\Local\Android\Sdk\platform-tools\adb.exe" install -r build\app\outputs\flutter-apk\app-debug.apk
```

### Launch App on Phone
```powershell
& "C:\Users\Disa V\AppData\Local\Android\Sdk\platform-tools\adb.exe" shell am start -n com.flocksense.app/.MainActivity
```

### Check Live Phone Logs
```powershell
& "C:\Users\Disa V\AppData\Local\Android\Sdk\platform-tools\adb.exe" logcat -d -s flutter
```
