ALTER TABLE schedules ADD COLUMN valid_from DATE;
ALTER TABLE schedules ADD COLUMN valid_until DATE;
ALTER TABLE schedules ADD COLUMN revision INTEGER NOT NULL DEFAULT 1;
ALTER TABLE schedules ADD CONSTRAINT chk_schedule_validity
    CHECK (valid_from IS NULL OR valid_until IS NULL OR valid_until >= valid_from);
ALTER TABLE schedule_slots ADD COLUMN campus VARCHAR(20);
ALTER TABLE schedule_slots ADD CONSTRAINT chk_schedule_campus
    CHECK (campus IS NULL OR campus IN ('TARGA', 'CENTRE'));
-- Existing unconfirmed/demo imports must never generate real suggestions.
UPDATE schedules SET active = FALSE;
CREATE UNIQUE INDEX idx_schedules_one_active ON schedules(user_id) WHERE active;
