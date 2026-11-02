-- Driving is a capability of a student account, not a distinct role.
-- Roles are now limited to STUDENT and ADMIN.
UPDATE users SET role = 'STUDENT' WHERE role = 'DRIVER';

ALTER TABLE users DROP CONSTRAINT chk_users_role;
ALTER TABLE users ADD CONSTRAINT chk_users_role CHECK (role IN ('STUDENT', 'ADMIN'));
