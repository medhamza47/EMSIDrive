package ma.emsi.emsidrive.ride.entity;

/** Lifecycle of a passenger ride request. */
public enum RideRequestStatus {
    PENDING,
    MATCHED,
    COMPLETED,
    CANCELLED,
    EXPIRED
}
