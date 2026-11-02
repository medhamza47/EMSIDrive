package ma.emsi.emsidrive.auth.security;

import java.util.Collection;
import java.util.List;
import java.util.UUID;
import ma.emsi.emsidrive.user.entity.UserRole;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

/**
 * Principal restored from a verified access token, exposed to controllers through
 * {@code @AuthenticationPrincipal}.
 */
public record AuthenticatedUser(UUID id, String email, UserRole role) {

    public Collection<GrantedAuthority> authorities() {
        return List.of(new SimpleGrantedAuthority("ROLE_" + role.name()));
    }
}
