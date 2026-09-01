# Environment Configuration & Deployment Guide

This guide outlines setup instructions for Development, Staging, and Production deployment targets.

---

## 1. Flavor Overview
- **Development (`dev`)**: Points to Firebase Local Emulator Suite.
- **Staging (`stg`)**: Dedicated cloud staging project for QA and automated integration tests.
- **Production (`prod`)**: Multi-region hardened production cluster.

---

## 2. Running Locally with Emulators
```bash
# Start Firebase Emulator Suite
firebase emulators:start --only firestore,auth,storage

# Run Flutter App with Dev Flavor
flutter run --dart-define=ENVIRONMENT=dev
```
