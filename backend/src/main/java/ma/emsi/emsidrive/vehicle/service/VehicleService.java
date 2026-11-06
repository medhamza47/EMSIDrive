package ma.emsi.emsidrive.vehicle.service;

import java.util.List;
import java.util.UUID;
import ma.emsi.emsidrive.common.exception.ApiException;
import ma.emsi.emsidrive.user.entity.User;
import ma.emsi.emsidrive.user.repository.UserRepository;
import ma.emsi.emsidrive.vehicle.dto.VehicleRequest;
import ma.emsi.emsidrive.vehicle.dto.VehicleResponse;
import ma.emsi.emsidrive.vehicle.entity.Vehicle;
import ma.emsi.emsidrive.vehicle.repository.VehicleRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Vehicle management for the authenticated user.
 *
 * <p>Every lookup is filtered by the owner id taken from the access token, therefore a
 * user can never read or mutate a vehicle belonging to somebody else.
 */
@Service
public class VehicleService {

    private final VehicleRepository vehicleRepository;
    private final UserRepository userRepository;

    public VehicleService(VehicleRepository vehicleRepository, UserRepository userRepository) {
        this.vehicleRepository = vehicleRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public List<VehicleResponse> listVehicles(UUID ownerId) {
        return vehicleRepository.findAllByOwnerIdOrderByCreatedAtDesc(ownerId).stream()
                .map(VehicleResponse::from)
                .toList();
    }

    @Transactional
    public VehicleResponse createVehicle(UUID ownerId, VehicleRequest request) {
        Vehicle vehicle = Vehicle.builder()
                .owner(requireOwner(ownerId))
                .type(request.type())
                .brand(request.brand().trim())
                .model(request.model().trim())
                .color(normalize(request.color()))
                .seats(request.seats().shortValue())
                .active(true)
                .build();

        return VehicleResponse.from(vehicleRepository.saveAndFlush(vehicle));
    }

    @Transactional
    public VehicleResponse updateVehicle(UUID ownerId, UUID vehicleId, VehicleRequest request) {
        Vehicle vehicle = requireOwnedVehicle(ownerId, vehicleId);

        vehicle.setType(request.type());
        vehicle.setBrand(request.brand().trim());
        vehicle.setModel(request.model().trim());
        vehicle.setColor(normalize(request.color()));
        vehicle.setSeats(request.seats().shortValue());

        return VehicleResponse.from(vehicleRepository.saveAndFlush(vehicle));
    }

    @Transactional
    public void deleteVehicle(UUID ownerId, UUID vehicleId) {
        vehicleRepository.delete(requireOwnedVehicle(ownerId, vehicleId));
    }

    private Vehicle requireOwnedVehicle(UUID ownerId, UUID vehicleId) {
        return vehicleRepository.findByIdAndOwnerId(vehicleId, ownerId)
                .orElseThrow(() -> ApiException.notFound(
                        "VEHICLE_NOT_FOUND", "No vehicle with this id belongs to your account"));
    }

    private User requireOwner(UUID ownerId) {
        return userRepository.findById(ownerId)
                .orElseThrow(() -> ApiException.notFound("USER_NOT_FOUND", "User account no longer exists"));
    }

    private static String normalize(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
