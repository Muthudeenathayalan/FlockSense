# FlockSense System Architecture & Design Guidelines

This document details the architectural blueprints, design patterns, and code structure of the FlockSense application.

---

## 1. Architectural Philosophy

FlockSense adopts **Clean Architecture** combined with **Feature-First modularization** and Riverpod state management.

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  (Screens, Widgets, Dialogs, State Providers, Animation)    │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│                       Domain Layer                          │
│     (Entity Models, Enums, Calculators, Validators)        │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│                        Data Layer                           │
│   (Firestore Services, DTO Serializers, Repositories)       │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Layer Responsibilities

### Presentation Layer (`presentation/`)
- **Screens**: Page-level widgets responsible for assembling sub-widgets.
- **Widgets**: Reusable, atomic visual components.
- **Providers**: Riverpod `StateNotifierProvider`, `StreamProvider`, or `FutureProvider` managing UI state and streaming Firebase changes.

### Domain Layer (`domain/`)
- **Models**: Immutable data structures (e.g. `FarmModel`, `BatchModel`, `DailyRecordModel`).
- **Calculators / Engines**: Pure functions with zero Flutter UI dependencies (e.g. `PerformanceCalculator`, `FinanceAnalyticsEngine`).
- **Validators**: Static helper methods ensuring data integrity before persistence.

### Data Layer (`data/`)
- **Services**: Cloud Firestore data access objects executing scoped queries.
- **Generators**: PDF, Excel, and CSV file creators.

---

## 3. Directory Layout

```
lib/
├── core/
│   ├── constants/
│   ├── theme/
│   │   ├── app_colors.dart
│   │   └── app_design.dart
│   ├── utils/
│   └── widgets/
│       ├── app_dialog.dart
│       └── custom_app_bar.dart
└── features/
    ├── auth/
    ├── farms/
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    │       ├── providers/
    │       ├── screens/
    │       └── widgets/
    ├── batches/
    ├── daily_records/
    ├── performance/
    ├── feed/
    ├── inventory/
    ├── vaccine/
    ├── medicine/
    ├── finance/
    ├── reports/
    └── home/
```

---

## 4. State Management Conventions

- Prefer `StreamProvider` for real-time Firestore collections (e.g. `farmsStreamProvider`, `activeBatchesProvider`).
- Keep business logic inside pure domain calculators for testability without Flutter UI bindings.
- Use `AsyncValue.when` for consistent Loading, Error, and Data UI state handling.
