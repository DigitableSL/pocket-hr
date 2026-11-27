# DT-PocketHR (`cn_pocket_hr`) — AI Context & Token-Saving Rules

## 1. Project Overview
- **Stack**: Flutter (Dart `^3.5.4`) mobile & tablet HR/attendance app.
- **Target Platforms & Devices**: **iOS (`ios/` — iPhone & iPad, `TARGETED_DEVICE_FAMILY = "1,2"`) and Android (`android/` — smartphones & tablets)**. Ignore `linux/`, `macos/`, `windows/`, and `web/`.
- **Flavors / Tenants**: `domex`, `malkey`, `mahajana`, `digitable` (entry points: `lib/main_<flavor>.dart`, config: `lib/config/flavor_config.dart`).
- **Linux CI Case-Sensitivity Rule (CRITICAL)**: GitHub Actions builds Android on **Linux (`ubuntu-latest`)**, which has a strictly case-sensitive filesystem (unlike macOS). Always use exact Git-tracked lowercase paths in Dart `import` statements and new file paths (e.g., `package:cn_pocket_hr/screens/...` and `lib/screens/...`, NEVER `lib/Screens/...`), and use LF (`\n`) line endings + forward slashes (`/`).

## 2. Token Efficiency Rules (CRITICAL)
1. **Never read entire large files**: Use `StartLine` and `EndLine` (or `grep -n` first) on large files:
   - `lib/api/api_service.dart` (~2,500 lines)
   - `lib/Screens/team/devices/mobile_team.dart` (~2,500 lines)
   - `lib/Screens/todos/devices/mobile_todos_screen.dart` (~1,800 lines)
   - `lib/Screens/leave/devices/mobile_leave_request_page.dart` (~1,800 lines)
   - `lib/Screens/home/devices/mobile_home.dart` (~1,500 lines)
   - `lib/Screens/attendance/devices/mobile_attendance.dart` (~1,500 lines)
2. **Never read generated files in full**:
   - Skip `lib/database/app_database.g.dart` (read `lib/database/app_database.dart` instead).
   - Skip `lib/l10n/app_localizations*.dart` (~6,100 lines total). Inspect `lib/l10n/app_en.arb`, `app_si.arb`, `app_ta.arb` and use targeted `grep -n` if manual edits to `app_localizations*.dart` are required.
   - Skip `pub_log.txt` and `pubspec.lock`.
3. **Constraint-Based Responsiveness**: Screens under `lib/Screens/<feature>/devices/mobile_<feature>.dart` serve both mobile and tablet/foldable devices via `ResponsiveLayout` (`lib/ui/responsive_layout.dart`), which centers and constrains width (`<= 600dp`) with an adjusted `MediaQuery` size on tablets.
4. **Concise responses**: Keep explanations brief and link directly to modified symbols/lines.

## 3. Architecture Quick Map (Avoid Broad Searches)
- **API Reference (`docs/API_REFERENCE.md`)**: Complete endpoint, header (`X-App-Version`, `X-Platform`, update headers), auth, and payload map (read this first instead of scanning `lib/api/api_service.dart`; live PII-free schemas in `docs/api_schemas_live.json`, refreshed via `tooling/probe_apis.py`).
- **Native MethodChannel (`asia.ceynet.pocket/security`)**:
  - Android: `android/app/src/main/kotlin/asia/ceynet/human/pocket/MainActivity.kt` (`isDevModeEnabled`, `isMockLocation`, `isAutoTimeEnabled`, `playScanTone`, `getAndroidId`)
  - iOS: `ios/Runner/AppDelegate.swift`
- **Core Services (`lib/services/`)**:
  - `security_service.dart`: Device security & anti-spoofing (`verifyDeviceSecurity`, `verifyPosition`, `startContinuousMonitoring`).
  - `location_service.dart`: Shared GPS position stream & battery-efficient location management.
  - `offline_attendance_service.dart`: Drift SQLite FIFO queue (`lib/database/app_database.dart`, `schemaVersion = 2` with `location_accuracy` & `distance`) for all attendance punches.
  - `token_refresh_service.dart`: Process-wide single-flight OAuth token refresh (60s skew buffer, 8s timeout, `sso_client_id` fallback).
  - `fcm_service.dart`: Firebase push notifications & global `navigatorKey`.
  - `sso_service.dart`: OAuth/SSO login flow.
- **Helpers & Interceptors (`lib/helpers/` & `lib/api/`)**:
  - `lib/api/custom_http.dart`: Centralized HTTP wrapper attaching `X-App-Version`/`X-Platform`/device headers, auto-refreshing & retrying `401` once, and running `TimeValidator`, `AppUpdateHelper`, and `SessionValidator` on every response.
  - `lib/helpers/app_update_helper.dart`: Header-driven hard (`X-App-Force-Update: true` / HTTP `426`) and soft (`X-App-Update-Available: true`) update bottom sheets using `X-App-Update-Url`.
  - `lib/helpers/time_validator.dart`: Checks server HTTP `Date` / `timestamp` vs device UTC clock (180s max drift).
  - `lib/helpers/session_validator.dart`: Handles 401/419 expiration while deferring to silent refresh when `refresh_token` is present.
  - `lib/helpers/logout.dart`: `LogoutHelper.logout()` and `LogoutHelper.forceLogout()` (wipes storage + secure storage).

## 4. Learning & Industry Terminology Preference (ALWAYS FOLLOW)
- When proposing designs, explaining architecture, or making code changes, **explicitly name and briefly explain the standard industry terms** for the UI elements, Flutter widgets/patterns, and Android/iOS platform concepts involved (e.g. *Modal Bottom Sheet*, *Progressive Disclosure / Expandable Card*, *BFF (Backend-for-Frontend) endpoint*, *Single-Flight Token Refresh*, *HTTP Interceptor*, *SafeArea / Edge-to-Edge Insets*, *MethodChannel*, *Provisioning Profile*, *Staged Rollout*, *Schema Migration*).
- Keep explanations concise (1–2 lines per concept) so the user steadily builds practical **Flutter, Android, and iOS** engineering vocabulary alongside every change.
