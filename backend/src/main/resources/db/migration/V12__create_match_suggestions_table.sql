-- Suggestion produced by the matching engine to pair a ride request with a ride offer.
CREATE TABLE match_suggestions (
    id             UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    ride_request_id UUID         NOT NULL REFERENCES ride_requests (id) ON DELETE CASCADE,
    ride_offer_id   UUID         NOT NULL REFERENCES ride_offers (id) ON DELETE CASCADE,
    score           NUMERIC(5, 2) NOT NULL,
    detour_km       NUMERIC(8, 2),
    walking_km      NUMERIC(8, 2),
    time_delta_min  INTEGER,
    status          VARCHAR(20)   NOT NULL DEFAULT 'SUGGESTED',
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT uq_match_suggestions_request_offer UNIQUE (ride_request_id, ride_offer_id),
    CONSTRAINT chk_match_suggestions_status CHECK (status IN ('SUGGESTED', 'ACCEPTED', 'REJECTED', 'EXPIRED')),
    CONSTRAINT chk_match_suggestions_score CHECK (score BETWEEN 0 AND 100)
);

CREATE INDEX idx_match_suggestions_ride_request_id ON match_suggestions (ride_request_id);
CREATE INDEX idx_match_suggestions_ride_offer_id ON match_suggestions (ride_offer_id);
CREATE INDEX idx_match_suggestions_status_score ON match_suggestions (status, score DESC);
