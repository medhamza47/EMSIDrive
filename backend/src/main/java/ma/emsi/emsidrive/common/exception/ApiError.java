package ma.emsi.emsidrive.common.exception;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.time.Instant;
import java.util.List;

/**
 * Normalized error payload returned by the API, as defined in CONTEXT.md.
 *
 * <p>{@code details} is only serialized when field level validation failed.
 */
@JsonInclude(JsonInclude.Include.NON_EMPTY)
public record ApiError(
        String timestamp,
        int status,
        String code,
        String message,
        List<ApiFieldError> details) {

    public static ApiError of(int status, String code, String message) {
        return new ApiError(Instant.now().toString(), status, code, message, List.of());
    }

    public static ApiError of(int status, String code, String message, List<ApiFieldError> details) {
        return new ApiError(Instant.now().toString(), status, code, message, details);
    }
}
