-- Per-passenger share of a fuel split, with its settlement state.
CREATE TABLE fuel_shares (
    id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    fuel_split_id UUID          NOT NULL REFERENCES fuel_splits (id) ON DELETE CASCADE,
    user_id       UUID          NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    amount        NUMERIC(10, 2) NOT NULL,
    paid          BOOLEAN       NOT NULL DEFAULT FALSE,
    paid_at       TIMESTAMPTZ,
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT uq_fuel_shares_split_user UNIQUE (fuel_split_id, user_id),
    CONSTRAINT chk_fuel_shares_amount CHECK (amount >= 0)
);

CREATE INDEX idx_fuel_shares_fuel_split_id ON fuel_shares (fuel_split_id);
CREATE INDEX idx_fuel_shares_user_id_paid ON fuel_shares (user_id, paid);
