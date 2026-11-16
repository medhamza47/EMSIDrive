CREATE TABLE schedule_import_jobs (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL CHECK (status IN ('QUEUED','PROCESSING','SUCCEEDED','FAILED','CANCELLED','DISMISSED')),
    document_hash VARCHAR(64) NOT NULL,
    group_name VARCHAR(120) NOT NULL,
    revision INTEGER NOT NULL CHECK (revision >= 0),
    payload TEXT,
    result TEXT,
    error_code VARCHAR(80),
    lease_token UUID,
    lease_until TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX idx_schedule_import_jobs_one_running ON schedule_import_jobs(user_id)
    WHERE status IN ('QUEUED','PROCESSING');
CREATE INDEX idx_schedule_import_jobs_queue ON schedule_import_jobs(status, created_at);
CREATE INDEX idx_schedule_import_jobs_user ON schedule_import_jobs(user_id, created_at DESC);

CREATE TABLE schedule_travel_preferences (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    campus VARCHAR(20) NOT NULL CHECK (campus IN ('TARGA','CENTRE')),
    latitude NUMERIC(10,7) NOT NULL CHECK (latitude BETWEEN -90 AND 90),
    longitude NUMERIC(10,7) NOT NULL CHECK (longitude BETWEEN -180 AND 180),
    radius_meters INTEGER NOT NULL CHECK (radius_meters BETWEEN 100 AND 10000),
    commute_minutes INTEGER NOT NULL CHECK (commute_minutes BETWEEN 5 AND 180),
    margin_minutes INTEGER NOT NULL CHECK (margin_minutes BETWEEN 0 AND 60),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
