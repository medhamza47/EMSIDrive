-- In-app notifications: booking proposals, match suggestions and ride reminders.
CREATE TABLE notifications (
    id                UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    type              VARCHAR(30)  NOT NULL,
    title             VARCHAR(160) NOT NULL,
    body              VARCHAR(500) NOT NULL,
    reference_type    VARCHAR(30),
    reference_id      UUID,
    read_at           TIMESTAMPTZ,
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT chk_notifications_type CHECK (type IN ('BOOKING', 'MATCH', 'RIDE_UPDATE', 'FUEL_SPLIT', 'RATING', 'SYSTEM')),
    CONSTRAINT chk_notifications_reference_type CHECK (reference_type IS NULL OR reference_type IN ('RIDE_OFFER', 'RIDE_REQUEST', 'BOOKING', 'FUEL_SPLIT', 'RATING'))
);

CREATE INDEX idx_notifications_user_id_created_at ON notifications (user_id, created_at DESC);
CREATE INDEX idx_notifications_user_id_read_at ON notifications (user_id, read_at);
CREATE INDEX idx_notifications_reference ON notifications (reference_type, reference_id);
