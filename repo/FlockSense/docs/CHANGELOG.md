# FlockSense Changelog

All notable changes to the FlockSense platform will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.0] - 2026-08-27

### Added
- **Farm Multi-Tier Command Center**: Modular sub-widgets (`FarmIdentityHeader`, `FarmOperationalSummary`, `FarmActiveBatchesSection`, `FarmSpecsCard`, `FarmStatusControlCard`).
- **Telemetry & Validation**: Mortality upper bound check against live bird population; non-negative feed, water, and temperature bounds.
- **Analytics Formula Precision**: Standardized cumulative FCR with live biomass denominator; added Average Daily Gain (ADG) and European Production Efficiency Factor (EPEF).
- **Inventory & Finance**: Added stock balance transitions, low-stock/expiry detection, invoice pending balance calculation, and financial unit economics.
- **Automated Test Suite**: Added 34 unit tests across all core feature domains (Farms, Batches, Daily Records, Performance, Feed, Inventory, Vaccines, Finance, Reports).
- **Comprehensive Documentation**: Added `ARCHITECTURE.md`, `FIREBASE_SCHEMA.md`, `ANALYTICS_FORMULAS.md`, `DEVELOPMENT_SETUP.md`, `TESTING.md`, `CONTRIBUTING.md`, and `SECURITY.md`.

### Fixed
- Corrected cumulative FCR calculation from single-bird divisor to total live flock biomass.
- Prevented negative closing bird counts in `DailyRecordModel.fromJson`.
- Fixed Reports Dashboard empty state action to route directly to `DailyRecordsDashboardScreen`.
- Removed obsolete placeholder screens.

---

## [1.0.0] - 2026-08-01
- Initial release of FlockSense with basic farm, batch, and daily records tracking.
