// Database schema, as an ordered list of migrations. Each runs once, in a
// transaction, and is recorded in `schema_migrations`. Never edit a
// migration that has been released; add a new one instead.

/// Schema changes in order. The index + 1 is the version.
const migrations = <String>[
  // 1: accounts, sessions, email tokens, synced data, images.
  '''
  CREATE TABLE users (
    id                UUID PRIMARY KEY,
    email             TEXT UNIQUE,
    email_verified_at TIMESTAMPTZ,
    password_hash     TEXT,
    apple_sub         TEXT UNIQUE,
    google_sub        TEXT UNIQUE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    deactivated_at    TIMESTAMPTZ,
    delete_after      TIMESTAMPTZ
  );

  CREATE TABLE refresh_tokens (
    id           UUID PRIMARY KEY,
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash   TEXT NOT NULL UNIQUE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at   TIMESTAMPTZ NOT NULL,
    revoked_at   TIMESTAMPTZ
  );
  CREATE INDEX refresh_tokens_user ON refresh_tokens(user_id);

  CREATE TABLE email_tokens (
    id         UUID PRIMARY KEY,
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    purpose    TEXT NOT NULL CHECK (purpose IN ('verify', 'reset')),
    token_hash TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    used_at    TIMESTAMPTZ
  );

  CREATE SEQUENCE sync_seq;

  CREATE TABLE cards (
    id         UUID PRIMARY KEY,
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    data       JSONB,
    share_slug TEXT UNIQUE,
    updated_at TIMESTAMPTZ NOT NULL,
    deleted    BOOLEAN NOT NULL DEFAULT false,
    seq        BIGINT NOT NULL
  );
  CREATE INDEX cards_user_seq ON cards(user_id, seq);

  CREATE TABLE received_cards (
    id         UUID PRIMARY KEY,
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    data       JSONB,
    updated_at TIMESTAMPTZ NOT NULL,
    deleted    BOOLEAN NOT NULL DEFAULT false,
    seq        BIGINT NOT NULL
  );
  CREATE INDEX received_cards_user_seq ON received_cards(user_id, seq);

  CREATE TABLE images (
    id           UUID PRIMARY KEY,
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content_type TEXT NOT NULL,
    size         INTEGER NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
  );
  CREATE INDEX images_user ON images(user_id);
  ''',
  // 2: card links. A card gets a share slug on its first sync; the owner
  // can revoke it, and then none is created again until they ask for one.
  '''
  ALTER TABLE cards ADD COLUMN link_revoked BOOLEAN NOT NULL DEFAULT false;
  ''',
];
