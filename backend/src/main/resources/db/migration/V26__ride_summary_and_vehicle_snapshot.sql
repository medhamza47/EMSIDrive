ALTER TABLE ride_offers
    ADD COLUMN vehicle_brand VARCHAR(60),
    ADD COLUMN vehicle_model VARCHAR(60),
    ADD COLUMN vehicle_color VARCHAR(30);

-- Legacy reviews keep their existing contents and provenance.
ALTER TABLE ratings ADD COLUMN marketplace_review BOOLEAN NOT NULL DEFAULT FALSE;
CREATE UNIQUE INDEX uq_ratings_booking_author ON ratings(booking_id, author_id)
    WHERE marketplace_review;
