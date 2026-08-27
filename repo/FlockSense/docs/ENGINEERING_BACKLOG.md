# FlockSense Engineering Backlog

This backlog documents legitimate, verified improvements, refactorings, bug fixes, validation enhancements, tests, and architectural tasks across the FlockSense Flutter + Firebase codebase.

---

## Task Priority Definitions
- **P0**: Correctness, security, broken calculations, crash prevention, data integrity.
- **P1**: Functional completeness, broken workflows, derived real-time metrics.
- **P2**: Unit, widget, and provider test coverage.
- **P3**: Maintainability, modularization of oversized components.
- **P4**: UX polish, validation feedback, loading & empty states, responsive layouts, a11y.
- **P5**: System documentation, schema specs, formulas, and architecture guides.

---

## Backlog Item List

| Task ID | Module | Title | Priority | Complexity | Test Req | Status |
|---|---|---|---|---|---|---|
| **FS-001** | Farms | Calculate aggregate total shed capacity in farm dashboard stats | P0 | Small | Required | Done |
| **FS-002** | Farms | Calculate current live bird population from active batches | P0 | Small | Required | Done |
| **FS-003** | Farms | Calculate active batch count across user farms | P0 | Small | Required | Done |
| **FS-004** | Farms | Add unit & provider tests for `farmDashboardStatsProvider` | P2 | Medium | Required | Done |
| **FS-005** | Reports | Route empty report action directly to `DailyRecordsDashboardScreen` | P1 | Small | Required | Done |
| **FS-006** | Daily Records | Remove obsolete `DailyRecordsPlaceholderScreen` widget | P3 | Small | Optional | Done |
| **FS-007** | Auth | Centralize auth method availability and clean unsupported Email OTP UI | P0 | Small | Required | Done |
| **FS-008** | Auth | Document secure Cloud Functions / backend email OTP architecture | P5 | Small | N/A | Done |
| **FS-009** | Home | Connect Home dashboard active farm & bird population to live streams | P1 | Medium | Required | Done |
| **FS-010** | Home | Derive today's mortality and feed telemetry on Home from daily records | P1 | Medium | Required | Done |
| **FS-011** | Daily Records | Reject negative mortality values in daily records form & domain | P0 | Small | Required | Done |
| **FS-012** | Daily Records | Prevent mortality input from exceeding current live bird population | P0 | Small | Required | Done |
| **FS-013** | Feed | Validate feed bag quantity, weight per bag, and prevent negative stock | P0 | Small | Required | Done |
| **FS-014** | Farms | Validate farm dimensions, area calculation, and physical capacity | P1 | Small | Required | Todo |
| **FS-015** | Farms | Extract `FarmIdentityHeader` from `FarmCommandCenterScreen` | P3 | Medium | Required | Todo |
| **FS-016** | Farms | Extract `FarmOperationalSummary` metrics card from Command Center | P3 | Small | Optional | Todo |
| **FS-017** | Farms | Extract `FarmActiveBatchesSection` from Command Center | P3 | Medium | Optional | Todo |
| **FS-018** | Farms | Extract `FarmSpecsCard` from `FarmCommandCenterScreen` | P3 | Small | Optional | Todo |
| **FS-019** | Farms | Extract `FarmStatusControlCard` from `FarmCommandCenterScreen` | P3 | Small | Optional | Todo |
| **FS-020** | Farms | Validate phone numbers and district/state in `FarmSetupScreen` | P1 | Small | Required | Todo |
| **FS-021** | Farms | Standardize farm status badges across list and command center | P4 | Small | Optional | Todo |
| **FS-022** | Farms | Improve empty and error states in `FarmListScreen` | P4 | Small | Optional | Todo |
| **FS-023** | Farms | Add farm search and status filter in `FarmListScreen` | P1 | Medium | Required | Todo |
| **FS-024** | Farms | Unit test `FarmModel` serialization and dimension parsing | P2 | Small | Required | Todo |
| **FS-025** | Batches | Validate batch placement bird count (must be positive integer) | P0 | Small | Required | Todo |
| **FS-026** | Batches | Warn when batch bird count exceeds farm or shed capacity | P1 | Medium | Required | Todo |
| **FS-027** | Batches | Calculate remaining live birds (`totalBirds - mortality - culls + adj`) | P0 | Small | Required | Todo |
| **FS-028** | Batches | Support batch status filtering (`active`, `completed`, `all`) | P1 | Small | Required | Todo |
| **FS-029** | Batches | Prevent placement dates in the far future | P0 | Small | Required | Todo |
| **FS-030** | Batches | Unit test `BatchModel` serialization and copyWith methods | P2 | Small | Required | Todo |
| **FS-031** | Batches | Unit test batch population arithmetic and shed allocations | P2 | Small | Required | Todo |
| **FS-032** | Daily Records | Validate water consumption values (non-negative, realistic bounds) | P0 | Small | Required | Todo |
| **FS-033** | Daily Records | Validate daily record temperature and humidity numeric ranges | P1 | Small | Required | Todo |
| **FS-034** | Daily Records | Validate average bird weight input in grams (reasonable poultry range) | P1 | Small | Required | Todo |
| **FS-035** | Daily Records | Prevent duplicate daily records for identical batch and date | P0 | Medium | Required | Todo |
| **FS-036** | Daily Records | Extract repeated telemetry input card widgets in `add_record_wizard` | P3 | Medium | Optional | Todo |
| **FS-037** | Daily Records | Unit test daily record closing bird calculation edge cases | P2 | Small | Required | Todo |
| **FS-038** | Performance | Standardize Feed Conversion Ratio (FCR) formula calculation | P0 | Medium | Required | Todo |
| **FS-039** | Performance | Correct Mortality % formula with proper batch opening denominator | P0 | Small | Required | Todo |
| **FS-040** | Performance | Standardize Average Daily Gain (ADG) calculation across growth charts | P0 | Medium | Required | Todo |
| **FS-041** | Performance | Handle zero-data and single-point time series gracefully in charts | P4 | Small | Optional | Todo |
| **FS-042** | Performance | Prevent invalid zero-range Y-axis exceptions in `fl_chart` | P0 | Small | Required | Todo |
| **FS-043** | Performance | Unit test performance formulas (FCR, ADG, Mortality %, EPEF) | P2 | Medium | Required | Todo |
| **FS-044** | Home | Extract `HomeDashboardHeader` widget from `HomeScreen` | P3 | Small | Optional | Todo |
| **FS-045** | Home | Extract `HomeKpiSection` widget from `HomeScreen` | P3 | Small | Optional | Todo |
| **FS-046** | Home | Extract `HomeQuickActions` widget from `HomeScreen` | P3 | Small | Optional | Todo |
| **FS-047** | Home | Extract `HomeAlertSection` widget from `HomeScreen` | P3 | Small | Optional | Todo |
| **FS-048** | Home | Replace static demo mortality array with derived weekly records | P1 | Medium | Required | Todo |
| **FS-049** | Home | Replace static demo feed intake array with derived daily records | P1 | Medium | Required | Todo |
| **FS-050** | Feed | Calculate totalKg consistently from bags * weightPerBag | P0 | Small | Required | Todo |
| **FS-051** | Feed | Prevent negative inventory stock on consumption entries | P0 | Small | Required | Todo |
| **FS-052** | Feed | Add low-stock visual warning badge to feed inventory list | P4 | Small | Optional | Todo |
| **FS-053** | Feed | Validate feed purchase transaction costs (unit price, total amount) | P1 | Small | Required | Todo |
| **FS-054** | Feed | Unit test `FeedTransactionModel` calculations and stock updates | P2 | Small | Required | Todo |
| **FS-055** | Inventory | Reject negative item stock quantities during adjustments | P0 | Small | Required | Todo |
| **FS-056** | Inventory | Validate stock movement transactions (IN / OUT / AUDIT) | P0 | Small | Required | Todo |
| **FS-057** | Inventory | Add low stock threshold indicators in inventory dashboard | P4 | Small | Optional | Todo |
| **FS-058** | Inventory | Improve empty state for item movement history | P4 | Small | Optional | Todo |
| **FS-059** | Inventory | Unit test inventory stock adjustments and movement history | P2 | Small | Required | Todo |
| **FS-060** | Vaccine | Clarify distinction between `vaccine` (catalogue/stock) and `vaccination` (log) | P5 | Small | N/A | Todo |
| **FS-061** | Vaccine | Validate vaccination application dates (cannot precede placement date) | P0 | Small | Required | Todo |
| **FS-062** | Vaccine | Display upcoming scheduled vaccinations badge on batch screen | P1 | Medium | Required | Todo |
| **FS-063** | Medicine | Validate medicine dosage numeric input and unit selection | P1 | Small | Required | Todo |
| **FS-064** | Medicine | Improve treatment history display with completion status | P4 | Small | Optional | Todo |
| **FS-065** | Medicine | Unit test medicine and vaccine record models | P2 | Small | Required | Todo |
| **FS-066** | Finance | Ensure net profit calculation is `totalIncome - totalExpense` consistently | P0 | Small | Required | Todo |
| **FS-067** | Finance | Reject negative or zero transaction amounts in finance entry form | P0 | Small | Required | Todo |
| **FS-068** | Finance | Validate finance transaction dates (reject invalid formats / future dates) | P1 | Small | Required | Todo |
| **FS-069** | Finance | Handle zero-data state in financial breakdown charts | P4 | Small | Optional | Todo |
| **FS-070** | Finance | Unit test finance calculations (income, expense, cashflow, net profit) | P2 | Small | Required | Todo |
| **FS-071** | Reports | Validate report date range filters (start date must be <= end date) | P0 | Small | Required | Todo |
| **FS-072** | Reports | Handle empty dataset gracefully during PDF, Excel, CSV generation | P0 | Medium | Required | Todo |
| **FS-073** | Reports | Centralize export file naming with timestamp and farm identifier | P1 | Small | Required | Todo |
| **FS-074** | Reports | Add metadata summary to report history entries | P4 | Small | Optional | Todo |
| **FS-075** | Reports | Unit test report export data structure generation | P2 | Small | Required | Todo |
| **FS-076** | Notifications | Prevent duplicate smart alert creation for identical events on same day | P0 | Medium | Required | Todo |
| **FS-077** | Notifications | Add real-time unread notification count badge on navigation bar | P1 | Small | Required | Todo |
| **FS-078** | Notifications | Handle missing or invalid FCM token gracefully without throwing | P0 | Small | Required | Todo |
| **FS-079** | Notifications | Improve notification center empty state and filter by alert type | P4 | Small | Optional | Todo |
| **FS-080** | Notifications | Unit test smart alert evaluator trigger conditions | P2 | Medium | Required | Todo |
| **FS-081** | AI | Reject empty or whitespace-only prompts in Gemini AI chat | P0 | Small | Required | Todo |
| **FS-082** | AI | Handle missing Gemini API configuration gracefully with UI fallback | P0 | Small | Required | Todo |
| **FS-083** | AI | Improve network failure & quota exhaustion error messages | P1 | Small | Required | Todo |
| **FS-084** | AI | Sanitize farm and batch context formatting before sending to LLM | P1 | Medium | Required | Todo |
| **FS-085** | AI | Prevent duplicate conversation message appends during active streams | P0 | Small | Required | Todo |
| **FS-086** | Calendar | Validate calendar event start and end time ranges | P1 | Small | Required | Todo |
| **FS-087** | Calendar | Highlight upcoming vaccination & medication schedules on calendar | P1 | Medium | Required | Todo |
| **FS-088** | Calendar | Add today's event summary card at top of calendar screen | P4 | Small | Optional | Todo |
| **FS-089** | Auth | Validate email format with standard RFC regex in auth forms | P0 | Small | Required | Todo |
| **FS-090** | Auth | Validate password minimum strength (6+ chars, digit check) | P1 | Small | Required | Todo |
| **FS-091** | Auth | Map Firebase Auth exceptions to user-friendly localized messages | P0 | Small | Required | Todo |
| **FS-092** | Auth | Prevent double-submission on login and registration buttons | P1 | Small | Required | Todo |
| **FS-093** | Core | Apply `InputSanitizer` to all user-facing text and numeric fields | P1 | Medium | Required | Todo |
| **FS-094** | Core | Normalize Firestore and network exceptions across all data services | P0 | Medium | Required | Todo |
| **FS-095** | Core | Standardize use of `AppEmptyState` across feature screens | P4 | Small | Optional | Todo |
| **FS-096** | Core | Standardize use of `AppLoadingIndicator` across feature screens | P4 | Small | Optional | Todo |
| **FS-097** | Core | Centralize design tokens in `AppColors` and `AppDesign` | P3 | Medium | Optional | Todo |
| **FS-098** | Core | Fix deprecated `withOpacity` usages to `withValues()` | P3 | Medium | Optional | Todo |
| **FS-099** | Accessibility | Add semantic labels to icon-only action buttons across app | P4 | Medium | Optional | Todo |
| **FS-100** | Accessibility | Ensure touch targets are at least 48x48 dp on mobile forms | P4 | Medium | Optional | Todo |
| **FS-101** | Accessibility | Add accessible descriptions to performance charts | P4 | Small | Optional | Todo |
| **FS-102** | Responsiveness | Fix potential RenderFlex overflow on compact mobile screens | P1 | Medium | Required | Todo |
| **FS-103** | Responsiveness | Adapt report and analytics grids for tablet and desktop widths | P4 | Medium | Optional | Todo |
| **FS-104** | Demo Data | Create isolated development seed data generator for testing | P5 | Large | Required | Todo |
| **FS-105** | Docs | Write comprehensive `README.md` with features and architecture | P5 | Medium | N/A | Todo |
| **FS-106** | Docs | Create `docs/ARCHITECTURE.md` detailing clean architecture | P5 | Medium | N/A | Todo |
| **FS-107** | Docs | Create `docs/FIREBASE_SCHEMA.md` with Firestore paths & rules | P5 | Medium | N/A | Todo |
| **FS-108** | Docs | Create `docs/ANALYTICS_FORMULAS.md` documenting FCR, ADG, EPEF | P5 | Small | N/A | Todo |
| **FS-109** | Docs | Create `docs/DEVELOPMENT_SETUP.md` with local run guidelines | P5 | Small | N/A | Todo |
| **FS-110** | Docs | Create `docs/TESTING.md` documenting unit & widget test runner | P5 | Small | N/A | Todo |
| **FS-111** | Docs | Create `docs/CONTRIBUTING.md` with coding standards & branch guide | P5 | Small | N/A | Todo |
| **FS-112** | Docs | Create `docs/FEATURE_MAP.md` mapping all 20+ poultry features | P5 | Medium | N/A | Todo |
| **FS-113** | Docs | Create `docs/SECURITY.md` covering credential hygiene and rules | P5 | Small | N/A | Todo |
| **FS-114** | Docs | Create `docs/DEMO_DATA.md` documenting sample farm & batch data | P5 | Small | N/A | Todo |
| **FS-115** | Sheds | Add shed creation form validation (length, width, capacity) | P1 | Small | Required | Todo |
| **FS-116** | Sheds | Add unit tests for `ShedModel` serialization and capacity totals | P2 | Small | Required | Todo |
| **FS-117** | Health | Validate flock symptom observation records in health module | P1 | Small | Required | Todo |
| **FS-118** | Health | Add mortality spike alert detection in health evaluation | P0 | Medium | Required | Todo |
| **FS-119** | Weight | Validate average weight sampling records with bird count sample | P1 | Small | Required | Todo |
| **FS-120** | Weight | Fix async context usage in weight records screen | P0 | Small | Required | Todo |
| **FS-121** | Sales | Validate bird sale transactions (live bird count <= current population) | P0 | Medium | Required | Todo |
| **FS-122** | Sales | Calculate total bird weight and sale revenue from price per kg | P0 | Small | Required | Todo |
| **FS-123** | Profile | Validate user profile updates (name, phone, role) | P1 | Small | Required | Todo |
| **FS-124** | Settings | Replace deprecated Switch `activeColor` with `activeThumbColor` | P3 | Small | Optional | Todo |
| **FS-125** | CI/CD | Set up comprehensive GitHub Action workflow for analyze & test | P5 | Small | Required | Todo |

---
