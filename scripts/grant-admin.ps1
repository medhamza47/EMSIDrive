# Grants administration to an existing enabled account in the local development database.
# Register the account through EMSIDrive first. No passwords are stored by this script.
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-zA-Z0-9._+\-]+@emsi-edu\.ma$')]
    [string]$Email
)
$ErrorActionPreference = 'Stop'
$accountEmail = $Email.ToLowerInvariant()
$accountCount = docker exec emsidrive-postgres psql -U emsidrive -d emsidrive -tAc "SELECT count(*) FROM users WHERE lower(email) = '$accountEmail' AND enabled"
if ($LASTEXITCODE -ne 0) { throw 'Cannot read the local development database.' }
if ($accountCount.Trim() -ne '1') { throw 'Register and activate this account before granting administration.' }
$query = @"
BEGIN;
WITH promoted AS (
    UPDATE users SET role = 'ADMIN', updated_at = now()
    WHERE lower(email) = '$accountEmail' AND enabled AND role = 'STUDENT'
    RETURNING id
)
INSERT INTO admin_actions(actor_id, action, target_id, reason)
SELECT id, 'ADMIN_GRANTED', id, 'Local administrator provisioning' FROM promoted;
SELECT email, role, enabled FROM users WHERE lower(email) = '$accountEmail';
COMMIT;
"@
docker exec emsidrive-postgres psql -U emsidrive -d emsidrive -v ON_ERROR_STOP=1 -c $query
if ($LASTEXITCODE -ne 0) { throw 'Administrator provisioning failed.' }
