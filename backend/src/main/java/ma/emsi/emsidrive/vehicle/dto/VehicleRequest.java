package ma.emsi.emsidrive.vehicle.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import ma.emsi.emsidrive.vehicle.entity.VehicleType;

/** Payload used to declare or update a vehicle. */
@Schema(description = "Vehicle creation or update request")
public record VehicleRequest(

        @Schema(description = "Kind of vehicle", example = "VOITURE")
        @NotNull(message = "Vehicle type is required")
        VehicleType type,

        @Schema(description = "Manufacturer", example = "Dacia")
        @NotBlank(message = "Brand is required")
        @Size(max = 60, message = "Brand must not exceed 60 characters")
        String brand,

        @Schema(description = "Model", example = "Logan")
        @NotBlank(message = "Model is required")
        @Size(max = 60, message = "Model must not exceed 60 characters")
        String model,

        @Schema(description = "Color", example = "White")
        @Size(max = 30, message = "Color must not exceed 30 characters")
        String color,

        @Schema(description = "Number of passenger seats", example = "4")
        @NotNull(message = "Seat count is required")
        @Min(value = 1, message = "A vehicle must offer at least 1 seat")
        @Max(value = 8, message = "A vehicle cannot offer more than 8 seats")
        Integer seats) {
}
