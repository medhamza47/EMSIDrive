-- Codes emailed before an account is created, proving the address exists and
-- belongs to the student. No account row exists until a code is confirmed.
-- Only an HMAC of the code is stored, salted with the normalized email.
CREATE TABLE email_verification_codes (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    email       VARCHAR(180) NOT NULL,
    code_hash   VARCHAR(64)  NOT NULL,
    expires_at  TIMESTAMPTZ  NOT NULL,
    attempts    INTEGER      NOT NULL DEFAULT 0,
    consumed_at TIMESTAMPTZ,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX idx_email_verification_codes_email_created ON email_verification_codes (email, created_at DESC);
