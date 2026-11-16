ALTER TABLE ride_offers
    ADD COLUMN started_at TIMESTAMPTZ,
    ADD COLUMN completed_at TIMESTAMPTZ;

-- Keep cancelled bookings as history while allowing a new reservation.
ALTER TABLE bookings DROP CONSTRAINT uq_bookings_offer_passenger;
CREATE UNIQUE INDEX uq_bookings_active_offer_passenger
    ON bookings (ride_offer_id, passenger_id)
    WHERE status IN ('PENDING', 'CONFIRMED');
