# Offline-First Data Synchronization & Queue Architecture

This document details the offline-first replication and synchronization protocol implemented across FlockSense for mobile farm deployments with intermittent rural connectivity.

---

## 1. Sync Philosophy & Guarantees
- **Local Writes First**: Every mutation (daily entry, feeding log, mortality record) writes immediately to local storage.
- **Optimistic UI**: The presentation layer reflects mutations with `SyncStatus.pending` visual badges.
- **Eventual Consistency**: Once network connectivity is re-established, the sync dispatcher drains the FIFO mutation queue to Cloud Firestore.

---

## 2. Conflict Resolution
FlockSense implements **Last-Write-Wins with Authoritative Server Timestamps (LWW-ST)**:
1. Every write payload includes a local client timestamp and a monotonic sequence counter.
2. In the event of competing concurrent writes from multiple shed supervisors, the server evaluates `updatedAt`.
3. If concurrent updates edit different fields of a batch, fine-grained field merging applies without overwriting independent telemetry.
