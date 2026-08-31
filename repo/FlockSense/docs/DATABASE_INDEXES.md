# Cloud Firestore & PostgreSQL Indexing Specifications

This document outlines the composite index configurations and Row-Level Security (RLS) constraints for FlockSense.

---

## 1. Compound Query Indexes

### `daily_records` Collection
```json
{
  "collectionGroup": "daily_records",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "batchId", "order": "ASCENDING" },
    { "fieldPath": "date", "order": "DESCENDING" }
  ]
}
```

### `sales_records` Collection
```json
{
  "collectionGroup": "sales_records",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "farmId", "order": "ASCENDING" },
    { "fieldPath": "date", "order": "DESCENDING" }
  ]
}
```

---

## 2. Security & Partitioning
- **Farm Isolation**: Queries strictly enforce `where('farmId', isEqualTo: activeFarmId)` to prevent cross-tenant data leakage.
- **Owner Scope**: All mutations authenticate against `request.auth.uid == resource.data.ownerId`.
