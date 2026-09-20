# Engineering Task Tracker

Offline Flutter app for engineering task tracking. **Managers** create users, assign and edit tasks; **employees** see their own tasks, update status, and leave comments. Each install keeps its own local SQLite database — no server is required to run the shipped Windows or Android builds.

## Tech stack

| Layer | Implementation |
|--------|----------------|
| UI | Flutter (`frontend/`) — phone shells + responsive desktop shell |
| Business logic & auth | `frontend/lib/services/api_service.dart` |
| Database | Local SQLite via `sqflite` (Android) / `sqflite_common_ffi` (Windows/Linux) |
| Passwords | PBKDF2-HMAC-SHA256 (`frontend/lib/data/password_hasher.dart`) |

> **Legacy:** The Django project under `tasks/` and `task_tracker/` is **not** used by the current Flutter app. Keep it only if you still need the old HTTP API for reference.

## Roles

App role comes from `users.is_manager` in SQLite (exposed as `AppUser.isManager` / `role`).

| Role | Capabilities |
|------|----------------|
| **Manager** | All tasks and users; create/update/delete tasks; reassign; set priority; create users; comments on any accessible task |
| **Employee** | Only tasks assigned to them; update **status** only; comments on those tasks |

After login, `role_home.dart` → `homeForUser` / `ResponsiveAppHome` opens the manager or employee shell (mobile or desktop).

## Data flow

1. `main.dart` initializes bindings, opens SQLite (`DatabaseHelper`), seeds a default manager if the DB is empty, then shows `LoginScreen`.
2. `ApiService.login` looks up the user, checks `is_active`, verifies the password hash, and stores `currentUser` in memory.
3. Screens call `ApiService` methods (same names as the old HTTP client). Those methods run SQL and enforce permissions — they do **not** call a network API.
4. Logout clears `currentUser` only (session is in-memory; closing the app logs you out).

### Schema (local)

- `users` — `id`, `username`, `password_hash`, `email`, `is_manager`, `is_active`
- `tasks` — `id`, `title`, `description`, `priority`, `status`, `due_date`, `assignee_id`, `created_at`, `updated_at`
- `task_comments` — `id`, `task_id`, `author_id`, `body`, `created_at`

DB file: `task_tracker.db` under the app documents directory (per device / per user profile).

## First launch

If there are no users yet, the app seeds:

| Username | Password | Role |
|----------|----------|------|
| `manager` | `manager123` | Manager |

Change this account (or create another manager and stop using the seed) before treating any install as production-ready. The seed password is currently hardcoded in `database_helper.dart`.

## How to run (development)

```powershell
cd frontend
flutter pub get
flutter run -d windows
# or
flutter run -d <android-device>
```

Web is **not** supported (SQLite path throws on web).

## How to build

```powershell
cd frontend
flutter pub get
flutter build windows --release
flutter build apk --release
```

### Windows installer (single .exe)

Requires [Inno Setup 6](https://jrsoftware.org/isinfo.php) (`winget install JRSoftware.InnoSetup`).

```powershell
# After flutter build windows --release
& "$env:LocalAppData\Programs\Inno Setup 6\ISCC.exe" installer\task_tracker.iss
```

Output: `dist\EngineeringTaskTracker-Setup.exe` (script lives in `installer/task_tracker.iss`).

### Android APK

`frontend\build\app\outputs\flutter-apk\app-release.apk`

## Known limitations

- **Per-device data only** — no sync between phone and PC installs.
- **No remote error tracking** — `ApiService` often swallows exceptions into empty/`null` results; add Sentry (or similar) if you need production visibility.
- **Seed credentials in source** — default manager password is hardcoded; change before hand-off to real users.
- **README vs legacy Django** — ignore Django run/`API_BASE_URL` instructions if you are using the offline builds.
- **Access model** — rules are enforced in Dart against the local DB; anyone with filesystem access to `task_tracker.db` can read task content (passwords are hashed).
