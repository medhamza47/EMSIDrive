ALTER TABLE bookings
    ADD COLUMN tracking_state VARCHAR(20) NOT NULL DEFAULT 'CONFIRMED',
    ADD COLUMN tracking_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    ADD COLUMN live_captured_at TIMESTAMPTZ,
    ADD COLUMN live_accuracy DOUBLE PRECISION,
    ADD COLUMN live_heading DOUBLE PRECISION,
    ADD CONSTRAINT chk_booking_tracking_state CHECK
        (tracking_state IN ('CONFIRMED','EN_ROUTE','ARRIVED','IN_PROGRESS','COMPLETED','CANCELLED'));

UPDATE bookings SET tracking_state = CASE WHEN status='COMPLETED' THEN 'COMPLETED'
    WHEN status IN ('CANCELLED','NO_SHOW') THEN 'CANCELLED' ELSE 'CONFIRMED' END;
CREATE INDEX idx_bookings_tracking_state ON bookings(tracking_state, tracking_updated_at);
