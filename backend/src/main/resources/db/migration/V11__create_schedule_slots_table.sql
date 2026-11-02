-- One course slot of a weekly schedule. Weekday follows ISO-8601 (1 = Monday, 7 = Sunday)
-- so that time-range queries can be combined with the weekday filter.
CREATE TABLE schedule_slots (
    id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    schedule_id  UUID         NOT NULL REFERENCES schedules (id) ON DELETE CASCADE,
    label        VARCHAR(120) NOT NULL,
    location     VARCHAR(160),
    weekday      SMALLINT     NOT NULL,
    start_time   TIME         NOT NULL,
    end_time     TIME         NOT NULL,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT chk_schedule_slots_weekday CHECK (weekday BETWEEN 1 AND 7),
    CONSTRAINT chk_schedule_slots_time_order CHECK (end_time > start_time)
);

CREATE INDEX idx_schedule_slots_schedule_id ON schedule_slots (schedule_id);
CREATE INDEX idx_schedule_slots_weekday_time ON schedule_slots (weekday, start_time, end_time);
