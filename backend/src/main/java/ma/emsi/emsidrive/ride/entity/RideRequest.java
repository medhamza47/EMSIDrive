package ma.emsi.emsidrive.ride.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import ma.emsi.emsidrive.common.entity.AuditableEntity;
import ma.emsi.emsidrive.user.entity.User;

/** Ride demand posted by a passenger waiting to be matched with a driver. */
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(onlyExplicitlyIncluded = true, callSuper = false)
@Entity(name = "RideRequest")
@Table(name = "ride_requests")
public class RideRequest extends AuditableEntity {

    @Id
    @EqualsAndHashCode.Include
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "passenger_id", nullable = false)
    private User passenger;

    @Column(name = "origin_label", nullable = false, length = 160)
    private String originLabel;

    @Column(name = "origin_latitude", nullable = false, precision = 9, scale = 6)
    private BigDecimal originLatitude;

    @Column(name = "origin_longitude", nullable = false, precision = 9, scale = 6)
    private BigDecimal originLongitude;

    @Column(name = "destination_label", nullable = false, length = 160)
    private String destinationLabel;

    @Column(name = "destination_latitude", nullable = false, precision = 9, scale = 6)
    private BigDecimal destinationLatitude;

    @Column(name = "destination_longitude", nullable = false, precision = 9, scale = 6)
    private BigDecimal destinationLongitude;

    @Column(name = "departure_time", nullable = false)
    private Instant departureTime;

    @Builder.Default
    @Column(name = "seats_needed", nullable = false)
    private Short seatsNeeded = 1;

    @Column(name = "notes", length = 500)
    private String notes;

    @Builder.Default
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private RideRequestStatus status = RideRequestStatus.PENDING;
}
