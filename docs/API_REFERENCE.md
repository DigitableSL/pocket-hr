# DT-PocketHR API Reference

> **Purpose:** Concise reference of all backend APIs used by `cn_pocket_hr` for developers and AI agents.  
> **Live Schema Verification:** Run `tooling/probe_apis.py` against a test Bearer token to verify/refresh read-only `GET` response schemas into `docs/api_schemas_live.json` (PII is automatically stripped).

---

## 1. Base URLs & Flavors

| Service | Base URL | Source |
| :--- | :--- | :--- |
| **HR Core API** (all flavors: `domex`, `malkey`, `mahajana`, `digitable`) | `https://api.human.go.digitable.io/human/v2/api` | `lib/main_<flavor>.dart`, `lib/api/config.dart` |
| **OAuth / Token Refresh** | `https://accounts.go.digitable.io/token` | `lib/services/token_refresh_service.dart` |

Tenant routing is passed via the `tenant` query parameter (e.g. `?tenant=domex`) and/or request body field `tenant`, resolved via `FlavorConfig.instance.tenant` or JWT `client_id`.

---

## 2. Global Headers & HTTP Interceptors

All requests routed through `lib/api/custom_http.dart` automatically attach:

| Header | Value / Source |
| :--- | :--- |
| `Authorization` | `Bearer <access_token>` (auto-refreshed proactively within 60s of expiry and retried once on `401` via `TokenRefreshService`) |
| `Device-Time` | Device UTC ISO-8601 timestamp (`TimeValidator` enforces ≤ 180s drift vs server `Date`) |
| `device-id` / `device-identifier` | Android: `Settings.Secure.ANDROID_ID` (via `MainActivity.kt`); iOS: `identifierForVendor` |
| `device-model`, `device-brand`, `device-platform`, `device-version` | Collected via `DeviceDetailsService` (cached 5 min) |
| `device-ip`, `battery-level` | Wi-Fi IP & battery % |
| `X-App-Version` | `<version>+<buildNumber>` from `PackageInfo` (e.g. `1.4.2+31`) |
| `X-Platform` | `android` or `iphone` |

**Response Interceptors (every `custom_http` response):**
1. `TimeValidator.validate(res)` — blocks/warns if device clock drifts > 180s from server UTC.
2. `AppUpdateHelper.handlePotentialUpdateRequired(statusCode, body)` — prompts force-update if server requires a newer app version.
3. `SessionValidator.validate(res, url)` — forces logout on `400`/`401`/`419` from `/token` or unrecoverable `401`/`419` without a refresh token.

---

## 3. Endpoints

### Auth & SSO
| Method | Path | Query / Body | Notes & Source |
| :--- | :--- | :--- | :--- |
| `POST` | `/sso/mobile-start` | JSON: `{ tenant, device_id?, model? }` | Starts PKCE SSO; returns `{ verifier, state, authUrl }`. (`lib/services/sso_service.dart`) |
| `POST` | `/sso/mobile-callback` | JSON: `{ tenant, code, state, verifier }` | Completes PKCE SSO; returns `{ access_token, refresh_token }`. (`lib/services/sso_service.dart`) |
| `POST` | `https://accounts.go.digitable.io/token` | JSON: `{ grant_type: "refresh_token", refresh_token, client_id }` | Single-flight silent token refresh (8s timeout). (`lib/services/token_refresh_service.dart`) |
| `GET` | `/auth/me` | `?tenant=<tenant>` | Authenticated user profile, permissions, `mobileMenu`, `remoteValue`. (`lib/api/api_service.dart#L665`) |

### Attendance
| Method | Path | Query / Body | Notes & Source |
| :--- | :--- | :--- | :--- |
| `POST` | `/attendance/check-in` | Form/JSON: location (`lat`, `lng`), `qr_code?`, `is_remote?`, `device_id`, `device_identifier`, `tenant`, timestamp | Supports offline SQLite queue via `OfflineAttendanceService` (`lib/api/api_service.dart#L160`) |
| `POST` | `/attendance/check-out` | Same as check-in | Supports offline SQLite queue (`lib/api/api_service.dart#L196`) |
| `GET` | `/attendance/user/{tenant}/{uid}/` | `?tenant=<tenant>&month=<MM>&year=<YYYY>` (falls back to `/attendance/user/{uid}/`) | Monthly attendance records (`lib/api/api_service.dart#L1332`) |
| `POST` | `/attendance/mark` | `?tenant=<tenant>`, JSON body | Manager/team attendance mark (`lib/api/api_service.dart#L2315`) |

### Leave Management
| Method | Path | Query / Body | Notes & Source |
| :--- | :--- | :--- | :--- |
| `GET` | `/leave` | `?tenant=<tenant>&userId=<uid>&...` | List user's leave requests (`lib/api/api_service.dart#L785`, `lib/services/leave_service.dart`) |
| `GET` | `/leave/balance` | `?userId=<uid>&tenant=<tenant>` | Available leave balances per leave type (`lib/api/api_service.dart#L444`) |
| `GET` | `/leave/apply-eligibility/{uid}` | `?tenant=<tenant>` | Allowed leave date range & payroll lock dates (`lib/api/api_service.dart#L481`) |
| `POST` | `/leave/store` | Form/JSON: leave type, duration (`full`/`half`/`short`), `from`, `to`, `reason`, `tenant` | Submit leave request (`lib/api/api_service.dart#L299`) |
| `POST` | `/leave/{leaveId}/approve` | `?tenant=<tenant>` | Approve team member leave (`lib/api/api_service.dart#L2213`) |
| `POST` | `/leave/{leaveId}/reject` | `?tenant=<tenant>`, JSON: `{ reason }` | Reject team member leave (`lib/api/api_service.dart#L2236`) |

### Todos / Approvals
| Method | Path | Query / Body | Notes & Source |
| :--- | :--- | :--- | :--- |
| `GET` | `/todos` | `?tenant=<tenant>&...` | Pending & processed approval todos (`lib/api/api_service.dart#L517`) |
| `POST` | `/todos/{todoId}/update` | `?tenant=<tenant>`, JSON: `{ status, reason? }` | Approve or reject a todo item (`lib/api/api_service.dart#L2259`, `#L2287`) |

### Team & Locations
| Method | Path | Query / Body | Notes & Source |
| :--- | :--- | :--- | :--- |
| `GET` | `/teams/locations-by-userid/{userId}` | — | Allowed geofence/QR punch locations (`lib/api/api_service.dart#L2089`) |
| `GET` | `/teams/my-team` | `?tenant=<tenant>` | Team hierarchy & direct reports (`lib/api/api_service.dart#L2176`) |
| `GET` | `/teams/my-team/leaves` | `?tenant=<tenant>` | Team leave requests (`lib/api/api_service.dart#L2194`) |
| `GET` | `/teams/my-team/attendance` | `?tenant=<tenant>` | Team attendance overview (`lib/api/api_service.dart#L2343`) |

### Payroll, Allowances & Debts
| Method | Path | Query / Body | Notes & Source |
| :--- | :--- | :--- | :--- |
| `GET` | `/payroll/salary-slips/user/{uid}` | `?tenant=<tenant>&year=<YYYY>` | List salary slips (`lib/api/api_service.dart#L1862`) |
| `GET` | `/payroll/salary-slips/{id}` | `?tenant=<tenant>` | Salary slip detail (`lib/api/api_service.dart#L1936`) |
| `GET` | `/payroll/salary-slips/{id}/download` | `?tenant=<tenant>` | Download salary slip PDF (`lib/api/api_service.dart#L2001`) |
| `GET` | `/variables/variables/{userId}` | `?tenant=<tenant>` | Allowances & deductions (`lib/api/api_service.dart#L972`) |
| `GET` | `/debts/{uid}` | `?tenant=<tenant>` | Debts & loans (`lib/api/api_service.dart#L1062`, `lib/services/debt_service.dart`) |

### Notifications & Profile Media
| Method | Path | Query / Body | Notes & Source |
| :--- | :--- | :--- | :--- |
| `POST` | `/teams/{userId}/fcm-token` | JSON: `{ fcm_token }` | Registers Firebase push token (`lib/services/fcm_service.dart#L571`) |
| `HEAD`/`GET` | `/documents/view/{uid}/{fileName}?size=150-150` | Fallback: `/uploads/profile/{uid}/{fileName}` | Profile photo resolution (`lib/api/api_service.dart#L1765`) |

---

## 4. Keeping Response Schemas Up to Date

Use `tooling/probe_apis.py` to probe **read-only `GET` endpoints** with a test Bearer token and generate/diff `docs/api_schemas_live.json` (all PII values are replaced with data types):

```bash
export POCKET_HR_TOKEN="<your-test-bearer-jwt>"
export POCKET_HR_TENANT="domex"
python3 tooling/probe_apis.py
```

- **Safe by design:** Only executes `GET` requests (never calls `POST`/`PUT`/`DELETE`).
- **Drift detection:** Compares the new schema against the existing `docs/api_schemas_live.json` and prints added, removed, or type-changed fields.
