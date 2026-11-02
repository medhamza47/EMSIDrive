-- FCM/APNs tokens registered by the mobile app for push notifications.
CREATE TABLE device_tokens (
    id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    token        VARCHAR(255) NOT NULL,
    platform     VARCHAR(20)  NOT NULL,
    device_name  VARCHAR(120),
    active       BOOLEAN      NOT NULL DEFAULT TRUE,
    last_used_at TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT uq_device_tokens_token UNIQUE (token),
    CONSTRAINT chk_device_tokens_platform CHECK (platform IN ('ANDROID', 'IOS', 'WEB'))
);

CREATE INDEX idx_device_tokens_user_id_active ON device_tokens (user_id, active);
CREATE INDEX idx_device_tokens_last_used_at ON device_tokens (last_used_at DESC);
