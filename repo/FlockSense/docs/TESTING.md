# Testing Architecture & Guidelines

FlockSense adopts an automated testing strategy with unit tests, domain calculation tests, and widget smoke tests.

---

## 1. Test Suite Structure

```
test/
├── calculations_test.dart                         # Baseline daily calculations
├── models/                                        # Legacy serialization tests
├── features/
│   ├── farms/
│   │   ├── domain/farm_model_test.dart            # Farm dimension & capacity validation
│   │   └── farm_providers_test.dart               # Aggregate capacity & bird population
│   ├── batches/
│   │   └── batch_model_test.dart                  # Batch placement & live count calculations
│   ├── daily_records/
│   │   ├── daily_records_validation_test.dart     # Mortality bounds & feed validation
│   │   └── daily_record_ux_test.dart              # Offline sync & yesterday copy logic
│   ├── performance/
│   │   └── performance_calculator_test.dart       # FCR, ADG, Mortality %, EPEF formulas
│   ├── feed/
│   │   └── feed_transaction_model_test.dart       # Bag and weight per bag calculations
│   ├── inventory/
│   │   └── inventory_model_test.dart              # Stock balance, low stock & expiry checks
│   ├── vaccine_medicine/
│   │   └── vaccine_medicine_models_test.dart      # Dosage & schedule validation
│   ├── finance/
│   │   └── finance_analytics_test.dart            # Income, expense, profit & cash flow
│   └── reports/
│       └── report_types_test.dart                 # Filter date validation & export naming
└── widget_test.dart                               # Root app widget test
```

---

## 2. Running Tests

### Run Full Test Suite
```bash
flutter test
```

### Run Specific Feature Tests
```bash
flutter test test/features/performance/performance_calculator_test.dart
flutter test test/features/finance/finance_analytics_test.dart
```

### Test Output Standards
All tests must pass with 0 errors before committing changes.
