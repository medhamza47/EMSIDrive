ALTER TABLE users ADD COLUMN access_invalidated_at TIMESTAMPTZ;
ALTER TABLE reports ADD COLUMN revision INTEGER NOT NULL DEFAULT 1;
ALTER TABLE reports ADD COLUMN submission_id UUID;
ALTER TABLE reports ADD COLUMN ride_request_id UUID REFERENCES ride_requests(id) ON DELETE SET NULL;
CREATE UNIQUE INDEX uq_report_submission ON reports(reporter_id, submission_id);

CREATE TABLE admin_actions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    actor_id UUID NOT NULL REFERENCES users(id),
    action VARCHAR(40) NOT NULL,
    target_id UUID NOT NULL,
    reason VARCHAR(500) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_admin_actions_created ON admin_actions(created_at DESC, id DESC);
