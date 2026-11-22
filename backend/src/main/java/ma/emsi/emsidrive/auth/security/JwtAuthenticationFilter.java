package ma.emsi.emsidrive.auth.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.http.HttpHeaders;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import ma.emsi.emsidrive.user.repository.UserRepository;

/**
 * Populates the security context from a {@code Bearer} access token.
 *
 * <p>An invalid or expired token is not rejected here: the request continues
 * anonymously and authorization rules decide the outcome, so public endpoints keep
 * working even when a client sends a stale token.
 */
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private static final String BEARER_PREFIX = "Bearer ";

    private final JwtService jwtService;
    private final UserRepository users;

    public JwtAuthenticationFilter(JwtService jwtService, UserRepository users) {
        this.jwtService = jwtService;
        this.users = users;
    }

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain) throws ServletException, IOException {

        String header = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (header != null && header.startsWith(BEARER_PREFIX)
                && SecurityContextHolder.getContext().getAuthentication() == null) {
            authenticate(header.substring(BEARER_PREFIX.length()).trim(), request);
        }
        filterChain.doFilter(request, response);
    }

    private void authenticate(String token, HttpServletRequest request) {
        Claims claims;
        try {
            claims = jwtService.parse(token);
        } catch (JwtException | IllegalArgumentException ex) {
            return;
        }
        if (!jwtService.isAccessToken(claims)) {
            return;
        }

        var account = users.findById(jwtService.extractUserId(claims)).orElse(null);
        if (account == null || !account.isEnabled()) return;
        Number issuedMillis = claims.get("issuedMillis", Number.class);
        long issued = issuedMillis == null ? claims.getIssuedAt().getTime() : issuedMillis.longValue();
        if (account.getAccessInvalidatedAt() != null
                && issued <= account.getAccessInvalidatedAt().toEpochMilli()) return;
        AuthenticatedUser principal = new AuthenticatedUser(account.getId(), account.getEmail(), account.getRole());
        UsernamePasswordAuthenticationToken authentication =
                new UsernamePasswordAuthenticationToken(principal, null, principal.authorities());
        authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
        SecurityContextHolder.getContext().setAuthentication(authentication);
    }
}
