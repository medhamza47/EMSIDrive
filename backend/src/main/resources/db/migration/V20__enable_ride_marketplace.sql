ALTER TABLE ride_offers
    ADD COLUMN marketplace BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN vehicle_preference VARCHAR(10),
    ADD COLUMN notes VARCHAR(500);

ALTER TABLE ride_requests
    ADD COLUMN marketplace BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN vehicle_preference VARCHAR(10);

ALTER TABLE bookings
    ADD COLUMN live_latitude NUMERIC(9, 6),
    ADD COLUMN live_longitude NUMERIC(9, 6),
    ADD COLUMN live_at TIMESTAMPTZ;

CREATE TABLE ride_messages (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    booking_id UUID NOT NULL REFERENCES bookings (id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    body VARCHAR(1000) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_ride_messages_booking_id ON ride_messages (booking_id, id);
