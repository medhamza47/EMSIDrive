-- User-submitted reports moderated from the admin web console.
CREATE TABLE reports (
    id                UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id       UUID         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    reported_user_id  UUID         REFERENCES users (id) ON DELETE SET NULL,
    ride_offer_id     UUID         REFERENCES ride_offers (id) ON DELETE SET NULL,
    booking_id        UUID         REFERENCES bookings (id) ON DELETE SET NULL,
    category          VARCHAR(30)  NOT NULL,
    description       VARCHAR(1000) NOT NULL,
    status            VARCHAR(20)  NOT NULL DEFAULT 'OPEN',
    resolution_note   VARCHAR(500),
    resolved_at       TIMESTAMPTZ,
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT chk_reports_category CHECK (category IN ('HARASSMENT', 'NO_SHOW', 'UNSAFE_DRIVING', 'FAKE_PROFILE', 'PAYMENT', 'OTHER')),
    CONSTRAINT chk_reports_status CHECK (status IN ('OPEN', 'UNDER_REVIEW', 'RESOLVED', 'DISMISSED'))
);

CREATE INDEX idx_reports_reporter_id ON reports (reporter_id);
CREATE INDEX idx_reports_reported_user_id ON reports (reported_user_id);
CREATE INDEX idx_reports_ride_offer_id ON reports (ride_offer_id);
CREATE INDEX idx_reports_booking_id ON reports (booking_id);
CREATE INDEX idx_reports_status_created_at ON reports (status, created_at DESC);
