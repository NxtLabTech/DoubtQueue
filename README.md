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
- **"Failed to establish connection with the application instance in Chrome":** Flutter attempts to communicate with Chrome through a debugging connection. When Flutter cannot establish that connection with Chrome's debugging port, this error or a related `SocketException` may occur. A practical workaround is to run Flutter using the `web-server` device instead of the Chrome device:

  ```bash
  flutter run -d web-server --web-port 8081
  ```

  Then manually open:

  http://localhost:8081

  in your browser. Note that this is a workaround for the Chrome debugging connection problem, not a claim that the underlying Chrome issue has been permanently fixed.
- **"Address already in use":** The backend is attempting to listen on port 8000, but another process is already using that port. You can resolve this with one of two solutions:
  - **Solution A:** Identify and stop the process currently using port 8000, provided it is safe to stop. Do not terminate unknown or system processes blindly.
  - **Solution B:** Run the backend on another available port:

    ```bash
    php -S localhost:8001 -t public public/index.php
    ```

    Flutter must also be configured to use the new backend URL. Pass the following flag:

    ```bash
    --dart-define=API_BASE_URL=http://localhost:8001
    ```

    For example, combining this flag with the repository's Flutter run command:

    ```bash
    flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8001
    ```

    Both the backend port and Flutter `API_BASE_URL` must match so that Flutter sends requests to the correct port where the backend is listening.
- **Real phone cannot connect ("Could not reach the server. Check that the backend is running."):** When running the app on a physical device, you may see "Could not reach the server. Check that the backend is running." Likely causes include:
  - The phone is attempting to access `localhost`, which refers to the phone itself, not the development computer.
  - The phone and development computer may not be connected to the same local network.
  - The PHP development server may only be listening on the computer's loopback interface (`localhost` / `127.0.0.1`).
  - The computer's firewall may be blocking incoming connections.

  How to fix this:
  1. Find the development computer's local IPv4 address (for example, using `ipconfig` on Windows or `ifconfig` / `ip a` on macOS and Linux).
  2. Connect the phone and development computer to the same Wi-Fi/local network.
  3. Start PHP so it listens on all network interfaces:

     ```bash
     php -S 0.0.0.0:8000 -t public public/index.php
     ```

  4. The Flutter application must use the computer's local IP address rather than `localhost`. Provide the API base URL flag:

     ```bash
     --dart-define=API_BASE_URL=http://192.168.1.10:8000
     ```

     For example:

     ```bash
     flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
     ```

     Note: `192.168.1.10` is only an illustrative example and must be replaced with your computer's actual local IPv4 address.
  5. The firewall may need to allow incoming connections on port 8000 for the PHP process or the development environment. Do not disable the firewall entirely.
  6. Network isolation, guest Wi-Fi, VPNs, or router settings may prevent devices from communicating even when connected to the same Wi-Fi network.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT. See [LICENSE](LICENSE).
