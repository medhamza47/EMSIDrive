package ma.emsi.emsidrive.notification.push;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import jakarta.validation.constraints.Pattern;
import ma.emsi.emsidrive.auth.security.AuthenticatedUser;
import ma.emsi.emsidrive.auth.security.TokenHasher;
import ma.emsi.emsidrive.common.exception.ApiException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/me/push-devices")
public class PushDeviceController {
    private final JdbcTemplate jdbc;

    public PushDeviceController(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public record Registration(@NotBlank @Size(max = 2048) @Pattern(regexp = "[\\x21-\\x7E]+") String token,
                               @NotBlank @Size(max = 4096) String refreshToken) {}
    public record Removal(@NotBlank @Size(max = 2048) @Pattern(regexp = "[\\x21-\\x7E]+") String token) {}

    @PutMapping
    @Transactional
    public void register(@AuthenticationPrincipal AuthenticatedUser user,
                         @Valid @RequestBody Registration input) {
        String hash = TokenHasher.sha256Hex(input.refreshToken());
        // Lock the session against concurrent logout/rotation while linking the phone.
        var sessions = jdbc.queryForList("""
                SELECT id FROM refresh_tokens WHERE token_hash = ? AND user_id = ?
                    AND revoked_at IS NULL AND expires_at > now() FOR UPDATE
                """, hash, user.id());
        if (sessions.isEmpty()) {
            throw ApiException.conflict("SESSION_CHANGED", "Retry with the current session");
        }
        jdbc.update("""
                INSERT INTO push_devices(token, user_id, session_hash) VALUES (?, ?, ?)
                ON CONFLICT (token) DO UPDATE SET user_id = EXCLUDED.user_id,
                    session_hash = EXCLUDED.session_hash, updated_at = now(),
                    generation = CASE WHEN push_devices.user_id = EXCLUDED.user_id
                        THEN push_devices.generation ELSE gen_random_uuid() END
                """, input.token(), user.id(), hash);
    }

    @DeleteMapping
    public void remove(@AuthenticationPrincipal AuthenticatedUser user,
                       @Valid @RequestBody Removal input) {
        jdbc.update("DELETE FROM push_devices WHERE token = ? AND user_id = ?", input.token(), user.id());
    }
}
