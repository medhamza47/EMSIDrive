-- Ride demand posted by a passenger waiting for a driver.
CREATE TABLE ride_requests (
    id                    UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    passenger_id          UUID           NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    origin_label          VARCHAR(160)   NOT NULL,
    origin_latitude       NUMERIC(9, 6)  NOT NULL,
    origin_longitude      NUMERIC(9, 6)  NOT NULL,
    destination_label     VARCHAR(160)   NOT NULL,
    destination_latitude  NUMERIC(9, 6)  NOT NULL,
    destination_longitude NUMERIC(9, 6)  NOT NULL,
    departure_time        TIMESTAMPTZ    NOT NULL,
    seats_needed          SMALLINT       NOT NULL DEFAULT 1,
    notes                 VARCHAR(500),
    status                VARCHAR(20)    NOT NULL DEFAULT 'PENDING',
    created_at            TIMESTAMPTZ    NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ    NOT NULL DEFAULT now(),
    CONSTRAINT chk_ride_requests_status CHECK (status IN ('PENDING', 'MATCHED', 'COMPLETED', 'CANCELLED', 'EXPIRED')),
    CONSTRAINT chk_ride_requests_seats_needed CHECK (seats_needed BETWEEN 1 AND 8),
    CONSTRAINT chk_ride_requests_origin CHECK (origin_latitude BETWEEN -90 AND 90 AND origin_longitude BETWEEN -180 AND 180),
    CONSTRAINT chk_ride_requests_destination CHECK (destination_latitude BETWEEN -90 AND 90 AND destination_longitude BETWEEN -180 AND 180)
);

CREATE INDEX idx_ride_requests_passenger_id ON ride_requests (passenger_id);
CREATE INDEX idx_ride_requests_departure_time ON ride_requests (departure_time);
CREATE INDEX idx_ride_requests_status_departure_time ON ride_requests (status, departure_time);
CREATE INDEX idx_ride_requests_origin_coordinates ON ride_requests (origin_latitude, origin_longitude);
CREATE INDEX idx_ride_requests_destination_coordinates ON ride_requests (destination_latitude, destination_longitude);
