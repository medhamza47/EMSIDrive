package ma.emsi.emsidrive.booking.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import ma.emsi.emsidrive.booking.entity.Booking;
import ma.emsi.emsidrive.booking.entity.BookingStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface BookingRepository extends JpaRepository<Booking, UUID> {

    Optional<Booking> findByRideOfferIdAndPassengerId(UUID rideOfferId, UUID passengerId);

    List<Booking> findAllByRideOfferId(UUID rideOfferId);

    Page<Booking> findAllByPassengerId(UUID passengerId, Pageable pageable);

    List<Booking> findAllByPassengerIdAndStatus(UUID passengerId, BookingStatus status);

    long countByRideOfferIdAndStatus(UUID rideOfferId, BookingStatus status);
}
