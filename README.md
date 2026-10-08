# DoubtQueue

DoubtQueue is a small app for mentor office hours. A mentor opens a session, students join the queue with their question, and the mentor takes the students one by one.

Students can see their position in the queue and whether their doubt was solved or skipped. There is no login.

## Features

There is no login. Anyone can open the app as a student or a mentor.

**Students**

- Search sessions by session or mentor name.
- Filter sessions by Open, Closed or All, and sort them by Newest or Most waiting.
- Join a session queue with a name, email, topic and question.
- See your position in the queue and how many students are ahead of you.
- The doubt screen refreshes every 10 seconds, so you see when it is your turn and when your doubt is solved or skipped.

**Mentors**

- Start a session with a title and a mentor name, or select an open session.
- See statistics for waiting, in progress, solved and skipped doubts.
- Take the next student, then mark the doubt as solved or skip it.
- Confirm before you skip a doubt or close a session.
- Close a session so no more students can join.

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

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT. See [LICENSE](LICENSE).
