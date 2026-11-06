package ma.emsi.emsidrive.vehicle.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import ma.emsi.emsidrive.auth.security.AuthenticatedUser;
import ma.emsi.emsidrive.vehicle.dto.VehicleRequest;
import ma.emsi.emsidrive.vehicle.dto.VehicleResponse;
import ma.emsi.emsidrive.vehicle.service.VehicleService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/me/vehicles")
@Tag(name = "Vehicles", description = "Vehicles owned by the authenticated user")
public class VehicleController {

    private final VehicleService vehicleService;

    public VehicleController(VehicleService vehicleService) {
        this.vehicleService = vehicleService;
    }

    @GetMapping
    @Operation(summary = "List the vehicles of the authenticated user")
    public List<VehicleResponse> list(@AuthenticationPrincipal AuthenticatedUser principal) {
        return vehicleService.listVehicles(principal.id());
    }

    @PostMapping
    @Operation(summary = "Declare a new vehicle")
    public ResponseEntity<VehicleResponse> create(
            @AuthenticationPrincipal AuthenticatedUser principal,
            @Valid @RequestBody VehicleRequest request) {
        VehicleResponse created = vehicleService.createVehicle(principal.id(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update one of the authenticated user vehicles")
    public VehicleResponse update(
            @AuthenticationPrincipal AuthenticatedUser principal,
            @PathVariable UUID id,
            @Valid @RequestBody VehicleRequest request) {
        return vehicleService.updateVehicle(principal.id(), id, request);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete one of the authenticated user vehicles")
    public ResponseEntity<Void> delete(
            @AuthenticationPrincipal AuthenticatedUser principal,
            @PathVariable UUID id) {
        vehicleService.deleteVehicle(principal.id(), id);
        return ResponseEntity.noContent().build();
    }
}
