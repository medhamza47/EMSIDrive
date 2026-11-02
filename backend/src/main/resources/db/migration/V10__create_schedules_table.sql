-- Weekly recurring timetable imported by a student (manual entry or AI extraction).
CREATE TABLE schedules (
    id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          UUID        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    name             VARCHAR(120) NOT NULL,
    source           VARCHAR(20) NOT NULL DEFAULT 'MANUAL',
    ai_confidence    NUMERIC(4, 2),
    message_count    INTEGER     NOT NULL DEFAULT 0,
    active           BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_schedules_source CHECK (source IN ('MANUAL', 'AI_IMPORT', 'IMAGE', 'PDF')),
    CONSTRAINT chk_schedules_ai_confidence CHECK (ai_confidence IS NULL OR (ai_confidence >= 0 AND ai_confidence <= 1))
);

CREATE INDEX idx_schedules_user_id ON schedules (user_id);
CREATE INDEX idx_schedules_user_id_active ON schedules (user_id, active);
CREATE INDEX idx_schedules_created_at ON schedules (created_at DESC);
