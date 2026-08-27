# FlockSense Security Architecture & Guidelines

This document outlines the security architecture, authentication standards, credential protection, and Firestore security rules implemented in FlockSense.

---

## 1. Authentication Security Model

FlockSense supports three primary authentication pathways:
1. **Google OAuth 2.0 Sign-In** (`signInWithGoogle`) via Firebase Authentication with cryptographically verified ID tokens.
2. **Phone Number OTP** (`sendPhoneOtp`, `verifyPhoneOtp`) via Firebase Phone Authentication with Android auto-retrieval / SMS fallback.
3. **Email & Password Authentication** (`login`, `createAccount`) with SHA-256 / scrypt credential hashing handled directly by Firebase Auth.

### Email OTP Security Policy
> [!IMPORTANT]
> **Client-Side OTP Generation is Strictly Prohibited**
> 
> Generating random OTP codes on the client and storing them in a readable Firestore collection (e.g. `otp_requests`) is an insecure anti-pattern. Any compromised client or unauthenticated user could intercept or brute-force codes.
>
> Email OTP must always be implemented via **Firebase Cloud Functions (v2)** or a dedicated trusted backend:
> 1. Client calls `httpsCallable('sendEmailOtp')` with user's email.
> 2. Cloud Function securely generates a cryptographically secure 6-digit code, saves a hashed digest (`crypto.scrypt`) with expiry (5 minutes) and attempt counter (max 3 attempts) in a protected collection accessible only by Admin SDK.
> 3. Cloud Function sends email via transactional provider (SendGrid, Postmark, Firebase Mail Extension).
> 4. Verification occurs exclusively in `httpsCallable('verifyEmailOtp')`.

---

## 2. Secrets & Credential Hygiene

- **Zero Secrets in Version Control**: API keys, service account JSON files, private keys, `.env` secrets, and passwords must never be committed.
- **Firebase Configuration**: Production client configs (`google-services.json`, `GoogleService-Info.plist`) are environment-scoped and restricted to specific SHA-1/SHA-256 fingerprint hashes and iOS bundle identifiers.
- **AI & Gemini API Keys**: Passed securely at runtime via environment variables or encrypted secure storage (`flutter_secure_storage` / Firebase Remote Config), never hardcoded.

---

## 3. Firestore Security Rules Structure

All user data is strictly scoped under user ownership:
- Path: `users/{userId}/*`
- Rules require `request.auth.uid == userId` for all read and write operations.
- Collection group queries (such as `collectionGroup('dailyRecords')` or `collectionGroup('batches')`) require `where('ownerId', '==', request.auth.uid)` with composite indexes.

---

## 4. Input Sanitization & Data Integrity

- Text fields are sanitized against injection attacks via `InputSanitizer`.
- Numeric inputs (mortality, feed weights, water volumes, temperature) are bounded and validated prior to database persistence.
- Closing bird population is computed deterministically to prevent negative flock counts.
