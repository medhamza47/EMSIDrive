-- Phones linked to an account for fingerprint login.
-- The phone keeps a random device key behind its biometric check; only the
-- SHA-256 hash is stored here, so a database leak cannot be replayed.
CREATE TABLE biometric_devices (
    id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    key_hash     VARCHAR(64)  NOT NULL UNIQUE,
    device_name  VARCHAR(120),
    last_used_at TIMESTAMPTZ,
    revoked_at   TIMESTAMPTZ,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX idx_biometric_devices_user_id ON biometric_devices (user_id);
