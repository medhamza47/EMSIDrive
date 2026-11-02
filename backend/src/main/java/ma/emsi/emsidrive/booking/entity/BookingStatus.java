package ma.emsi.emsidrive.booking.entity;

/** Lifecycle of a seat reservation. */
public enum BookingStatus {
    PENDING,
    CONFIRMED,
    CANCELLED,
    COMPLETED,
    NO_SHOW
}
