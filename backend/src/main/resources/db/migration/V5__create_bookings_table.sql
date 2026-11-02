-- Seat reservation linking a passenger to a ride offer.
CREATE TABLE bookings (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    ride_offer_id   UUID        NOT NULL REFERENCES ride_offers (id) ON DELETE CASCADE,
    passenger_id    UUID        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    ride_request_id UUID        REFERENCES ride_requests (id) ON DELETE SET NULL,
    seats_booked    SMALLINT    NOT NULL DEFAULT 1,
    status          VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    booked_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    cancelled_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_bookings_offer_passenger UNIQUE (ride_offer_id, passenger_id),
    CONSTRAINT chk_bookings_status CHECK (status IN ('PENDING', 'CONFIRMED', 'CANCELLED', 'COMPLETED', 'NO_SHOW')),
    CONSTRAINT chk_bookings_seats_booked CHECK (seats_booked BETWEEN 1 AND 8)
);

CREATE INDEX idx_bookings_ride_offer_id ON bookings (ride_offer_id);
CREATE INDEX idx_bookings_passenger_id ON bookings (passenger_id);
CREATE INDEX idx_bookings_ride_request_id ON bookings (ride_request_id);
CREATE INDEX idx_bookings_status_booked_at ON bookings (status, booked_at);
