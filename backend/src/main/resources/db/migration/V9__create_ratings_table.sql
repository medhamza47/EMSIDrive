-- Bidirectional rating: one row per author for a given ride.
CREATE TABLE ratings (
    id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id    UUID         REFERENCES bookings (id) ON DELETE SET NULL,
    ride_offer_id UUID         REFERENCES ride_offers (id) ON DELETE SET NULL,
    author_id     UUID         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    target_id     UUID         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    score         SMALLINT     NOT NULL,
    comment       VARCHAR(500),
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT chk_ratings_score CHECK (score BETWEEN 1 AND 5),
    CONSTRAINT chk_ratings_author_not_target CHECK (author_id <> target_id)
);

CREATE INDEX idx_ratings_target_id_created_at ON ratings (target_id, created_at DESC);
CREATE INDEX idx_ratings_author_id ON ratings (author_id);
CREATE INDEX idx_ratings_booking_id ON ratings (booking_id);
CREATE INDEX idx_ratings_ride_offer_id ON ratings (ride_offer_id);
