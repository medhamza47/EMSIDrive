package ma.emsi.emsidrive.common.exception;

/**
 * Single validation failure attached to an {@link ApiError}.
 */
public record ApiFieldError(String field, String message) {
}
