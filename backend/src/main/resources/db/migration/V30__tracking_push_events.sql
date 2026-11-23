CREATE OR REPLACE FUNCTION enqueue_ride_push() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.reference_type = 'BOOKING' AND NEW.title IN (
        'REQUEST_ACCEPTED', 'OFFER_ACCEPTED', 'TRIP_STARTED', 'TRIP_COMPLETED', 'TRIP_CANCELLED', 'CHAT_MESSAGE',
        'BOOKING_CONFIRMED', 'RIDE_EN_ROUTE', 'RIDE_ARRIVED', 'RIDE_IN_PROGRESS',
        'RIDE_COMPLETED', 'RIDE_CANCELLED', 'RIDE_MESSAGE') THEN
        INSERT INTO push_deliveries(notification_id, device_token, generation)
        SELECT NEW.id, d.token, d.generation FROM push_devices d
        JOIN refresh_tokens r ON r.token_hash = d.session_hash
        WHERE d.user_id = NEW.user_id AND r.revoked_at IS NULL AND r.expires_at > now();
    END IF;
    RETURN NEW;
END;
$$;
