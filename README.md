# DoubtQueue

DoubtQueue is a small app for mentor office hours. A mentor opens a session, students join the queue with their question, and the mentor takes the students one by one.

Students can see their position in the queue and whether their doubt was solved or skipped. There is no login.

## Technology

- Backend: plain PHP 8.2+, PDO, SQLite (default), MySQL (optional), Composer, PHPUnit
- App: Flutter (stable), Dart 3, Material 3, `http` package

## Requirements

- PHP 8.2 or newer with the `pdo_sqlite`, `mbstring`, `openssl`, `xml`, `dom` and `zip` extensions
- Composer
- Flutter stable SDK
- Chrome, to run the app in the browser

## Backend setup

```
cd backend
composer install
composer start
```

The API runs at `http://localhost:8000`. On the first request it creates the SQLite database at `backend/data/doubtqueue.sqlite` and adds sample data. The database file is ignored by Git.

## Flutter setup

Start the backend first, then:

```
cd app
flutter pub get
flutter run -d chrome
```

### Android emulator

The emulator reaches your computer at `10.0.2.2`:

```
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Plain HTTP is allowed only in the Android debug manifest (`app/android/app/src/debug/AndroidManifest.xml`). Release builds do not allow it.

### Real phone

Use the local IP address of your computer, for example:

```
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000
```

The phone and the computer must be on the same network. Start the backend so it accepts outside connections:

```
php -S 0.0.0.0:8000 -t public public/index.php
```

## Running tests

```
cd backend
composer test

cd ../app
flutter analyze
flutter test
```

## API endpoints

| Method | Path | Description |
| --- | --- | --- |
| POST | `/api/sessions` | Create a session (`title`, `mentor_name`) |
| GET | `/api/sessions` | List sessions, optional `?status=OPEN` |
| GET | `/api/sessions/{id}` | Get one session |
| PATCH | `/api/sessions/{id}/close` | Close a session |
| POST | `/api/sessions/{id}/doubts` | Join a session (`student_name`, `student_email`, `topic`, `question`) |
| GET | `/api/sessions/{id}/queue` | Waiting doubts, oldest first |
| POST | `/api/sessions/{id}/next` | Take the oldest waiting doubt |
| GET | `/api/sessions/{id}/stats` | Doubt counts by status |
| GET | `/api/doubts/{id}` | Get one doubt, with `position` while it is waiting |
| PATCH | `/api/doubts/{id}/solved` | Mark an in-progress doubt as solved |
| PATCH | `/api/doubts/{id}/skipped` | Mark an in-progress doubt as skipped |

Errors are returned as JSON:

```
{
  "status": 404,
  "message": "Session with id 9 not found"
}
```

## MySQL (optional)

SQLite is the default. MySQL can be used by setting environment variables before starting the backend:

```
DB_DRIVER=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=doubtqueue
DB_USERNAME=root
DB_PASSWORD=root
```

Create the `doubtqueue` database first. The tables are created on the first request from `backend/database/schema-mysql.sql`. Enable the `pdo_mysql` PHP extension.

The defaults above are for local development only. Use your own credentials and never commit them.

MySQL support is optional and has not been tested locally. The tests use SQLite only.

## Troubleshooting

- **The app shows "Could not reach the server":** check that the backend is running and that `API_BASE_URL` points to it.
- **Android emulator cannot connect:** use `http://10.0.2.2:8000`, not `localhost`.
- **`composer install` says the zip extension is missing:** enable `extension=zip` in `php.ini`.
- **"could not find driver":** enable `extension=pdo_sqlite` in `php.ini`.
- **Sample data is wrong:** stop the backend and delete `backend/data/doubtqueue.sqlite`. It is created again on the next start.
- **"Failed to establish connection with the application instance in Chrome":**
  - **Cause:** Flutter attempts to communicate with Chrome through a debugging port. This error (or a related `SocketException`) occurs when Flutter cannot establish that debugging connection.
  - **Solution:** Run Flutter using the headless `web-server` device instead of the default Chrome device:

    ```bash
    cd app
    flutter run -d web-server --web-port 8081
    ```

    Then manually open `http://localhost:8081` in your browser. *(Note: This is a practical workaround for the Chrome debugging connection problem, not a permanent fix for underlying Chrome issues.)*
  - **Verification:** Open `http://localhost:8081` in your browser; the DoubtQueue web interface should load and function normally.
- **"Address already in use":**
  - **Cause:** The PHP backend server is attempting to listen on port 8000, but another process is already occupying that port.
  - **Solution:**
    - **Solution A (Stop the existing process):** Check which process is using port 8000:
      - Windows: `netstat -ano | findstr :8000`
      - macOS / Linux: `lsof -i :8000`
      If the process is an orphaned PHP server or a service you can safely stop, terminate it. Do not terminate unknown or system processes blindly.
    - **Solution B (Run on another port, e.g. 8001):** Start the backend on an available port:

      ```bash
      cd backend
      php -S localhost:8001 -t public public/index.php
      ```

      Then configure Flutter to use the new backend port by passing `--dart-define=API_BASE_URL=http://localhost:8001`:

      ```bash
      cd app
      flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8001
      ```

      Both the backend port and Flutter `API_BASE_URL` must match so API requests reach the running backend.
  - **Verification:** Open `http://localhost:8001/api/sessions` in your browser to verify the backend returns a JSON response, and confirm the Flutter app loads sessions without showing "Could not reach the server".
- **Real phone cannot connect ("Could not reach the server. Check that the backend is running."):**
  - **Cause:**
    - The phone attempts to access `localhost`, which refers to the phone itself rather than your development computer.
    - The phone and development computer are not connected to the same local network.
    - The PHP development server is only listening on the computer's loopback interface (`localhost` / `127.0.0.1`).
    - The computer's firewall blocks incoming connections on port 8000.
  - **Solution:**
    1. **Find your computer's local IPv4 address:**
       - Windows: run `ipconfig` (find the IPv4 address under your active Wi-Fi or Ethernet adapter).
       - macOS / Linux: run `ip a` or `ifconfig`.
    2. **Connect to the same network:** Ensure your physical phone and development computer are on the same Wi-Fi/local network. Note that guest Wi-Fi modes, router client isolation (AP isolation), or active VPNs can block local device-to-device communication.
    3. **Start PHP on all network interfaces:**

       ```bash
       cd backend
       php -S 0.0.0.0:8000 -t public public/index.php
       ```

    4. **Run Flutter using your computer's local IPv4 address:**

       ```bash
       cd app
       flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
       ```

       *(Note: `192.168.1.10` is only an illustrative example. Replace it with your computer's actual local IPv4 address found in step 1.)*
    5. **Allow port 8000 in your firewall:** If connections are blocked, allow incoming TCP traffic on port 8000 for PHP in your computer's firewall settings. Do not disable your firewall entirely.
  - **Security note:** `0.0.0.0` binds PHP to all network interfaces on your machine. Use this only on trusted private development networks (such as your home or private office Wi-Fi), never on untrusted public Wi-Fi networks. The PHP development server is intended strictly for local development and must not be exposed to the public internet or used in production.
  - **Verification:** Before building the mobile app, open `http://<your-computer-ip>:8000/api/sessions` in your phone's web browser. If you receive a JSON response, network reachability is verified. The Flutter app will then connect and load sessions properly.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT. See [LICENSE](LICENSE).
