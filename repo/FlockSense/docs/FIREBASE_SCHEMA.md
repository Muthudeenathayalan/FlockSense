# Cloud Firestore Data Architecture & Security Rules

This document outlines the Firestore document paths, indexing policies, and security scoping rules for FlockSense.

---

## 1. Document Path Hierarchy

All farm records are strictly scoped under the authenticated user's UID:

### User Root
- `users/{uid}`: User profile and global settings

### Farms Collection
- `users/{uid}/farms/{farmId}`
  - Fields: `id`, `farmName`, `farmType`, `lengthFt`, `widthFt`, `totalSqFt`, `capacity`, `status`, `createdAt`, `updatedAt`

### Batches Subcollection
- `users/{uid}/farms/{farmId}/batches/{batchId}`
  - Fields: `id`, `farmId`, `batchName`, `placementDate`, `totalBirds`, `currentBirds`, `breedOrFlockType`, `status`, `createdAt`, `updatedAt`

### Daily Records Subcollection
- `users/{uid}/farms/{farmId}/batches/{batchId}/dailyRecords/{recordId}`
  - Fields: `id`, `batchAgeDay`, `recordDate`, `openingBirds`, `mortalityCount`, `cullCount`, `closingBirds`, `feedConsumedKg`, `waterConsumedLiters`, `avgWeightGrams`

### Global Collections (User-Scoped)
- `users/{uid}/inventory/{itemId}`: Farm consumables and equipment stock
- `users/{uid}/finance_transactions/{txId}`: Income and expense entries
- `users/{uid}/finance_budgets/{budgetId}`: Monthly budget allocations

---

## 2. Collection Group Queries

For cross-farm rollups (e.g. Total live bird count across all farms, or all pending vaccines), collection group queries must be scoped to the authenticated owner:

```dart
FirebaseFirestore.instance
    .collectionGroup('batches')
    .where('ownerId', isEqualTo: currentUserId)
    .where('status', isEqualTo: 'active');
```

---

## 3. Firestore Security Rules Blueprint

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```
