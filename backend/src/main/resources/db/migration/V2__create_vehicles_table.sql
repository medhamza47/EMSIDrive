-- Vehicles declared by drivers. Seat capacity limits how many bookings a ride offer can accept.
CREATE TABLE vehicles (
    id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id     UUID         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    plate_number VARCHAR(20)  NOT NULL,
    brand        VARCHAR(60)  NOT NULL,
    model        VARCHAR(60)  NOT NULL,
    color        VARCHAR(30),
    seats        SMALLINT     NOT NULL,
    active       BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT uq_vehicles_plate_number UNIQUE (plate_number),
    CONSTRAINT chk_vehicles_seats CHECK (seats BETWEEN 1 AND 8)
);

CREATE INDEX idx_vehicles_owner_id ON vehicles (owner_id);
