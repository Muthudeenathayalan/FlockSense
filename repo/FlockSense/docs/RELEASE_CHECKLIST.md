# Mobile Production Release Pre-Flight Checklist

Mandatory verification items prior to building and publishing production app bundles.

---

## 1. Code Quality & Verification
- [ ] All automated unit tests passing (`flutter test`).
- [ ] Static analyzer reports 0 errors (`flutter analyze`).
- [ ] Version code and name bumped in `pubspec.yaml`.

---

## 2. Android Pre-Flight
- [ ] ProGuard / R8 rules verified against Firestore models.
- [ ] Keystore signature valid and secure.
- [ ] App Bundle generated via `flutter build appbundle --release`.

---

## 3. iOS Pre-Flight
- [ ] Provisioning profiles and certificates current.
- [ ] CocoaPods dependencies synchronized and locked.
- [ ] App Store privacy manifest declarations updated.
