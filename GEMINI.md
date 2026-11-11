# DT-PocketHR (`cn_pocket_hr`) — AI Context & Token-Saving Rules

## 1. Project Overview
- **Stack**: Flutter (Dart `^3.5.4`) mobile & tablet HR/attendance app.
- **Target Platforms**: **iOS** (`ios/`) and **Android** (`android/`) ONLY. Ignore `linux/`, `macos/`, `windows/`, and `web/`.
- **Flavors / Tenants**: `domex`, `malkey`, `mahajana`, `digitable` (entry points: `lib/main_<flavor>.dart`, config: `lib/config/flavor_config.dart`).

## 2. Token Efficiency Rules (CRITICAL)
1. **Never read entire large files**: Use `StartLine` and `EndLine` (or `grep -n` first) on large files:
   - `lib/api/api_service.dart` (~2,500 lines)
   - `lib/Screens/team/devices/mobile_team.dart` & `tablet_team.dart` (~2,500 lines each)
   - `lib/Screens/todos/devices/mobile_todos_screen.dart` & `tablet_todos_screen.dart` (~1,800 lines each)
   - `lib/Screens/leave/devices/mobile_leave_request_page.dart` (~1,800 lines)
   - `lib/Screens/home/devices/mobile_home.dart` & `tablet_home.dart` (~1,500 lines each)
   - `lib/Screens/attendance/devices/mobile_attendance.dart` & `tablet_attendance.dart` (~1,500 lines each)
2. **Never read generated files in full**:
   - Skip `lib/database/app_database.g.dart` (read `lib/database/app_database.dart` instead).
   - Skip `lib/l10n/app_localizations*.dart` (~6,100 lines total). Inspect `lib/l10n/app_en.arb`, `app_si.arb`, `app_ta.arb` and use targeted `grep -n` if manual edits to `app_localizations*.dart` are required.
   - Skip `pub_log.txt` and `pubspec.lock`.
3. **Mobile + Tablet Parity**: Most screens under `lib/Screens/<feature>/devices/` have `mobile_<feature>.dart` and `tablet_<feature>.dart`. Locate exact line numbers via `grep -n` before reading or editing both.
4. **concise responses**: Keep explanations brief and link directly to modified symbols/lines.

## 3. Architecture Quick Map (Avoid Broad Searches)
- **Native MethodChannel (`asia.ceynet.pocket/security`)**:
  - Android: `android/app/src/main/kotlin/asia/ceynet/human/pocket/MainActivity.kt` (`isDevModeEnabled`, `isMockLocation`, `isAutoTimeEnabled`)
  - iOS: `ios/Runner/AppDelegate.swift`
- **Core Services (`lib/services/`)**:
  - `security_service.dart`: Device security & anti-spoofing (`verifyDeviceSecurity`, `verifyPosition`, `startContinuousMonitoring`).
  - `location_service.dart`: Shared GPS position stream & battery-efficient location management.
  - `offline_attendance_service.dart`: Drift SQLite queue (`lib/database/app_database.dart`) for offline attendance punches.
  - `fcm_service.dart`: Firebase push notifications & global `navigatorKey`.
  - `sso_service.dart`: OAuth/SSO login flow.
- **Helpers & Interceptors (`lib/helpers/` & `lib/api/`)**:
  - `lib/api/custom_http.dart`: HTTP wrapper running `TimeValidator.validate()` and `SessionValidator.validate()` on every API response.
  - `lib/helpers/time_validator.dart`: Checks server HTTP `Date` / `timestamp` vs device UTC clock (180s max drift).
  - `lib/helpers/session_validator.dart`: Handles 401/419 expiration while deferring to silent refresh when `refresh_token` is present.
  - `lib/helpers/logout.dart`: `LogoutHelper.logout()` and `LogoutHelper.forceLogout()` (wipes storage + secure storage).

