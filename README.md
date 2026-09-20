# Engineering Task Tracker

Internal task tracking for engineering work: **managers** create, assign, and edit tasks (and users); **employees** see their assigned tasks and update status. Comments are supported on tasks.

## Tech stack

- **Client:** Flutter (`frontend/`) — mobile and responsive desktop shells
- **API:** Django REST Framework (`tasks/`, `task_tracker/`)
- **Auth:** Session cookies (Flutter web + CSRF) and DRF token auth (mobile)
- **Data:** SQLite (`db.sqlite3`) + Django `User` + `UserProfile.is_manager` + `Task` / `TaskComment`

## Roles

App “manager” is **not** Django `is_staff`. It comes from:

- `UserProfile.is_manager == True`, or
- `user.is_superuser`

Django `/admin/` is restricted to **superusers** only.

After login, `role_home.dart` → `homeForUser` / `ResponsiveAppHome`:

- **Manager** → `AdminHomeScreen` (mobile) or `DesktopShell(isManager: true)`
- **Employee** → `EmployeeShellScreen` (mobile) or `DesktopShell(isManager: false)`

## Data flow

1. `frontend/lib/main.dart` → `LoginScreen`
2. Web: `GET /api/csrf/` then `POST /api/login/` with `X-CSRFToken` (session cookie via Dio `withCredentials`)
3. Mobile: `POST /api/login/` → store returned `token` → send `Authorization: Token …` on later calls
4. Role from API (`is_manager` / `role`) → manager or employee shell (`role_home.dart`)
5. Tasks via `/api/tasks/`: managers full CRUD; employees list only their assignee-scoped tasks and may `PATCH` **status** only
6. Other live endpoints: `/api/users/` (managers), `/api/tasks/{id}/comments/`

API base URL comes from `--dart-define=API_BASE_URL=…` (default `http://localhost:8000/api/`).

## Environment

| Variable | Where | Purpose |
|---|---|---|
| `DJANGO_SECRET_KEY` | Project root `.env` (see `.env.example`) | Django secret; required at startup |
| `API_BASE_URL` | Flutter `--dart-define` | API root for non-web / LAN devices |

Copy `.env.example` → `.env` and set a real secret before running Django. Do not commit `.env`.

## How to run

### Backend (Django)

```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

On macOS/Linux:

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

Then:

```powershell
# Ensure .env exists with DJANGO_SECRET_KEY=...
python manage.py migrate
python manage.py createsuperuser   # optional; also set profile.is_manager for app managers
python manage.py runserver 0.0.0.0:8000
```

### Frontend (Flutter)

```powershell
cd frontend
flutter pub get

# Web (CSRF trusted origin uses port 8080)
flutter run -d chrome --web-port=8080

# Phone / wireless — point at this machine's LAN IP
flutter run -d <device> --dart-define=API_BASE_URL=http://192.168.0.102:8000/api/
```


