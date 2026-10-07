# DoubtQueue API reference

DoubtQueue is a REST API for running doubt sessions. A mentor opens a session, students add doubts to the queue, and the mentor takes the doubts one at a time.

This page describes every endpoint, with a `curl` example, a sample response, and the errors you can get.

## Before you begin

Start the server from the `backend/` folder:

```bash
composer start
```

The API is then available at `http://localhost:8000`. All examples on this page use that address.

Some examples change data, so the response you get depends on the requests you sent before. To get the results shown on this page, follow [Run the examples in order](#run-the-examples-in-order). Ids and timestamps also differ from the samples on this page. To start again with the sample data, stop the server and delete `backend/data/doubtqueue.sqlite`. Start the server again. It creates the database and the sample data on the first request.

## Run the examples in order

The examples on this page are grouped by endpoint, not in the order you should run them. To get the results shown here, start with a fresh database and run the examples in the order below.

First, run the examples that only read data. They change nothing, so you can run them in any order. These are all the examples in these sections:

- List sessions
- Get a session
- List the queue
- Get session statistics
- Get a doubt

Then run the examples that change data, in this order:

| Order | Section | Example to run |
|-------|---------|----------------|
| 1 | Create a session | The example request, then the example with an empty body |
| 2 | Add a doubt to a session | The example with an empty body |
| 3 | Take the next doubt | The empty queue example, which uses session 3 |
| 4 | Add a doubt to a session | The example request, then the example for a closed session |
| 5 | Take the next doubt | The example request. It returns doubt 1. |
| 6 | Mark a doubt as solved | All three examples |
| 7 | Take the next doubt | The example request again. It returns doubt 2, which the skipped examples need. |
| 8 | Mark a doubt as skipped | All three examples |
| 9 | Close a session | All three examples |
| 10 | Take the next doubt | The closed sessions example. It returns doubt 3. |

If an example gives a different result, reset the database and start again.

## Conventions

### Responses

All responses use the `application/json` content type.

### Errors

An error response has two fields: `status` and `message`.

```json
{"status":404,"message":"Session with id 9999 not found"}
```

The API returns these error statuses:

| Status | Name | Meaning |
|--------|------|---------|
| 400 | Bad Request | A field is missing, too long, or not valid. Also returned when you finish a doubt that is not in progress. |
| 404 | Not Found | The session or doubt does not exist, or the session has no waiting doubts to take. |
| 409 | Conflict | You tried to add a doubt to a closed session. |

### Dates

All timestamps are in UTC and use the format `Y-m-d H:i:s`, for example `2026-10-06 19:21:24`.

The timestamps on this page are examples. The sample data sets its timestamps when the database is first created, so your values will differ.

### Doubt status

A doubt has one of these statuses:

| Status | Meaning |
|--------|---------|
| `WAITING` | The doubt is in the queue. |
| `IN_PROGRESS` | The mentor took the doubt with the next endpoint. |
| `SOLVED` | The mentor marked the doubt as solved. |
| `SKIPPED` | The mentor marked the doubt as skipped. |

### Position

The `position` field appears on a doubt that you get by id, add, take, solved, or skipped. The queue list (`GET /api/sessions/{id}/queue`) does not include `position`.

- For a waiting doubt, `position` is the place of the doubt in the queue, starting at 1. Only waiting doubts count, so the position moves up when a doubt ahead of it is taken.
- For a doubt that is not waiting, `position` is `null`. This applies to `IN_PROGRESS`, `SOLVED`, and `SKIPPED` doubts.

### Cross-origin requests (CORS)

The API allows requests from any origin and accepts the `GET`, `POST`, `PATCH`, and `OPTIONS` methods.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/sessions` | List sessions. |
| POST | `/api/sessions` | Create a session. |
| GET | `/api/sessions/{id}` | Get one session. |
| GET | `/api/sessions/{id}/queue` | List the waiting doubts in a session. |
| GET | `/api/sessions/{id}/stats` | Count doubts by status. |
| POST | `/api/sessions/{id}/doubts` | Add a doubt to a session. |
| POST | `/api/sessions/{id}/next` | Take the next waiting doubt. |
| PATCH | `/api/sessions/{id}/close` | Close a session. |
| GET | `/api/doubts/{id}` | Get one doubt. |
| PATCH | `/api/doubts/{id}/solved` | Mark a doubt as solved. |
| PATCH | `/api/doubts/{id}/skipped` | Mark a doubt as skipped. |

## List sessions

```
GET /api/sessions
```

Returns an array of all sessions.

### Query parameters

| Name | Required | Description |
|------|----------|-------------|
| `status` | No | Return only sessions with this status. Must be `OPEN` or `CLOSED`. |

### Example request

```bash
curl -i http://localhost:8000/api/sessions
```

### Example response

Status: `200 OK`

```json
[
    {
        "id": 1,
        "title": "PHP Basics Doubt Session",
        "mentor_name": "Priya",
        "status": "OPEN",
        "created_at": "2026-10-06 19:21:24",
        "closed_at": null,
        "waiting_count": 5
    },
    {
        "id": 2,
        "title": "Flutter Doubt Session",
        "mentor_name": "Arjun",
        "status": "CLOSED",
        "created_at": "2026-10-05 20:21:24",
        "closed_at": "2026-10-05 21:21:24",
        "waiting_count": 0
    }
]
```

### Session fields

| Field | Description |
|-------|-------------|
| `id` | The session ID. |
| `title` | The session title. |
| `mentor_name` | The name of the mentor. |
| `status` | `OPEN` or `CLOSED`. |
| `created_at` | When the session was created. |
| `closed_at` | When the session was closed, or `null` if it is open. |
| `waiting_count` | The number of doubts that are waiting. |

### Filter by status

```bash
curl -i "http://localhost:8000/api/sessions?status=CLOSED"
```

Status: `200 OK`. The response contains only closed sessions.

```json
[
    {
        "id": 2,
        "title": "Flutter Doubt Session",
        "mentor_name": "Arjun",
        "status": "CLOSED",
        "created_at": "2026-10-05 20:21:24",
        "closed_at": "2026-10-05 21:21:24",
        "waiting_count": 0
    }
]
```

### Errors

| Status | When | Example message |
|--------|------|-----------------|
| 400 | `status` is not `OPEN` or `CLOSED`. | `status must be OPEN or CLOSED` |

```bash
curl -i "http://localhost:8000/api/sessions?status=BANANA"
```

```json
{"status":400,"message":"status must be OPEN or CLOSED"}
```

## Create a session

```
POST /api/sessions
```

Creates an open session.

### Request body

| Field | Type | Required | Limit |
|-------|------|----------|-------|
| `title` | string | Yes | 255 characters |
| `mentor_name` | string | Yes | 255 characters |

### Example request

```bash
curl -i -X POST http://localhost:8000/api/sessions \
  -H "Content-Type: application/json" \
  -d '{"title":"Docs Test Session","mentor_name":"Rhea"}'
```

### Example response

Status: `201 Created`

```json
{
    "id": 3,
    "title": "Docs Test Session",
    "mentor_name": "Rhea",
    "status": "OPEN",
    "created_at": "2026-10-06 21:03:42",
    "closed_at": null,
    "waiting_count": 0
}
```

### Errors

| Status | When | Example message |
|--------|------|-----------------|
| 400 | `title` is missing. | `title is required` |
| 400 | `mentor_name` is missing. | `mentor_name is required` |
| 400 | `title` is longer than the limit. | `title must be 255 characters or fewer` |
| 400 | `mentor_name` is longer than the limit. | `mentor_name must be 255 characters or fewer` |

If both fields are missing, the response names only `title`:

```bash
curl -i -X POST http://localhost:8000/api/sessions \
  -H "Content-Type: application/json" \
  -d '{}'
```

```json
{"status":400,"message":"title is required"}
```

A value of exactly 255 characters is accepted. A value of 256 characters is rejected.

## Get a session

```
GET /api/sessions/{id}
```

Returns one session. The response has the same fields as an item in the list.

### Example request

```bash
curl -i http://localhost:8000/api/sessions/1
```

### Example response

Status: `200 OK`

```json
{
    "id": 1,
    "title": "PHP Basics Doubt Session",
    "mentor_name": "Priya",
    "status": "OPEN",
    "created_at": "2026-10-06 19:21:24",
    "closed_at": null,
    "waiting_count": 5
}
```

### Errors

| Status | When | Example message |
|--------|------|-----------------|
| 404 | The session does not exist. | `Session with id 9999 not found` |

```bash
curl -i http://localhost:8000/api/sessions/9999
```

```json
{"status":404,"message":"Session with id 9999 not found"}
```

## List the queue

```
GET /api/sessions/{id}/queue
```

Returns the waiting doubts in a session as an array. The oldest doubt is first. A doubt leaves the list when it is taken.

### Example request

```bash
curl -i http://localhost:8000/api/sessions/1/queue
```

### Example response

Status: `200 OK`

The sample session has five waiting doubts. This example shows the first two.

```json
[
    {
        "id": 1,
        "session_id": 1,
        "student_name": "Asha Rao",
        "student_email": "asha@example.com",
        "topic": "Arrays",
        "question": "How do I loop over an associative array?",
        "status": "WAITING",
        "created_at": "2026-10-06 19:51:24",
        "started_at": null,
        "finished_at": null
    },
    {
        "id": 2,
        "session_id": 1,
        "student_name": "Ben Thomas",
        "student_email": "ben@example.com",
        "topic": "Functions",
        "question": "What is the difference between return and echo?",
        "status": "WAITING",
        "created_at": "2026-10-06 19:52:24",
        "started_at": null,
        "finished_at": null
    }
]
```

### Doubt fields

| Field | Description |
|-------|-------------|
| `id` | The doubt ID. |
| `session_id` | The ID of the session the doubt belongs to. |
| `student_name` | The name of the student. |
| `student_email` | The email address of the student. |
| `topic` | The topic of the doubt. |
| `question` | The question. |
| `status` | The status of the doubt. See [Doubt status](#doubt-status). |
| `created_at` | When the doubt was created. |
| `started_at` | When the doubt was taken, or `null`. |
| `finished_at` | When the doubt was solved or skipped, or `null`. |

Items in the queue list do not include `position`.

### Errors

| Status | When | Example message |
|--------|------|-----------------|
| 404 | The session does not exist. | `Session with id 9999 not found` |

```bash
curl -i http://localhost:8000/api/sessions/9999/queue
```

```json
{"status":404,"message":"Session with id 9999 not found"}
```

## Get session statistics

```
GET /api/sessions/{id}/stats
```

Returns the number of doubts in each status.

### Example request

```bash
curl -i http://localhost:8000/api/sessions/1/stats
```

### Example response

Status: `200 OK`

```json
{
    "WAITING": 5,
    "IN_PROGRESS": 0,
    "SOLVED": 0,
    "SKIPPED": 0
}
```

The counts change as doubts move through the queue. After the mentor solved one doubt, skipped one, and took one, the same request returned:

```json
{
    "WAITING": 3,
    "IN_PROGRESS": 1,
    "SOLVED": 1,
    "SKIPPED": 1
}
```

### Errors

| Status | When | Example message |
|--------|------|-----------------|
| 404 | The session does not exist. | `Session with id 9999 not found` |

```bash
curl -i http://localhost:8000/api/sessions/9999/stats
```

```json
{"status":404,"message":"Session with id 9999 not found"}
```

## Add a doubt to a session

```
POST /api/sessions/{id}/doubts
```

Adds a doubt to the end of the queue of an open session.

### Request body

| Field | Type | Required | Limit |
|-------|------|----------|-------|
| `student_name` | string | Yes | 255 characters |
| `student_email` | string | Yes | 255 characters. Must be a valid email address. |
| `topic` | string | Yes | 255 characters |
| `question` | string | Yes | 2000 characters |

For `student_email`, a valid address of 254 characters was accepted, and an address of 255 characters was rejected as not valid. Use an address of 254 characters or fewer.

### Example request

```bash
curl -i -X POST http://localhost:8000/api/sessions/1/doubts \
  -H "Content-Type: application/json" \
  -d '{"student_name":"Rhea Test","student_email":"rhea@example.com","topic":"Docs","question":"How do I read the API docs?"}'
```

### Example response

Status: `201 Created`

```json
{
    "id": 10,
    "session_id": 1,
    "student_name": "Rhea Test",
    "student_email": "rhea@example.com",
    "topic": "Docs",
    "question": "How do I read the API docs?",
    "status": "WAITING",
    "created_at": "2026-10-06 21:13:13",
    "started_at": null,
    "finished_at": null,
    "position": 6
}
```

The new doubt has `position` 6 because five doubts were already waiting. The `id` is an example. The database assigns it.

### Errors

| Status | When | Example message |
|--------|------|-----------------|
| 400 | `student_name` is missing. | `student_name is required` |
| 400 | `student_email` is missing. | `student_email is required` |
| 400 | `topic` is missing. | `topic is required` |
| 400 | `question` is missing. | `question is required` |
| 400 | `student_name` is longer than the limit. | `student_name must be 255 characters or fewer` |
| 400 | `student_email` is longer than the limit. | `student_email must be 255 characters or fewer` |
| 400 | `topic` is longer than the limit. | `topic must be 255 characters or fewer` |
| 400 | `question` is longer than the limit. | `question must be 2000 characters or fewer` |
| 400 | `student_email` is not a valid email address. | `student_email must be a valid email address` |
| 404 | The session does not exist. | `Session with id 9999 not found` |
| 409 | The session is closed. | `Session with id 2 is closed` |

If every field is missing, the response names only `student_email`:

```bash
curl -i -X POST http://localhost:8000/api/sessions/1/doubts \
  -H "Content-Type: application/json" \
  -d '{}'
```

```json
{"status":400,"message":"student_email is required"}
```

Adding a doubt to a closed session:

```bash
curl -i -X POST http://localhost:8000/api/sessions/2/doubts \
  -H "Content-Type: application/json" \
  -d '{"student_name":"Rhea Test","student_email":"rhea@example.com","topic":"Docs","question":"How do I read the API docs?"}'
```

```json
{"status":409,"message":"Session with id 2 is closed"}
```

A `question` of exactly 2000 characters is accepted. A `question` of 2001 characters is rejected.

## Take the next doubt

```
POST /api/sessions/{id}/next
```

Takes the next waiting doubt in the session and sets its status to `IN_PROGRESS`. The request has no body.

Doubts come back in queue order, oldest first.

### Example request

```bash
curl -i -X POST http://localhost:8000/api/sessions/1/next
```

### Example response

Status: `200 OK`

The response is the doubt. Its `status` is `IN_PROGRESS`, `started_at` is set, and `position` is `null`.

```json
{
    "id": 1,
    "session_id": 1,
    "student_name": "Asha Rao",
    "student_email": "asha@example.com",
    "topic": "Arrays",
    "question": "How do I loop over an associative array?",
    "status": "IN_PROGRESS",
    "created_at": "2026-10-06 19:51:24",
    "started_at": "2026-10-07 00:25:18",
    "finished_at": null,
    "position": null
}
```

### Closed sessions

You can take a doubt from a closed session. The request succeeds if a doubt is still waiting. This is different from adding a doubt, which returns 409 for a closed session.

Run the request below after you close session 1 (see [Close a session](#close-a-session)). It returns the next waiting doubt, doubt 3, with status `200 OK`:

```bash
curl -i -X POST http://localhost:8000/api/sessions/1/next
```

```json
{
    "id": 3,
    "session_id": 1,
    "student_name": "Chitra Nair",
    "student_email": "chitra@example.com",
    "topic": "PDO",
    "question": "Why should I use prepared statements?",
    "status": "IN_PROGRESS",
    "created_at": "2026-10-06 19:53:24",
    "started_at": "2026-10-07 01:02:04",
    "finished_at": null,
    "position": null
}
```

### Errors

| Status | When | Example message |
|--------|------|-----------------|
| 404 | The session does not exist. | `Session with id 9999 not found` |
| 404 | The session has no waiting doubts. | `Session with id 3 has no waiting doubts` |

```bash
curl -i -X POST http://localhost:8000/api/sessions/3/next
```

```json
{"status":404,"message":"Session with id 3 has no waiting doubts"}
```

An empty queue returns 404, not an empty `200` response.

## Close a session

```
PATCH /api/sessions/{id}/close
```

Sets the session status to `CLOSED` and sets `closed_at`. The request has no body.

### Example request

```bash
curl -i -X PATCH http://localhost:8000/api/sessions/1/close
```

### Example response

Status: `200 OK`

```json
{
    "id": 1,
    "title": "PHP Basics Doubt Session",
    "mentor_name": "Priya",
    "status": "CLOSED",
    "created_at": "2026-10-06 19:21:24",
    "closed_at": "2026-10-07 00:45:03",
    "waiting_count": 4
}
```

### What happens to waiting doubts

Closing a session does not change its waiting doubts. After the close above, the session still reported `waiting_count` 4, and the waiting doubts kept the status `WAITING`.

### Close a session that is already closed

Closing a closed session is not an error. The request returns `200 OK` and the same session. The `closed_at` value does not change.

```bash
curl -i -X PATCH http://localhost:8000/api/sessions/1/close
```

```json
{
    "id": 1,
    "title": "PHP Basics Doubt Session",
    "mentor_name": "Priya",
    "status": "CLOSED",
    "created_at": "2026-10-06 19:21:24",
    "closed_at": "2026-10-07 00:45:03",
    "waiting_count": 4
}
```

### Errors

| Status | When | Example message |
|--------|------|-----------------|
| 404 | The session does not exist. | `Session with id 9999 not found` |

```bash
curl -i -X PATCH http://localhost:8000/api/sessions/9999/close
```

```json
{"status":404,"message":"Session with id 9999 not found"}
```

## Get a doubt

```
GET /api/doubts/{id}
```

Returns one doubt. The response has the doubt fields plus `position`.

### Example request

```bash
curl -i http://localhost:8000/api/doubts/1
```

### Example response

Status: `200 OK`

```json
{
    "id": 1,
    "session_id": 1,
    "student_name": "Asha Rao",
    "student_email": "asha@example.com",
    "topic": "Arrays",
    "question": "How do I loop over an associative array?",
    "status": "WAITING",
    "created_at": "2026-10-06 19:51:24",
    "started_at": null,
    "finished_at": null,
    "position": 1
}
```

After the mentor takes the doubt, the same request returns `status` `IN_PROGRESS`, a `started_at` value, and `position` `null`.

### Errors

| Status | When | Example message |
|--------|------|-----------------|
| 404 | The doubt does not exist. | `Doubt with id 9999 not found` |

```bash
curl -i http://localhost:8000/api/doubts/9999
```

```json
{"status":404,"message":"Doubt with id 9999 not found"}
```

## Mark a doubt as solved

```
PATCH /api/doubts/{id}/solved
```

Sets the status of a doubt to `SOLVED` and sets `finished_at`. The doubt must be `IN_PROGRESS`. The request has no body.

### Example request

```bash
curl -i -X PATCH http://localhost:8000/api/doubts/1/solved
```

### Example response

Status: `200 OK`

```json
{
    "id": 1,
    "session_id": 1,
    "student_name": "Asha Rao",
    "student_email": "asha@example.com",
    "topic": "Arrays",
    "question": "How do I loop over an associative array?",
    "status": "SOLVED",
    "created_at": "2026-10-06 19:51:24",
    "started_at": "2026-10-07 00:25:18",
    "finished_at": "2026-10-07 00:30:35",
    "position": null
}
```

### Errors

| Status | When | Example message |
|--------|------|-----------------|
| 400 | The doubt is not `IN_PROGRESS`. | `Only a doubt that is in progress can be finished` |
| 404 | The doubt does not exist. | `Doubt with id 9999 not found` |

The 400 error applies to a doubt that is already solved and to a doubt that is still waiting:

```bash
curl -i -X PATCH http://localhost:8000/api/doubts/1/solved
```

```json
{"status":400,"message":"Only a doubt that is in progress can be finished"}
```

```bash
curl -i -X PATCH http://localhost:8000/api/doubts/9999/solved
```

```json
{"status":404,"message":"Doubt with id 9999 not found"}
```

## Mark a doubt as skipped

```
PATCH /api/doubts/{id}/skipped
```

Sets the status of a doubt to `SKIPPED` and sets `finished_at`. The doubt must be `IN_PROGRESS`. The request has no body.

### Example request

```bash
curl -i -X PATCH http://localhost:8000/api/doubts/2/skipped
```

### Example response

Status: `200 OK`

```json
{
    "id": 2,
    "session_id": 1,
    "student_name": "Ben Thomas",
    "student_email": "ben@example.com",
    "topic": "Functions",
    "question": "What is the difference between return and echo?",
    "status": "SKIPPED",
    "created_at": "2026-10-06 19:52:24",
    "started_at": "2026-10-07 00:35:16",
    "finished_at": "2026-10-07 00:37:35",
    "position": null
}
```

### Errors

| Status | When | Example message |
|--------|------|-----------------|
| 400 | The doubt is not `IN_PROGRESS`. | `Only a doubt that is in progress can be finished` |
| 404 | The doubt does not exist. | `Doubt with id 9999 not found` |

The 400 error uses the same message as the solved endpoint. It applies to a doubt that is already skipped and to a doubt that is still waiting.

```bash
curl -i -X PATCH http://localhost:8000/api/doubts/2/skipped
```

```json
{"status":400,"message":"Only a doubt that is in progress can be finished"}
```

```bash
curl -i -X PATCH http://localhost:8000/api/doubts/9999/skipped
```

```json
{"status":404,"message":"Doubt with id 9999 not found"}
```
