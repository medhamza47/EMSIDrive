package ma.emsi.emsidrive.config;

import java.time.Duration;
import java.util.List;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Authentication settings bound from the {@code app.security} configuration tree.
 *
 * @param jwt                 signing key and token lifetimes
 * @param studentEmailDomains domains accepted when a student registers
 */
@ConfigurationProperties(prefix = "app.security")
public record SecurityProperties(Jwt jwt, List<String> studentEmailDomains) {

    public SecurityProperties {
        studentEmailDomains = studentEmailDomains == null ? List.of() : List.copyOf(studentEmailDomains);
    }

    /** JWT signing key and token lifetimes. */
    public record Jwt(String secret, Duration accessTokenTtl, Duration refreshTokenTtl) {
    }
}
