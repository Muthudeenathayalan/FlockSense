# FlockSense — Precision Poultry Farm Management System

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20Layered-16A34A)](#architecture)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

FlockSense is an enterprise-grade mobile application and precision poultry telemetry platform engineered for modern commercial broiler and layer operations. Built with Flutter, Firebase, and Riverpod, FlockSense empowers farm owners, supervisors, and integrators with real-time flock tracking, automated FCR calculations, growth analytics, feed & medication inventory control, and financial reporting.

---

## 🚀 Key Features

### 🏢 Farm & Shed Multi-Tier Command Center
- Hierarchical multi-farm and shed management.
- Live bird population rollups and real-time operational capacity tracking.
- Physical capacity estimation based on square footage and commercial density standards.

### 🐣 Batch Lifecycle Management
- Complete flock cycle tracking from chick placement to harvest.
- Automatic live population recalculation (`placed - mortality - culls + adjustments`).
- Sub-shed allocation and mortality tracking with anomaly alerts.

### 📊 Precision Analytics & Growth Engine
- Standardized Feed Conversion Ratio (FCR) calculation against commercial broiler standards (e.g. SKM, Cobb 500).
- Average Daily Gain (ADG) and European Production Efficiency Factor (EPEF / PEF) monitoring.
- Interactive multi-metric time-series visualizations using `fl_chart`.

### 🌾 Feed & Inventory Control
- Bag count, weight per bag, and consumption transaction tracking.
- Automated low-stock thresholds, restock reminders, and shelf-life / expiry alerts.
- Stock movement audit trails (Addition, Consumption, Damage, Transfer).

### 💉 Vaccines & Medication Logs
- Batch-age-based vaccination schedules with dosage and route validation.
- Treatment logs with withdrawal period tracking and financial expense attribution.

### 💰 Financial Economics & Cash Flow
- Real-time gross income, operational expenses, net profit, and ROI calculations.
- Cost-per-bird and revenue-per-bird unit economics breakdown.
- Budget allocation vs actual expenditure warnings.

### 📑 Multi-Format Reporting & Export
- Deterministic PDF, Excel (XLSX), and CSV export generators.
- Filterable date presets with start/end date validation.
- Local report history caching and share sheet integration.

---

## 🏗️ Architecture

FlockSense strictly enforces **Clean Layered Architecture** principles:

```
lib/
├── core/                  # Theme, design tokens, shared dialogs, utils
├── features/
│   ├── auth/              # Authentication & session state
│   ├── farms/             # Farm management & command center
│   ├── batches/           # Batch lifecycle & placement
│   ├── daily_records/     # Daily flock telemetry (feed, water, mortality, weight)
│   ├── performance/       # Growth curves, FCR, ADG, EPEF analytics
│   ├── feed/              # Feed stock and consumption tracking
│   ├── inventory/         # General farm supply inventory
│   ├── vaccine/           # Vaccination schedule & log
│   ├── medicine/          # Treatment & medication records
│   ├── finance/           # Financial transactions, budgets & cash flow
│   ├── reports/           # PDF, Excel, CSV export pipelines
│   └── home/              # Executive dashboard & real-time telemetry feed
└── config/                # Firebase options, router configuration
```

---

## 🛠️ Getting Started

### Prerequisites
- **Flutter SDK**: `>= 3.3.0`
- **Dart SDK**: `>= 3.0.0`
- **Firebase Project**: Configured with Authentication & Firestore

### Installation
```bash
# Clone the repository
git clone https://github.com/Muthudeenathayalan/FlockSense.git
cd FlockSense

# Install Flutter dependencies
flutter pub get

# Run test suite
flutter test

# Launch debug app
flutter run
```

---

## 📚 Documentation Directory

- [Architecture & Layering](docs/ARCHITECTURE.md)
- [Firebase & Firestore Schema](docs/FIREBASE_SCHEMA.md)
- [Poultry Analytics & Performance Formulas](docs/ANALYTICS_FORMULAS.md)
- [Security Architecture & Best Practices](docs/SECURITY.md)
- [Local Development Setup](docs/DEVELOPMENT_SETUP.md)
- [Testing Guidelines](docs/TESTING.md)
- [Contributing Guidelines](docs/CONTRIBUTING.md)
- [Changelog](docs/CHANGELOG.md)

---

## 🧪 Testing

FlockSense maintains a comprehensive unit and widget testing suite:

```bash
# Run all unit and widget tests
flutter test

# Run tests with coverage
flutter test --coverage
```

---

## 📄 License
This project is open-source under the MIT License.
