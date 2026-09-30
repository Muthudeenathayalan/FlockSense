# Testing Architecture & Guidelines

FlockSense adopts an automated testing strategy with unit tests, domain calculation tests, and widget smoke tests.

---

## 1. Test Suite Structure

```
test/
├── core/
│   ├── calculations_test.dart                         # Baseline daily calculations
│   ├── services/sync_service_test.dart                # Offline persistence queue & sync
│   └── utils/
│       ├── ammonia_threshold_helper_test.dart         # Ammonia ppm thresholds & ventilation
│       ├── broiler_growth_standards_test.dart         # Standard Cobb 500 / Ross 308 weight tables
│       ├── csv_sanitizer_test.dart                    # CSV export injection guard
│       ├── density_calculator_test.dart               # Shed stocking density validation
│       ├── european_broiler_index_test.dart           # EPEF & European Broiler Index
│       ├── feed_allocation_table_test.dart            # Feed stage transitions
│       ├── feed_cost_calculator_test.dart             # Unit economics & bird feed cost
│       ├── flock_uniformity_calculator_test.dart      # Flock uniformity CV% calculations
│       ├── input_sanitizer_test.dart                  # Form input sanitization
│       ├── lighting_program_helper_test.dart          # Photoperiod & lux targets
│       ├── mortality_rate_calculator_test.dart        # Mortality & culling rates
│       ├── temperature_humidity_index_test.dart       # THI index & heat stress
│       ├── vaccination_schedule_helper_test.dart      # Bird age vaccination windows
│       └── water_intake_ratio_test.dart               # Water-to-feed consumption ratio
├── features/
│   ├── ai/
│   │   ├── ai_context_builder_test.dart               # Dynamic prompt context synthesis
│   │   └── gemini_service_test.dart                   # Gemini API client integration
│   ├── auth/                                          # Auth validators & User model
│   ├── batches/                                       # Batch lifecycle, placement & shed workflows
│   ├── calendar/                                      # Event scheduling & reminder models
│   ├── daily_records/                                 # Telemetry intake, bounds & yesterday prefill
│   ├── farms/                                         # Multi-tier farm topology & capacity rollups
│   ├── feed/                                          # Feed bag conversions & allocations
│   ├── finance/                                       # Revenue, expense & cash flow analytics
│   ├── flock_plan/                                    # Dynamic cycle days & authentic plan engine
│   ├── home/                                          # Dashboard alignment, tabs & farm switching
│   ├── inventory/                                     # Stock balance, reorder & expiry alerts
│   ├── notifications/                                 # Telemetry anomaly & deduplication logic
│   ├── onboarding/                                    # Guided first-run tour & replay tests
│   ├── performance/                                   # FCR, ADG, EPEF & growth curve benchmarking
│   ├── reports/                                       # Authentic audit, PDF generation & date filters
│   ├── sales/                                         # Sales & batch coupling bird decrement tests
│   ├── sheds/                                         # Shed dimensions, capacity & copyWith
│   ├── vaccine_medicine/                              # Dosage, schedule & cost attribution
│   └── weight/                                        # Weight sampling round-trip serialization
└── widget_test.dart                                   # Root application widget tests
```

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
