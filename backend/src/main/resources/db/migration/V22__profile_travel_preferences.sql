ALTER TABLE users ADD COLUMN preferred_campus VARCHAR(20);
ALTER TABLE users ADD COLUMN preferred_vehicle VARCHAR(12);
ALTER TABLE users ADD CONSTRAINT chk_users_preferred_campus CHECK (preferred_campus IS NULL OR preferred_campus IN ('CENTRE', 'TARGA'));
ALTER TABLE users ADD CONSTRAINT chk_users_preferred_vehicle CHECK (preferred_vehicle IS NULL OR preferred_vehicle IN ('MOTO', 'CAR', 'ANY'));
