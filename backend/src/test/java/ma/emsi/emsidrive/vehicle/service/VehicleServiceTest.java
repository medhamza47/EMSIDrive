package ma.emsi.emsidrive.vehicle.service;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import ma.emsi.emsidrive.common.exception.ApiException;
import ma.emsi.emsidrive.user.entity.User;
import ma.emsi.emsidrive.user.entity.UserRole;
import ma.emsi.emsidrive.user.repository.UserRepository;
import ma.emsi.emsidrive.vehicle.dto.VehicleRequest;
import ma.emsi.emsidrive.vehicle.dto.VehicleResponse;
import ma.emsi.emsidrive.vehicle.entity.Vehicle;
import ma.emsi.emsidrive.vehicle.entity.VehicleType;
import ma.emsi.emsidrive.vehicle.repository.VehicleRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.http.HttpStatus;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class VehicleServiceTest {

    private static final UUID OWNER_ID = UUID.fromString("1a2b3c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d");
    private static final UUID OTHER_USER_ID = UUID.fromString("9f8e7d6c-5b4a-4938-8271-6a5b4c3d2e1f");
    private static final UUID VEHICLE_ID = UUID.fromString("2b3c4d5e-6f7a-4b8c-9d0e-1f2a3b4c5d6e");

    @Mock
    private VehicleRepository vehicleRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private VehicleService vehicleService;

    @Test
    void listVehiclesReturnsOnlyTheOwnerVehicles() {
        when(vehicleRepository.findAllByOwnerIdOrderByCreatedAtDesc(OWNER_ID))
                .thenReturn(List.of(vehicle(OWNER_ID, VehicleType.VOITURE, "Dacia", "Logan")));

        List<VehicleResponse> vehicles = vehicleService.listVehicles(OWNER_ID);

        assertThat(vehicles).hasSize(1);
        assertThat(vehicles.get(0).brand()).isEqualTo("Dacia");
        assertThat(vehicles.get(0).type()).isEqualTo(VehicleType.VOITURE);
    }

    @Test
    void createVehiclePersistsForTheAuthenticatedOwner() {
        when(userRepository.findById(OWNER_ID)).thenReturn(Optional.of(user(OWNER_ID)));
        when(vehicleRepository.saveAndFlush(any(Vehicle.class))).thenAnswer(invocation -> invocation.getArgument(0));

        VehicleResponse created = vehicleService.createVehicle(
                OWNER_ID, new VehicleRequest(VehicleType.MOTO, "  Yamaha ", " Xmax ", " Black ", 2));

        assertThat(created.type()).isEqualTo(VehicleType.MOTO);
        assertThat(created.brand()).isEqualTo("Yamaha");
        assertThat(created.model()).isEqualTo("Xmax");
        assertThat(created.color()).isEqualTo("Black");
        assertThat(created.seats()).isEqualTo(2);
        assertThat(created.active()).isTrue();
    }

    @Test
    void createVehicleRejectsUnknownOwner() {
        when(userRepository.findById(OWNER_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> vehicleService.createVehicle(
                OWNER_ID, new VehicleRequest(VehicleType.VOITURE, "Dacia", "Logan", null, 4)))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getCode()).isEqualTo("USER_NOT_FOUND"));

        verify(vehicleRepository, never()).saveAndFlush(any(Vehicle.class));
    }

    @Test
    void updateVehicleAppliesNewValues() {
        Vehicle existing = vehicle(OWNER_ID, VehicleType.VOITURE, "Dacia", "Logan");
        when(vehicleRepository.findByIdAndOwnerId(VEHICLE_ID, OWNER_ID)).thenReturn(Optional.of(existing));
        when(vehicleRepository.saveAndFlush(any(Vehicle.class))).thenAnswer(invocation -> invocation.getArgument(0));

        VehicleResponse updated = vehicleService.updateVehicle(
                OWNER_ID, VEHICLE_ID, new VehicleRequest(VehicleType.VOITURE, "Renault", "Clio", "Blue", 5));

        assertThat(updated.brand()).isEqualTo("Renault");
        assertThat(updated.model()).isEqualTo("Clio");
        assertThat(updated.color()).isEqualTo("Blue");
        assertThat(updated.seats()).isEqualTo(5);
    }

    @Test
    void updateVehicleRejectsVehicleOwnedByAnotherUser() {
        when(vehicleRepository.findByIdAndOwnerId(VEHICLE_ID, OTHER_USER_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> vehicleService.updateVehicle(
                OTHER_USER_ID, VEHICLE_ID, new VehicleRequest(VehicleType.VOITURE, "Renault", "Clio", "Blue", 5)))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException apiException = (ApiException) ex;
                    assertThat(apiException.getStatus()).isEqualTo(HttpStatus.NOT_FOUND);
                    assertThat(apiException.getCode()).isEqualTo("VEHICLE_NOT_FOUND");
                });

        verify(vehicleRepository, never()).saveAndFlush(any(Vehicle.class));
    }

    @Test
    void deleteVehicleRemovesOwnedVehicle() {
        Vehicle existing = vehicle(OWNER_ID, VehicleType.MOTO, "Yamaha", "Xmax");
        when(vehicleRepository.findByIdAndOwnerId(VEHICLE_ID, OWNER_ID)).thenReturn(Optional.of(existing));

        vehicleService.deleteVehicle(OWNER_ID, VEHICLE_ID);

        verify(vehicleRepository).delete(existing);
    }

    @Test
    void deleteVehicleRejectsVehicleOwnedByAnotherUser() {
        when(vehicleRepository.findByIdAndOwnerId(VEHICLE_ID, OTHER_USER_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> vehicleService.deleteVehicle(OTHER_USER_ID, VEHICLE_ID))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getCode()).isEqualTo("VEHICLE_NOT_FOUND"));

        verify(vehicleRepository, never()).delete(any(Vehicle.class));
    }

    private static User user(UUID id) {
        return User.builder()
                .id(id)
                .email("sara.elidrissi@emsi-edu.ma")
                .passwordHash("$2a$10$0123456789012345678901234567890123456789012345678901234567")
                .fullName("Sara El Idrissi")
                .role(UserRole.STUDENT)
                .enabled(true)
                .build();
    }

    private static Vehicle vehicle(UUID ownerId, VehicleType type, String brand, String model) {
        return Vehicle.builder()
                .id(VEHICLE_ID)
                .owner(user(ownerId))
                .type(type)
                .brand(brand)
                .model(model)
                .color("White")
                .seats((short) 4)
                .active(true)
                .build();
    }
}
