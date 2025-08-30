# HomeCraft Sauna — End-to-End Auth & Data Flow
*(ESP32 + Firebase Auth + Firestore, no RTDB)*

---

## LEGEND
DEVICE = ESP32 sauna control board  
APP = mobile app (owner)  
BROKER = HTTPS Cloud Function (runs as service account)  
AUTH = Firebase Auth (issues ID/refresh tokens)  
FS = Firestore (device registry, schedules, state, telemetry)  
NVS = non-volatile storage (a library and system that stores small amounts of data, such as configuration settings, directly into the ESP32's flash memory, allowing the data to persist even after the device loses power or restarts)  

## 0) Data model — what is saved where

**Firestore**
```bash
/devices/{deviceId}
publicKey (PEM; used by broker to verify device JWT)
ownerUid (uid of the app user who owns this device)
saunaId (logical sauna this device serves)
nonce (int; anti-replay counter; starts at 1)
enabled (bool; kill switch)
lastSeenAt (server timestamp; audit/health)
/saunas/{saunaId}
ownerUid (for rules)
schedule (JSON: timezone, version, effectiveAfter?, rules[])
compiled (optional JSON: precomputed intervals like today[])
state (targetTemp, mode=ON/OFF/AUTO, lastUpdate)
telemetry/{autoId} (device writes metrics/events)
```


**ESP32 (device)**
- Private key (secure element preferred; otherwise NVS).
- `idToken` (RAM; ~60 min lifetime).
- `refreshToken` (optional; NVS if you choose to store it).
- `compiled.today` (cached intervals for control loop).
- `currentSession` `{start, end, setpoint}` (drives heater if offline).
- `writeQueue` (small ring buffer of unsent telemetry).
- `lastNonce` (last acknowledged nonce for next device JWT).

---

## 1) Provisioning & linking

**Provision (factory or first boot)**
1. Device generates ES256 keypair (keeps private key).
2. Create Firestore doc `/devices/{deviceId}` with:
   - `publicKey`, `ownerUid=null`, `saunaId=null`, `nonce=1`, `enabled=true`.

**Install & link (user setup in app)**
3. App discovers device (BLE/SoftAP) and configures Wi-Fi on device.
4. App “claims” device → writes:
   - `/devices/{deviceId}.ownerUid = {uid}`
   - `/devices/{deviceId}.saunaId  = {saunaId}`
   - `/saunas/{saunaId}.ownerUid   = {uid}`

---

## 2) First auth handshake (device → broker → Auth)

**Roles**
- **BROKER** = HTTPS Cloud Function running as a dedicated service account.
- **AUTH** = Firebase Auth.

**Flow**
1. **Device** builds a short-lived `deviceJWT`:
   - Payload includes: `deviceId`, `nonce`, `iat`, `exp` (~60s).
   - Signed with device private key (ES256).
2. Device `POST` to **BROKER** with `deviceJWT`.
3. **BROKER** reads `/devices/{deviceId}` and verifies:
   - `enabled == true`, `alg == ES256`, signature valid with stored `publicKey`.
   - `nonce` matches the stored value.
   - `exp/iat` sane (accept small clock skew).
4. **BROKER** runs a Firestore **transaction**:
   - Assert `payload.nonce == doc.nonce`.
   - Update `doc.nonce = nonce + 1`, set `lastSeenAt = now`.
5. **BROKER** creates a **custom token** for `ownerUid` with claims:
   - `{ role: "device", deviceId, saunaId }`.
6. **BROKER** calls `signInWithCustomToken` to get:
   - `id_token`, optional `refresh_token`, `expires_in`.
7. **BROKER → Device** returns `{ idToken, refreshToken?, expiresIn }`.

> Device never holds a service-account credential. Nonce blocks replay.

---

## 3) Normal operation (reads/writes)

**Device boot sequence (happy path)**
1. Safe-OFF outputs; load from NVS: `compiled.today`, `currentSession`, `lastNonce`, `refreshToken?`.
2. Connect Wi-Fi (backoff + jitter).
3. NTP time sync.
4. Ensure auth:
   - If `idToken` valid → continue.
   - Else if `refreshToken` present → refresh.
   - Else → run broker handshake (Section 2).
5. Read schedule if needed:
   - `GET /saunas/{saunaId}/schedule` **only** when local `version` differs.
6. Compute or load compiled intervals; cache `compiled.today` + `currentSession`.
7. Control loop:
   - If `now ∈ [start, end)`: heater ON, regulate to setpoint; else OFF/AUTO.
8. Telemetry:
   - `POST /saunas/{saunaId}/telemetry` (timestamped).
   - If offline, push into `writeQueue` for later flush.

**App schedule edits (owner action)**
- App `PUT /saunas/{saunaId}/schedule` (increment `version`, optional `effectiveAfter`).
- Device periodically checks `schedule.version` (e.g., every 30–90s) and re-fetches on change.

**Optional state writes**
- Device or app may `PATCH /saunas/{saunaId}/state` (e.g., targetTemp, mode).

---

## 4) Resilience — Wi-Fi drop & power loss

**Wi-Fi drop**
- Continue running from NVS: `currentSession` drives heater until `end`.
- Queue telemetry locally.
- Retry Wi-Fi with exponential backoff + jitter.
- On reconnect:
  - If `idToken` still valid → resume reads/writes.
  - If expired → refresh token if present, else broker handshake.
  - Flush telemetry in order.
  - Check `schedule.version` and re-fetch if changed.

**Power loss**
- On restart:
  1. Safe-OFF → load from NVS: `compiled.today`, `currentSession`.
  2. If `now < currentSession.end`, resume ON until end (safety checks apply).
  3. Wi-Fi → NTP → ensure auth (refresh or broker).
  4. Flush queued telemetry (if persisted).
  5. Check `schedule.version` and resync if changed.

---

## 5) Firestore security (logic + example rules)

**Logic**
- Only the **owner** or the **linked device** may read/write a sauna:
  - Owner: `/saunas/{saunaId}.ownerUid == request.auth.uid`.
  - Device: `request.auth.token.role == "device"` and
    `request.auth.token.saunaId == {this sauna doc id}`.
- `/devices/{deviceId}`:
  - Readable by its owner for visibility.
  - Writes restricted to backend (broker/admin only).

**Example (Firestore Rules)**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /saunas/{saunaId} {
      allow read, write: if isOwner(saunaId) || isDevice(saunaId);

      function isOwner(saunaId) {
        return request.auth != null &&
          get(/databases/$(database)/documents/saunas/$(saunaId)).data.ownerUid
            == request.auth.uid;
      }

      function isDevice(saunaId) {
        return request.auth != null &&
          request.auth.token.role == "device" &&
          request.auth.token.saunaId == saunaId;
      }
    }

    match /devices/{deviceId} {
      allow read: if request.auth != null &&
        get(/databases/$(database)/documents/devices/$(deviceId)).data.ownerUid
          == request.auth.uid;
      allow write: if false; // backend/broker only
    }
  }
}
```

## 6) Token renewal strategies

**A) Broker only (simplest, safest)**  
Do not store a refresh token. When the `idToken` expires (or on 401), the device runs the broker handshake again.  
- Pro: no long-lived secret on the device  
- Con: about hourly calls to the broker

**B) Refresh token (fewer broker calls)**  
Store a `refreshToken` in NVS (encrypt at rest if possible). Refresh ~10 minutes before expiry; fall back to the broker on failure.  
- Pro: less load on the broker  
- Con: treat the refresh token like a password

**Recommendation:** start with **A**; add **B** later if needed.

---

## 7) Read/write timing map

| Actor      | When                | Path                              | Operation                                         |
|------------|---------------------|-----------------------------------|---------------------------------------------------|
| App        | Claim device        | `/devices/{deviceId}`             | Set `ownerUid`, `saunaId`                         |
| App        | Claim device        | `/saunas/{saunaId}`               | Set `ownerUid`                                    |
| App        | Edit schedule       | `/saunas/{saunaId}/schedule`      | `PUT` (bump `version`, set `effectiveAfter`?)     |
| Broker     | Auth success        | `/devices/{deviceId}`             | **Transaction**: `nonce++`, set `lastSeenAt`      |
| Device     | Boot / periodic     | `/saunas/{saunaId}/schedule`      | `GET` if local `version` differs                  |
| Device     | Runtime             | `/saunas/{saunaId}/telemetry`     | `POST` (buffer offline; flush on reconnect)       |
| Device/App | Optional            | `/saunas/{saunaId}/state`         | `PATCH` (target/mode)                             |

---

## 8) Nonce — what and why

- A **nonce** (“number used once”) is a per-device counter stored in Firestore.
- The device includes the current nonce in its signed `deviceJWT`.
- The broker accepts only the **exact** expected value, then increments the stored nonce in a Firestore **transaction**.
- This prevents **replay attacks**: a captured `deviceJWT` cannot be reused after the nonce advances.

---

## 9) Operational notes

- **Broker service account (least privilege):**
  - `roles/iam.serviceAccountTokenCreator` (on itself)
  - `roles/datastore.user` (to read `/devices` and run the nonce transaction)
- **Keep the broker warm:** set minimum instances to reduce cold starts.
- **Kill switch:** set `/devices/{deviceId}.enabled = false` to block new tokens immediately.
- **Clock hygiene:** the device uses NTP; the broker accepts small clock skew with a short `exp` (~60 seconds) on the `deviceJWT`.

---

## 10) Quick checklist

- [ ] Create `/devices` and `/saunas` collections with fields described above.  
- [ ] Deploy the **token broker** Cloud Function (verify + nonce transaction + custom token + exchange).  
- [ ] Add Firestore **Rules** to enforce owner or linked-device access.  
- [ ] Implement on ESP32: JWT sign, broker call, token storage, schedule cache, telemetry queue.  
- [ ] Add reconnect logic: Wi-Fi backoff, token refresh/broker fallback, flush queued telemetry.  
- [ ] Safety: Safe-OFF on boot, watchdog, over-temp cutoff.
