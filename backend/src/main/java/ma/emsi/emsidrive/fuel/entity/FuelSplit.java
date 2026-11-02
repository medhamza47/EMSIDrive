package ma.emsi.emsidrive.fuel.entity;

import jakarta.persistence.CascadeType;
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
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import ma.emsi.emsidrive.common.entity.AuditableEntity;
import ma.emsi.emsidrive.ride.entity.RideOffer;
import ma.emsi.emsidrive.user.entity.User;

/** Fuel cost of a ride, divided among the participants through its shares. */
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(onlyExplicitlyIncluded = true, callSuper = false)
@Entity(name = "FuelSplit")
@Table(name = "fuel_splits")
public class FuelSplit extends AuditableEntity {

    @Id
    @EqualsAndHashCode.Include
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "ride_offer_id", nullable = false, unique = true)
    private RideOffer rideOffer;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "created_by_id", nullable = false)
    private User createdBy;

    @Column(name = "total_distance_km", precision = 8, scale = 2)
    private BigDecimal totalDistanceKm;

    @Column(name = "fuel_price_per_l", precision = 6, scale = 3)
    private BigDecimal fuelPricePerL;

    @Column(name = "consumption_l_100km", precision = 5, scale = 2)
    private BigDecimal consumptionL100km;

    @Column(name = "total_cost", nullable = false, precision = 10, scale = 2)
    private BigDecimal totalCost;

    @Builder.Default
    @Column(name = "currency", nullable = false, length = 3)
    private String currency = "MAD";

    @Builder.Default
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private FuelSplitStatus status = FuelSplitStatus.PENDING;

    @Builder.Default
    @OneToMany(mappedBy = "fuelSplit", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<FuelShare> shares = new ArrayList<>();
}
