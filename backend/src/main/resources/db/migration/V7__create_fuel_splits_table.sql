-- Fuel cost of a ride, shared among its participants through fuel_shares.
CREATE TABLE fuel_splits (
    id                UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    ride_offer_id     UUID          NOT NULL REFERENCES ride_offers (id) ON DELETE CASCADE,
    created_by_id     UUID          NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    total_distance_km NUMERIC(8, 2),
    fuel_price_per_l  NUMERIC(6, 3),
    consumption_l_100km NUMERIC(5, 2),
    total_cost        NUMERIC(10, 2) NOT NULL,
    currency          VARCHAR(3)    NOT NULL DEFAULT 'MAD',
    status            VARCHAR(20)   NOT NULL DEFAULT 'PENDING',
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT uq_fuel_splits_ride_offer UNIQUE (ride_offer_id),
    CONSTRAINT chk_fuel_splits_status CHECK (status IN ('PENDING', 'SETTLED', 'CANCELLED')),
    CONSTRAINT chk_fuel_splits_total_cost CHECK (total_cost >= 0)
);

CREATE INDEX idx_fuel_splits_ride_offer_id ON fuel_splits (ride_offer_id);
CREATE INDEX idx_fuel_splits_created_by_id ON fuel_splits (created_by_id);
CREATE INDEX idx_fuel_splits_status_created_at ON fuel_splits (status, created_at DESC);
