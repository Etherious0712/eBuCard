# eBuCard server

[Dart Frog](https://dart-frog.dev) API server and public web-card host.
Endpoints follow `docs/DESIGN.md` §7; everything except `/health` is a stub
that returns `501 Not Implemented` in this scaffold.

```sh
docker compose up -d          # PostgreSQL on localhost:5432
dart pub get
dart pub global activate dart_frog_cli
dart_frog dev                 # http://localhost:8080/health
dart test
```

| Route | Purpose |
|---|---|
| `GET /health` | Liveness check |
| `/v1/auth/*` | Email/password, Sign in with Apple, Google, token refresh/logout |
| `/v1/cards`, `/v1/cards/{id}` | CRUD for the signed-in user's own cards |
| `/v1/cards/{id}/share_link` | Create / revoke the public share slug |
| `/v1/received`, `/v1/received/{id}` | Sync of cards the user has received |
| `GET /c/{slug}` | Public web card (HTML) + vCard download for people without the app |
