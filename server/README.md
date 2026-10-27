# eBuCard server

[Dart Frog](https://dart-frog.dev) API server with PostgreSQL. It provides accounts (email/password, Sign in with Apple, Google), sync of cards and Inbox, and card images. Design and decisions: `../docs/DESIGN.md` §6–§8.

## Run locally

```sh
docker compose up -d                       # PostgreSQL on localhost:5432 (+ ebucard_test)
dart pub get
dart pub global activate dart_frog_cli
DB_PASSWORD=ebucard_dev JWT_SECRET=dev-secret-at-least-32-characters-long dart_frog dev
curl localhost:8080/health
```

Without SMTP settings, emails (confirmation, password reset) are **printed to the server log**. Without storage settings, images are kept **in memory**. Both are fine for development only.

## Tests

```sh
docker compose up -d   # once; the tests wipe the ebucard_test database
dart test
```

Tests that need the database are skipped if it isn't reachable. To use another database, set `TEST_DB_HOST`, `TEST_DB_PORT`, `TEST_DB_NAME`, `TEST_DB_USER` and `TEST_DB_PASSWORD`.

## Settings (environment variables)

| Variable | Required | Meaning |
|---|---|---|
| `JWT_SECRET` | yes | Secret for signing access tokens, at least 32 characters. Keep it in Secret Manager |
| `PUBLIC_BASE_URL` | – | Public address of this server, used in email links and image URLs. Default `https://api.example.com` (placeholder until the domain is chosen) |
| `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` | – | PostgreSQL. Defaults: `localhost`, `5432`, `ebucard`, `ebucard`, empty |
| `DB_SOCKET` | – | Unix socket instead of TCP, e.g. `/cloudsql/PROJECT:REGION:INSTANCE/.s.PGSQL.5432` on Cloud Run |
| `DB_SSL` | – | `true` to require TLS on TCP connections |
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_FROM`, `SMTP_SSL` | – | Outgoing email. Port 587 uses STARTTLS; set `SMTP_SSL=true` for port 465. `SMTP_FROM` like `eBuCard <no-reply@example.com>`. Unset: log only |
| `S3_BUCKET`, `S3_ACCESS_KEY`, `S3_SECRET_KEY` | – | Image bucket and HMAC keys. Unset: memory only |
| `S3_ENDPOINT`, `S3_REGION`, `S3_PATH_STYLE` | – | Defaults `https://storage.googleapis.com`, `auto`, `true` (Google Cloud Storage). Other S3-compatible services work too |
| `APPLE_CLIENT_IDS` | – | Comma-separated accepted audiences for Sign in with Apple (the iOS bundle id `com.etherious.ebucard`, plus a Services ID if used). Unset: Apple sign-in answers `provider_not_configured` |
| `GOOGLE_CLIENT_IDS` | – | Comma-separated Google OAuth client IDs (iOS, Android and web clients). Unset: Google sign-in is off |
| `BREACH_CHECK` | – | `false` turns off the Have I Been Pwned check for new passwords (default on) |
| `HOST`, `PORT` | – | Listen address and port. The container sets `HOST=0.0.0.0`; Cloud Run sets `PORT` |

## Deploy to Google Cloud Run

Build the image from the **repository root**, because the server uses `packages/ebucard_models`:

```sh
docker build -f server/Dockerfile -t REGION-docker.pkg.dev/PROJECT/ebucard/server .
docker push REGION-docker.pkg.dev/PROJECT/ebucard/server
```

One-time setup in the Google Cloud project:

1. **Cloud SQL for PostgreSQL** instance and an `ebucard` database and user.
2. **Cloud Storage** bucket for images (not public; the server serves images itself). Create **HMAC keys** for a service account with access to the bucket (Cloud Storage → Settings → Interoperability).
3. **Secret Manager** secrets for `JWT_SECRET`, `DB_PASSWORD`, `SMTP_PASSWORD` and `S3_SECRET_KEY`.
4. Deploy:

```sh
gcloud run deploy ebucard-server \
  --image REGION-docker.pkg.dev/PROJECT/ebucard/server \
  --region REGION --allow-unauthenticated \
  --add-cloudsql-instances PROJECT:REGION:INSTANCE \
  --set-env-vars DB_SOCKET=/cloudsql/PROJECT:REGION:INSTANCE/.s.PGSQL.5432,DB_USER=ebucard,DB_NAME=ebucard \
  --set-env-vars PUBLIC_BASE_URL=https://api.example.com,S3_BUCKET=BUCKET,S3_ACCESS_KEY=GOOG1... \
  --set-env-vars SMTP_HOST=...,SMTP_PORT=587,SMTP_USERNAME=...,SMTP_FROM="eBuCard <no-reply@example.com>" \
  --set-env-vars APPLE_CLIENT_IDS=com.etherious.ebucard,GOOGLE_CLIENT_IDS=... \
  --set-secrets JWT_SECRET=jwt-secret:latest,DB_PASSWORD=db-password:latest,SMTP_PASSWORD=smtp-password:latest,S3_SECRET_KEY=s3-secret:latest
```

The server applies database migrations at start-up; an advisory lock keeps several starting instances from migrating at once. It also erases accounts whose 30-day deletion period has ended, at start-up and then daily.

Rate limits (20 sign-in/registration/email requests per address per 10 minutes) are counted **per instance**. With many instances the effective limit is higher; a shared store can replace this later if needed.

## Endpoints

| Route | Purpose |
|---|---|
| `GET /health` | Liveness check |
| `POST /v1/auth/register` | `{email, password}` → account and tokens; emails a confirmation link |
| `POST /v1/auth/login` | `{email, password}` → tokens |
| `POST /v1/auth/apple`, `POST /v1/auth/google` | `{identityToken}` → tokens |
| `POST /v1/auth/refresh` | `{refreshToken}` → new tokens (the old refresh token stops working) |
| `POST /v1/auth/logout` | `{refreshToken}` → ends that session |
| `POST /v1/auth/resend_verification` | Signed in → sends the confirmation email again |
| `POST /v1/auth/password_reset` | `{email}` → emails a reset link (always 202) |
| `GET /email/verify?token=` | Page opened from the confirmation email |
| `GET/POST /password/reset?token=` | Page opened from the reset email: choose a new password |
| `GET /v1/account`, `DELETE /v1/account` | Account details; request deletion (30-day grace) |
| `GET /v1/cards?since=`, `PUT/DELETE /v1/cards/{id}` | Sync of own cards (needs a confirmed email) |
| `GET /v1/received?since=`, `PUT/DELETE /v1/received/{id}` | Sync of the Inbox |
| `POST /v1/images`, `DELETE /v1/images/{id}` | Upload (raw JPEG/PNG, ≤ 2 MB) / delete a card image |
| `GET /images/{id}` | Public image by unguessable id |
| `/v1/cards/{id}/share_link`, `GET /c/{slug}` | Card links and web card: roadmap step 4 (501 for now) |

Errors are JSON `{"error": "<code>"}`. The codes are stable, and the app translates them.

Signed-in requests send `Authorization: Bearer <accessToken>`. Access tokens last 15 minutes. The app then calls `/v1/auth/refresh`; a session stays signed in until sign-out, or until 90 days without use.

### Sync protocol

* `GET /v1/cards?since=N` returns `{changes, cursor, hasMore}`. Each change is `{id, updatedAt, deleted, data?}`. Store `cursor`, and ask again while `hasMore` is true.
* `PUT /v1/cards/{id}` with the full card JSON stores it **only if its `updatedAt` is newer** than the server's copy (last writer wins), and returns the version now stored. If the phone's change lost, the response is the newer server version to keep.
* `DELETE /v1/cards/{id}` with `{updatedAt}` leaves a tombstone, so other phones learn about the deletion.
* The server keeps card images only if they are its own `/images/…` URLs, ignores the phone's `shareSlug`, and drops images from Inbox entries.
