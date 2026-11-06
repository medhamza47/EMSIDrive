-- The mobile form only captures the vehicle kind, not the plate number,
-- so the plate stays optional (PostgreSQL unique constraints accept several NULLs).
ALTER TABLE vehicles ALTER COLUMN plate_number DROP NOT NULL;

-- Existing rows predate the kind selector and were all declared as cars.
ALTER TABLE vehicles ADD COLUMN type VARCHAR(10);
UPDATE vehicles SET type = 'VOITURE' WHERE type IS NULL;
ALTER TABLE vehicles ALTER COLUMN type SET NOT NULL;
ALTER TABLE vehicles ADD CONSTRAINT chk_vehicles_type CHECK (type IN ('MOTO', 'VOITURE'));
