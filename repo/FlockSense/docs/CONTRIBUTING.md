# Contributing to FlockSense

Thank you for contributing to FlockSense! To maintain high code quality and consistency, please follow these guidelines.

---

## 1. Commit Message Convention

FlockSense strictly follows **Conventional Commits**:

| Type | Purpose | Example |
|------|---------|---------|
| `feat` | New user-facing feature or domain capability | `feat(farms): add farm dimension validation and capacity estimation` |
| `fix` | Bug fix or calculation correction | `fix(analytics): correct cumulative FCR biomass denominator` |
| `refactor` | Code restructuring without feature changes | `refactor(farms): modularize FarmCommandCenterScreen into sub-widgets` |
| `test` | Adding or updating unit/widget tests | `test(finance): add tests for profit margin and pending invoice amounts` |
| `docs` | Documentation additions or updates | `docs: add comprehensive system architecture and formula specifications` |

---

## 2. Code Quality Checklist

Before submitting a Pull Request or pushing commits:
1. Run `flutter analyze` — verify **0 issues found**.
2. Run `dart format .` — ensure consistent code formatting.
3. Run `flutter test` — ensure **all automated tests pass**.
4. Update `docs/DEVELOPMENT_LOG.md` with task identifiers and test results.
