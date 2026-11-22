CREATE TABLE push_devices (
    token VARCHAR(2048) PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_hash VARCHAR(64) NOT NULL REFERENCES refresh_tokens(token_hash) ON DELETE CASCADE,
    generation UUID NOT NULL DEFAULT gen_random_uuid(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_push_devices_user ON push_devices(user_id);

CREATE TABLE push_deliveries (
    id BIGSERIAL PRIMARY KEY,
    notification_id UUID NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
    device_token VARCHAR(2048) NOT NULL REFERENCES push_devices(token) ON DELETE CASCADE,
    generation UUID NOT NULL,
    attempts INTEGER NOT NULL DEFAULT 0,
    available_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    finished_at TIMESTAMPTZ,
    UNIQUE (notification_id, device_token)
);
CREATE INDEX idx_push_deliveries_pending ON push_deliveries(available_at) WHERE finished_at IS NULL;

-- The queue commits or rolls back with the booking/chat transaction.
-- Existing notices are deliberately excluded when a phone is registered.
CREATE FUNCTION enqueue_ride_push() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.reference_type = 'BOOKING' AND NEW.title IN
        ('REQUEST_ACCEPTED', 'OFFER_ACCEPTED', 'TRIP_STARTED', 'TRIP_COMPLETED', 'TRIP_CANCELLED', 'CHAT_MESSAGE') THEN
        INSERT INTO push_deliveries(notification_id, device_token, generation)
        SELECT NEW.id, d.token, d.generation FROM push_devices d
        JOIN refresh_tokens r ON r.token_hash = d.session_hash
        WHERE d.user_id = NEW.user_id AND r.revoked_at IS NULL AND r.expires_at > now();
    END IF;
    RETURN NEW;
END;
$$;
CREATE TRIGGER notifications_enqueue_push AFTER INSERT ON notifications
    FOR EACH ROW EXECUTE FUNCTION enqueue_ride_push();
