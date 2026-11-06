package ma.emsi.emsidrive.vehicle.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.util.UUID;
import ma.emsi.emsidrive.vehicle.entity.Vehicle;
import ma.emsi.emsidrive.vehicle.entity.VehicleType;

@Schema(description = "Vehicle declared by the authenticated user")
public record VehicleResponse(
        UUID id,
        VehicleType type,
        String brand,
        String model,
        String color,
        int seats,
        boolean active,
        Instant createdAt,
        Instant updatedAt) {

    public static VehicleResponse from(Vehicle vehicle) {
        return new VehicleResponse(
                vehicle.getId(),
                vehicle.getType(),
                vehicle.getBrand(),
                vehicle.getModel(),
                vehicle.getColor(),
                vehicle.getSeats() == null ? 0 : vehicle.getSeats().intValue(),
                vehicle.isActive(),
                vehicle.getCreatedAt(),
                vehicle.getUpdatedAt());
    }
}
