# Local Development & Environment Setup

This guide walks through configuring your local development workstation to run, test, and contribute to FlockSense.

---

## 1. Prerequisites

Ensure you have installed:
- **Flutter SDK**: 3.3.0 or higher ([Installation Guide](https://docs.flutter.dev/get-started/install))
- **Dart SDK**: 3.0.0 or higher (included with Flutter)
- **Android Studio / VS Code / Antigravity IDE** with Flutter & Dart extensions
- **Git**

---

## 2. Quickstart Setup

### Step 1: Clone Repository
```bash
git clone https://github.com/Muthudeenathayalan/FlockSense.git
cd FlockSense
```

### Step 2: Install Packages
```bash
flutter pub get
```

### Step 3: Run Static Analysis & Tests
```bash
flutter analyze
flutter test
```

### Step 4: Launching Debug App
```bash
# Launch on an attached device or emulator
flutter run
```

---

## 3. Useful Commands

| Command | Purpose |
|---------|---------|
| `flutter analyze` | Run static code analysis for warnings and lint issues |
| `dart format .` | Format all Dart code files |
| `flutter test` | Run the complete automated test suite |
| `flutter test --coverage` | Run tests and generate LCOV coverage data |
