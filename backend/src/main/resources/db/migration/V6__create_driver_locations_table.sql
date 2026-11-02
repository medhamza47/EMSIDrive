-- Last known GPS position of a driver, used by the nearby-drivers screen.
CREATE TABLE driver_locations (
    id          UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id   UUID          NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    vehicle_id  UUID          REFERENCES vehicles (id) ON DELETE SET NULL,
    latitude    NUMERIC(9, 6) NOT NULL,
    longitude   NUMERIC(9, 6) NOT NULL,
    heading     NUMERIC(5, 2),
    speed_kmh   NUMERIC(5, 2),
    accuracy_m  NUMERIC(6, 2),
    recorded_at TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_at  TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT chk_driver_locations_latitude CHECK (latitude BETWEEN -90 AND 90),
    CONSTRAINT chk_driver_locations_longitude CHECK (longitude BETWEEN -180 AND 180)
);

CREATE INDEX idx_driver_locations_driver_id_recorded_at ON driver_locations (driver_id, recorded_at DESC);
CREATE INDEX idx_driver_locations_coordinates ON driver_locations (latitude, longitude);
CREATE INDEX idx_driver_locations_recorded_at ON driver_locations (recorded_at DESC);
