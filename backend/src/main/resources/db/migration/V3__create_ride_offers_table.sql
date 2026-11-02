-- Rides offered by a driver. Coordinates are stored as numeric pairs so that
-- nearby-ride searches can rely on plain B-tree indexes on (latitude, longitude).
CREATE TABLE ride_offers (
    id                    UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id             UUID           NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    vehicle_id            UUID           REFERENCES vehicles (id) ON DELETE SET NULL,
    origin_label          VARCHAR(160)   NOT NULL,
    origin_latitude       NUMERIC(9, 6)  NOT NULL,
    origin_longitude      NUMERIC(9, 6)  NOT NULL,
    destination_label     VARCHAR(160)   NOT NULL,
    destination_latitude  NUMERIC(9, 6)  NOT NULL,
    destination_longitude NUMERIC(9, 6)  NOT NULL,
    departure_time        TIMESTAMPTZ    NOT NULL,
    arrival_time          TIMESTAMPTZ,
    available_seats       SMALLINT       NOT NULL,
    price_per_seat        NUMERIC(10, 2),
    status                VARCHAR(20)    NOT NULL DEFAULT 'OPEN',
    created_at            TIMESTAMPTZ    NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ    NOT NULL DEFAULT now(),
    CONSTRAINT chk_ride_offers_status CHECK (status IN ('OPEN', 'FULL', 'ONGOING', 'COMPLETED', 'CANCELLED')),
    CONSTRAINT chk_ride_offers_available_seats CHECK (available_seats >= 0),
    CONSTRAINT chk_ride_offers_price CHECK (price_per_seat IS NULL OR price_per_seat >= 0),
    CONSTRAINT chk_ride_offers_time_order CHECK (arrival_time IS NULL OR arrival_time > departure_time),
    CONSTRAINT chk_ride_offers_origin CHECK (origin_latitude BETWEEN -90 AND 90 AND origin_longitude BETWEEN -180 AND 180),
    CONSTRAINT chk_ride_offers_destination CHECK (destination_latitude BETWEEN -90 AND 90 AND destination_longitude BETWEEN -180 AND 180)
);

CREATE INDEX idx_ride_offers_driver_id ON ride_offers (driver_id);
CREATE INDEX idx_ride_offers_vehicle_id ON ride_offers (vehicle_id);
CREATE INDEX idx_ride_offers_departure_time ON ride_offers (departure_time);
CREATE INDEX idx_ride_offers_status_departure_time ON ride_offers (status, departure_time);
CREATE INDEX idx_ride_offers_origin_coordinates ON ride_offers (origin_latitude, origin_longitude);
CREATE INDEX idx_ride_offers_destination_coordinates ON ride_offers (destination_latitude, destination_longitude);
