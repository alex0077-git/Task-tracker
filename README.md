# Engineering Task Tracker

An offline, cross-platform task management app built with Flutter. Managers create users and assign work; employees see only their own tasks, update status, and discuss progress in comments. Everything runs locally on SQLite, so the shipped Windows and Android builds need **no server, no internet, and no setup**.

> **History:** this project started as a Flutter + Django REST app. It was migrated to a fully offline architecture so it can be handed over as a standalone installer/APK. The original Django backend is preserved in [`archive/django-legacy/`](archive/django-legacy/) for reference only.

---

## Features

**Managers**
- Create, edit, delete, and reassign tasks
- Set priority (Low / Medium / High) and due dates
- Create employee and manager accounts
- Dashboard with a "Tasks by Status" chart (Pending, In Progress, Completed, Overdue)
- Team / Employees view showing each person's workload

**Employees**
- See only the tasks assigned to them
- Update task status (To Do → In Progress → Completed)
- Comment on their tasks

**Everyone**
- Title search (matches from the start of the title, debounced as you type)
- Filters for status, priority, and assignee that combine with search and "overdue only"
- Overdue highlighting for any unfinished task past its due date
- Priority tags, with High-priority tasks sorted first in the mobile list
- Responsive UI: bottom-navigation phone layout and a sidebar desktop layout

## Business rules

| Rule | Behaviour |
|------|-----------|
| One incomplete task per day | An employee cannot have two non-completed tasks due on the same date. Applies on create, edit, and reassign. |
| Role enforcement | Permissions are checked in the service layer, not just hidden in the UI. Employees cannot read or modify tasks that aren't assigned to them. |
| Validation | Title required; status and priority must be valid values; passwords must be at least 8 characters; usernames are unique (case-insensitive login). |
| Overdue | Due date is before today **and** status is not `Completed`. |

## Tech stack

| Layer | Implementation |
|-------|----------------|
| UI | Flutter / Material 3 (`frontend/lib/screens`, `frontend/lib/desktop`, `frontend/lib/widgets`) |
| State & list logic | Shared controllers in `frontend/lib/shared/` |
| Business logic & auth | `frontend/lib/services/api_service.dart` |
| Database | SQLite via `sqflite` (Android) and `sqflite_common_ffi` (Windows / Linux) |
| Password hashing | Salted PBKDF2-HMAC-SHA256, 100,000 iterations (`frontend/lib/data/password_hasher.dart`) |
| Charts | `fl_chart`, plus a custom status overview widget |
| Windows packaging | Inno Setup (`installer/task_tracker.iss`) |

## Architecture

```
┌──────────────────────────────────────────────┐
│  Screens / Desktop shell / Widgets           │  UI
├──────────────────────────────────────────────┤
│  Shared controllers (search, filters, stats) │  UI state
├──────────────────────────────────────────────┤
│  ApiService  (auth, permissions, validation) │  Business logic
├──────────────────────────────────────────────┤
│  DatabaseHelper + PasswordHasher             │  Data
├──────────────────────────────────────────────┤
│  SQLite file: task_tracker.db                │  Local storage
└──────────────────────────────────────────────┘
```

`ApiService` keeps the same method names as the original HTTP client, so the screens didn't need to change when the Django backend was replaced. Its methods now run SQL directly and enforce permissions locally.

### Startup and auth flow

1. `main.dart` initialises Flutter bindings and opens the database via `DatabaseHelper`.
2. On first launch (no users yet), a default manager account is seeded.
3. `LoginScreen` calls `ApiService.login`, which finds the user (case-insensitive), checks `is_active`, and verifies the password hash.
4. `role_home.dart` routes to the manager or employee experience, using the mobile shell below 600 px width and the desktop shell otherwise.
5. The session lives in memory only. Closing the app logs the user out.

### Responsive layout

| Width | Layout |
|-------|--------|
| < 600 px | Phone shell with bottom navigation |
| 600 – 1099 px | Desktop shell with collapsed sidebar |
| ≥ 1100 px | Desktop shell with expanded sidebar |

Manager navigation: Dashboard, Tasks, Employees, Profile (Home, Tasks, Team, Profile on phones).
Employee navigation: Dashboard, My Tasks, Profile (Home, Profile on phones).

### Database schema

```
users          id, username (unique), password_hash, email, is_manager, is_active
tasks          id, title, description, priority, status, due_date,
               assignee_id → users.id, created_at, updated_at
task_comments  id, task_id → tasks.id (ON DELETE CASCADE),
               author_id → users.id, body, created_at
```

Allowed values: **status** `To Do`, `In Progress`, `Completed`; **priority** `Low`, `Medium`, `High`.

The database file is `task_tracker.db` in the app's documents directory, so each device and each OS user profile has its own independent data.

## Getting started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart `^3.12.2`)
- For Windows builds: Visual Studio with the "Desktop development with C++" workload
- For Android builds: Android Studio / Android SDK

### Run in development

```powershell
cd frontend
flutter pub get
flutter run -d windows
# or
flutter run -d <android-device-id>
```

Web is **not supported** (SQLite is unavailable there and the app throws on startup).

### Default login

On first launch the app creates a manager account:

| Username | Password |
|----------|----------|
| `manager` | `manager123` |

Log in, create real accounts from the Employees / Team screen, and treat this seed password as a development default.

### Run the tests

```powershell
cd frontend
flutter test
```

## Building for release

```powershell
cd frontend
flutter pub get
flutter build windows --release
flutter build apk --release
```

**Android APK:** `frontend/build/app/outputs/flutter-apk/app-release.apk`

### Windows installer (single `.exe`)

Requires [Inno Setup 6](https://jrsoftware.org/isinfo.php) (`winget install JRSoftware.InnoSetup`). After `flutter build windows --release`:

```powershell
& "$env:LocalAppData\Programs\Inno Setup 6\ISCC.exe" installer\task_tracker.iss
```

Output: `dist\EngineeringTaskTracker-Setup.exe`. It installs per-user (no admin rights needed), adds a Start Menu entry, and offers an optional desktop shortcut.

## Project structure

```
Task-tracker/
├── frontend/                  Flutter app
│   ├── lib/
│   │   ├── main.dart          Entry point and theme
│   │   ├── data/              DatabaseHelper, PasswordHasher
│   │   ├── services/          ApiService (auth, permissions, queries)
│   │   ├── models/            Task, AppUser, TaskComment, TaskCounts
│   │   ├── shared/            Controllers for tasks, employees, dashboard, profile
│   │   ├── screens/           Phone UI (login, tasks, detail, team, profile)
│   │   ├── desktop/           Desktop shell, theme, breakpoints, screens
│   │   ├── widgets/           Priority tags, overdue badge, comments, chart
│   │   └── utils/             Date helpers
│   ├── android/ windows/ linux/ macos/ ios/ web/   Platform runners
│   └── test/                  Widget tests
├── installer/                 Inno Setup script for the Windows installer
└── archive/django-legacy/     Previous Django REST backend (unused)
```

## Known limitations

- **No sync.** Each install has its own database; phone and PC data are never merged.
- **No password change or account deactivation in the UI.** The `is_active` flag is enforced at login but can't yet be toggled from the app.
- **In-memory sessions.** Users log in again every time the app restarts.
- **Web is unsupported.**
- **Platform status.** Windows and Android are the tested release targets. Linux, macOS, and iOS runners exist from the Flutter template but aren't packaged or tested.

## Roadmap ideas

- Change-password and deactivate-user screens
- Export/import of the database for backup or moving between devices
- Optional sync service for teams that need shared data

## License

No license has been specified yet. Add a `LICENSE` file before sharing or accepting contributions.
