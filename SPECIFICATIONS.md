# TrustNet iOS App - Specifications

**Version 1.0**  
**February 9, 2026**

---

## 1. Executive Summary

The **TrustNet iOS App** is a mobile companion for TrustNet Node operators. It provides real-time node status monitoring, identity/reputation management, and token operations on-the-go. The app integrates with the PassportValidator cryptographic library to enable secure identity verification and document validation.

**Purpose**: Enable node operators to manage their TrustNet identity, check node status, verify reputation score, view TRUST token balance, and perform credential management—all from iPhone.

---

## 2. Architecture Overview

### 2.1 Core Components

```text
┌─────────────────────────────────────────────────────────────┐
│                    iOS App (SwiftUI)                        │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  UI Layer (SwiftUI)                                  │  │
│  │  ├─ Dashboard Screen (Node Status)                  │  │
│  │  ├─ Identity Management Screen                       │  │
│  │  ├─ Transactions Screen                              │  │
│  │  └─ Settings Screen                                  │  │
│  └──────────────────────────────────────────────────────┘  │
│                          ↓                                  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Service Layer (Swift)                              │  │
│  │  ├─ NodeAPIService (REST client)                    │  │
│  │  ├─ IdentityManager (identity logic)                │  │
│  │  ├─ KeychainManager (secure storage)                │  │
│  │  └─ ValidationService (PassportValidator)           │  │
│  └──────────────────────────────────────────────────────┘  │
│                          ↓                                  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Crypto Layer (Swift + PassportValidator.swift)     │  │
│  │  ├─ P256 signature validation (ECDSA)               │  │
│  │  ├─ Document hash verification                      │  │
│  │  └─ Credential validation                           │  │
│  └──────────────────────────────────────────────────────┘  │
│                          ↓                                  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Security Layer                                      │  │
│  │  ├─ Keychain (private key storage)                  │  │
│  │  ├─ AES-256-GCM (sensitive data)                    │  │
│  │  ├─ TLS 1.3 (network communication)                 │  │
│  │  └─ Biometric unlock (Face ID / Touch ID)           │  │
│  └──────────────────────────────────────────────────────┘  │
│                          ↓                                  │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│         TrustNet Node (Alpine VM)                           │
│                                                              │
│  REST API                                                   │
│  ├─ GET /node/status → { connected, syncHeight, ... }      │
│  ├─ GET /identity/{address} → { identity details }         │
│  ├─ GET /reputation/{address} → { score, endorsements }    │
│  ├─ GET /balance/{address} → { trustAmount, usdValue }     │
│  ├─ POST /transactions → { txData }                        │
│  └─ POST /verify/credential → { valid: boolean }           │
│                                                              │
│  Blockchain (Cosmos SDK)                                   │
│  ├─ Identity module                                        │
│  ├─ Reputation module                                      │
│  ├─ Bank module (TRUST token)                             │
│  └─ IBC module (cross-chain)                              │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Technology Stack

**iOS Framework**: SwiftUI (iOS 14+)
**Networking**: URLSession + async/await
**Crypto**: CryptoKit (P256, AES-256-GCM, SHA-256)
**Custom Library**: PassportValidator (ECDSA P256 signature validation)
**Security**: Keychain, Biometric authentication
**Data Storage**: UserDefaults (encrypted preferences), Keychain (secrets)
**Dependencies**: None (SwiftUI + standard library only)

---

## 3. User Interface Design

### 3.1 Visual Language

**Color Scheme** (from Alpine VM reference):
- Primary Gradient: Purple (#7C5CFF) to Blue (#4C63FF)
- Success: Green (#22C55E)
- Danger: Red (#EF4444)
- Neutral: Gray (#64748B)
- Backgrounds: Light gray (#F1F5F9)

**Typography**:
- Titles: System font, .bold, size 32
- Subtitles: System font, .semibold, size 18
- Body: System font, .regular, size 16
- Captions: System font, .regular, size 12

**Layout**:
- Card-based design (rounded corners 8px, shadow)
- Spacing: 16pt (padding), 8pt (element spacing)
- Status indicators: Colored badges with SF Symbols

---

### 3.2 Screen Specifications

#### **Screen 1: Dashboard (Main Screen)**

**Purpose**: Show node operator quick overview of everything important

**Layout**:
```
┌─────────────────────────────────────┐
│  TrustNet                    ⚙️      │
│  Node Operator Dashboard            │
├─────────────────────────────────────┤
│  📊 NODE STATUS                     │
│  ┌───────────────────────────────┐  │
│  │ Network Status: 🟢 Connected  │  │
│  │ Sync Status: 🟢 Synchronized  │  │
│  │ Block Height: 12,547          │  │
│  │ Node Address: trustnet1abc...  │  │
│  └───────────────────────────────┘  │
├─────────────────────────────────────┤
│  🎖️  REPUTATION & IDENTITY          │
│  ┌───────────────────────────────┐  │
│  │ Your Reputation: 85/100       │  │
│  │ ████████████░░░ 85%           │  │
│  │ Status: VERIFIED              │  │
│  │ Endorsements: 47              │  │
│  └───────────────────────────────┘  │
├─────────────────────────────────────┤
│  💰 TRUST BALANCE                   │
│  ┌───────────────────────────────┐  │
│  │ 2,547.50 TRUST                │  │
│  │ ≈ $12,737.50 USD              │  │
│  └───────────────────────────────┘  │
├─────────────────────────────────────┤
│  [Register Identity] [Verify Docs] │
│  [View Transactions] [Manage Keys] │
└─────────────────────────────────────┘
```

**Data Sources**:
- Node Status: `GET /node/status`
- Reputation: `GET /reputation/{address}`
- Balance: `GET /balance/{address}`

**Refresh**: Auto-refresh every 10 seconds, or manual pull-to-refresh

---

#### **Screen 2: Identity Management**

**Purpose**: Display and manage user identity, credentials, verification status

**Layout**:
```
┌─────────────────────────────────────┐
│  Identity Management         ← Back |
├─────────────────────────────────────┤
│  👤 YOUR IDENTITY                   │
│  ┌───────────────────────────────┐  │
│  │ Address: trustnet1abc...      │  │
│  │ Status: 🟢 VERIFIED           │  │
│  │ Registered: Feb 9, 2026       │  │
│  │ Last Activity: 2 hrs ago      │  │
│  └───────────────────────────────┘  │
├─────────────────────────────────────┤
│  🔐 GOVERNMENT CREDENTIALS          │
│  ┌───────────────────────────────┐  │
│  │ ID Type: Passport             │  │
│  │ Issuer: United States         │  │
│  │ Verified: ✅                  │  │
│  │ Hash: 8f3a2b1c...            │  │
│  └───────────────────────────────┘  │
├─────────────────────────────────────┤
│  📋 CREDENTIALS VERIFICATION        │
│  [Add Government ID] [View Hashes] │
│  [Verify Signature]                │
└─────────────────────────────────────┘
```

**Features**:
- Display address (copy to clipboard)
- Show verification status and date
- Display government credential hash
- Verify signature with PassportValidator
- Add new credentials (NFC passport scan - future)

---

#### **Screen 3: Transactions**

**Purpose**: Show transaction history and details

**Layout**:
```
┌─────────────────────────────────────┐
│  Transactions                ← Back |
├─────────────────────────────────────┤
│  🔍 Filter: All | Sent | Received │
├─────────────────────────────────────┤
│  📤 Sent TRUST to alice...         │
│  Amount: 100 TRUST | Feb 9, 13:27 │
│  Status: ✅ Confirmed              │
│  ┌───────────────────────────────┐  │
│  │ TX Hash: 0xdef456...          │  │
│  │ Block: 12,540                 │  │
│  └───────────────────────────────┘  │
├─────────────────────────────────────┤
│  📥 Received from bob...            │
│  Amount: 50 TRUST | Feb 8, 19:15   │
│  Status: ✅ Confirmed              │
│  ┌───────────────────────────────┐  │
│  │ TX Hash: 0xabc123...          │  │
│  │ Block: 12,520                 │  │
│  └───────────────────────────────┘  │
├─────────────────────────────────────┤
│  [Load More]                        │
└─────────────────────────────────────┘
```

**Features**:
- List recent transactions (10 per page)
- Show direction (sent/received), amount, timestamp
- Display confirmation status
- Tap for details (tx hash, block height)
- Filter by direction

---

#### **Screen 4: Settings**

**Purpose**: Configure app and manage security

**Layout**:
```
┌─────────────────────────────────────┐
│  Settings                    ← Back |
├─────────────────────────────────────┤
│  🔗 NODE CONFIGURATION              │
│  ┌───────────────────────────────┐  │
│  │ API Endpoint                  │  │
│  │ http://trustnet.local:1317    │  │
│  │ [Edit]                        │  │
│  │ Status: 🟢 Connected          │  │
│  └───────────────────────────────┘  │
├─────────────────────────────────────┤
│  🔒 SECURITY                        │
│  ┌───────────────────────────────┐  │
│  │ Biometric Unlock: ✅ ON       │  │
│  │ (Face ID / Touch ID)          │  │
│  │ [Settings]                    │  │
│  └───────────────────────────────┘  │
├─────────────────────────────────────┤
│  🎨 APPEARANCE                      │
│  ┌───────────────────────────────┐  │
│  │ Theme: System (Dark/Light)    │  │
│  │ [Change]                      │  │
│  └───────────────────────────────┘  │
├─────────────────────────────────────┤
│  ℹ️ ABOUT                           │
│  TrustNet iOS v1.0                  │
│  © 2026 TrustNet Foundation         │
│  [Privacy] [Terms] [Licenses]      │
└─────────────────────────────────────┘
```

**Features**:
- Configure node API endpoint
- Test connection
- Enable/disable biometric unlock
- Theme picker
- Privacy & license links

---

## 4. Core Features (Phase 1 - MVP)

### 4.1 Dashboard
- ✅ Real-time node status (connected/synced)
- ✅ Display user reputation score (0-100)
- ✅ Display TRUST token balance (with USD conversion)
- ✅ Auto-refresh every 10 seconds
- ✅ Manual pull-to-refresh

### 4.2 Identity Management
- ✅ Display wallet address and verification status
- ✅ Show registered identity details
- ✅ Display government credential hash (when available)
- ✅ Verify credential signature using PassportValidator
- ✅ Copy address to clipboard

### 4.3 Transactions (Phase 2)
- View transaction history
- Filter by direction (sent/received)
- Show transaction details (hash, block, timestamp)
- Pagination (load more)

### 4.4 Settings
- Configure node API endpoint
- Test API connection
- Biometric/Face ID unlock
- Theme selection
- About & license info

### 4.5 Security (All Phases)
- Private keys in Keychain (never in memory)
- Biometric authentication for sensitive operations
- AES-256-GCM for cached sensitive data
- TLS 1.3 for all network communication
- Session timeout (15 minutes)

---

## 5. API Integration

### 5.1 Node REST API Endpoints

**Authentication**: OAuth2 / JWT Bearer token (stored in Keychain)

```swift
// Node Status
GET /api/v1/node/status
Response: {
  "connected": true,
  "blockHeight": 12547,
  "syncPercentage": 100.0,
  "peers": 5,
  "timestamp": 1707481800
}

// Get Identity
GET /api/v1/identity/{address}
Response: {
  "address": "trustnet1abc...",
  "publicKey": "abc...",
  "name": "John Doe",
  "status": "VERIFIED",
  "credentialHash": "8f3a2b1c...",
  "registeredAt": 1707000000
}

// Get Reputation
GET /api/v1/reputation/{address}
Response: {
  "address": "trustnet1abc...",
  "score": 85,
  "endorsements": 47,
  "lastUpdated": 1707481800
}

// Get Balance
GET /api/v1/balance/{address}
Response: {
  "address": "trustnet1abc...",
  "amount": "2547500000",
  "denom": "utrust",
  "usdValue": 12737.50
}

// Get Transactions
GET /api/v1/transactions/{address}?limit=10&offset=0
Response: {
  "transactions": [
    {
      "hash": "0xdef456...",
      "type": "SEND",
      "from": "trustnet1abc...",
      "to": "trustnet1xyz...",
      "amount": "100000000",
      "blockHeight": 12540,
      "timestamp": 1707481200,
      "status": "SUCCESS"
    },
    ...
  ],
  "total": 156
}

// Verify Credential
POST /api/v1/verify/credential
Body: {
  "documentData": "base64-encoded-data",
  "signature": "base64-encoded-signature",
  "publicKey": "base64-encoded-public-key"
}
Response: {
  "valid": true,
  "message": "Signature verified successfully"
}
```

---

## 6. Data Models

### 6.1 Swift Structures

```swift
// Node Status
struct NodeStatus: Codable {
    let connected: Bool
    let blockHeight: Int64
    let syncPercentage: Double
    let peers: Int
    let timestamp: Int64
}

// Identity
struct Identity: Codable {
    let address: String
    let publicKey: String
    let name: String
    let status: VerificationStatus
    let credentialHash: String?
    let registeredAt: Int64
}

enum VerificationStatus: String, Codable {
    case unverified = "UNVERIFIED"
    case verified = "VERIFIED"
    case revoked = "REVOKED"
}

// Reputation
struct Reputation: Codable {
    let address: String
    let score: Int  // 0-100
    let endorsements: Int
    let lastUpdated: Int64
}

// Balance
struct Balance: Codable {
    let address: String
    let amount: String  // In utrust (smallest unit)
    let denom: String   // "utrust"
    let usdValue: Double
}

// Transaction
struct Transaction: Codable {
    let hash: String
    let type: TransactionType
    let from: String
    let to: String
    let amount: String
    let blockHeight: Int64
    let timestamp: Int64
    let status: TransactionStatus
}

enum TransactionType: String, Codable {
    case send = "SEND"
    case receive = "RECEIVE"
    case register = "REGISTER"
    case endorsement = "ENDORSEMENT"
}

enum TransactionStatus: String, Codable {
    case pending = "PENDING"
    case success = "SUCCESS"
    case failed = "FAILED"
}
```

---

## 7. Security Requirements

### 7.1 Key Management
- Generate P256 private key on device (never transmitted)
- Store in iOS Keychain with access control
- Require biometric authentication for signing operations
- Support key backup/recovery (future: Shamir secret sharing)

### 7.2 Network Security
- TLS 1.3 only (no fallback to older versions)
- Certificate pinning for API endpoints
- Validate SSL/TLS certificates
- Enforce HTTPS only

### 7.3 Data Security
- AES-256-GCM for caching sensitive data
- Keychain for credentials (passwords, tokens)
- No plaintext storage of private keys
- Auto-logout after 15 minutes inactivity

### 7.4 Biometric Authentication
- Support Face ID and Touch ID
- Require biometric for sensitive operations (signing, viewing key)
- Graceful fallback to passcode
- Cannot disable if enrolled (security-first design)

---

## 8. Implementation Roadmap

### **Phase 1: MVP (4 weeks)** ✅ Start Here
- Dashboard screen (node status, reputation, balance)
- Identity display screen
- Settings (API configuration, biometric setup)
- Basic API integration (read-only)
- Keychain secure storage
- Biometric authentication

### **Phase 2: Extended Features (4 weeks)**
- Transaction history screen
- Transaction filtering/search
- Government ID verification with PassportValidator
- Document upload and signature verification
- Transaction signing

### **Phase 3: Advanced (6 weeks)**
- NFC passport/ID reading (ICAO 9303 standard)
- Key backup via Shamir secret sharing
- Push notifications (node updates)
- Multi-wallet support
- Hardware key support (Ledger/Trezor)

### **Phase 4: Network (Ongoing)**
- Network discovery visualization
- Peer monitoring
- Reputation trending charts
- Cross-chain transaction support (IBC)

---

## 9. Testing Strategy

### 9.1 Unit Tests
- Test PassportValidator integration (ECDSA P256 validation)
- Test API response parsing
- Test data model serialization
- Test Keychain operations

### 9.2 Integration Tests
- Mock Node API endpoints
- Test full Dashboard data flow
- Test Identity verification with PassportValidator
- Test network error handling

### 9.3 Manual Testing
- iOS Simulator (iPhone 14 Pro Max)
- Real device (iPhone 14+)
- Offline mode handling
- Biometric authentication flows
- Low battery/connectivity scenarios

### 9.4 Security Testing
- Keychain access validation
- Biometric authentication bypass attempts
- Network certificate validation
- Session timeout enforcement

---

## 10. Definition of Done

### MVP Complete When:
- ✅ Dashboard displays real node status (mock API if needed)
- ✅ Reputation score 0-100 rendered with visual indicator
- ✅ TRUST balance displayed with USD conversion
- ✅ Identity screen shows address, status, credential hash
- ✅ PassportValidator signature verification working
- ✅ Settings screen configures API endpoint
- ✅ Biometric unlock implemented
- ✅ Keychain secure storage for credentials
- ✅ App builds and runs on iPhone 14 Pro Max simulator
- ✅ All 4/4 unit tests for PassportValidator pass
- ✅ No crashes, proper error handling

---

## References

- **TrustNet Whitepaper**: `/trustnet-wip/WHITEPAPER_v3.md`
- **PassportValidator Library**: `/ios/TrustNetValidator/PassportValidator.swift`
- **Node API Docs**: (To be created)
- **Alpine VM Dashboard**: Screenshot reference for UI/UX design

---

**Last Updated**: February 9, 2026
**Status**: Approved for Phase 1 Implementation
