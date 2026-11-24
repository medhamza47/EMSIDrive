-- One-time codes emailed to reset a forgotten password.
-- Only an HMAC of the code is stored, so a database leak alone cannot be used
-- to reset an account. A code is short lived and locked after a few failures.
CREATE TABLE password_reset_codes (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    code_hash   VARCHAR(64)  NOT NULL,
    expires_at  TIMESTAMPTZ  NOT NULL,
    attempts    INTEGER      NOT NULL DEFAULT 0,
    consumed_at TIMESTAMPTZ,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX idx_password_reset_codes_user_created ON password_reset_codes (user_id, created_at DESC);
