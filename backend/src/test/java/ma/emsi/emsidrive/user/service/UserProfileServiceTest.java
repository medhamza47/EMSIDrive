package ma.emsi.emsidrive.user.service;

import java.util.Optional;
import java.util.UUID;
import ma.emsi.emsidrive.common.exception.ApiException;
import ma.emsi.emsidrive.user.dto.UpdateProfileRequest;
import ma.emsi.emsidrive.user.dto.UserProfileResponse;
import ma.emsi.emsidrive.user.entity.User;
import ma.emsi.emsidrive.user.entity.UserRole;
import ma.emsi.emsidrive.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
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
class UserProfileServiceTest {

    private static final UUID USER_ID = UUID.fromString("8b7b6f8c-2f0e-4b64-9d4d-6f8f1c2a9b31");

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private UserProfileService userProfileService;

    @Test
    void getProfileReturnsAllEditableFields() {
        when(userRepository.findById(USER_ID)).thenReturn(Optional.of(student()));

        UserProfileResponse profile = userProfileService.getProfile(USER_ID);

        assertThat(profile.id()).isEqualTo(USER_ID);
        assertThat(profile.email()).isEqualTo("sara.elidrissi@emsi-edu.ma");
        assertThat(profile.fullName()).isEqualTo("Sara El Idrissi");
        assertThat(profile.filiere()).isEqualTo("2DSI");
        assertThat(profile.academicYear()).isEqualTo("2025-2026");
        assertThat(profile.photoUrl()).isEqualTo("https://cdn.emsidrive.ma/sara.jpg");
        assertThat(profile.role()).isEqualTo(UserRole.STUDENT);
        assertThat(profile.enabled()).isTrue();
    }

    @Test
    void getProfileRejectsUnknownAccount() {
        when(userRepository.findById(USER_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> userProfileService.getProfile(USER_ID))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException apiException = (ApiException) ex;
                    assertThat(apiException.getStatus()).isEqualTo(HttpStatus.NOT_FOUND);
                    assertThat(apiException.getCode()).isEqualTo("USER_NOT_FOUND");
                });
    }

    @Test
    void updateProfilePersistsEveryEditableField() {
        when(userRepository.findById(USER_ID)).thenReturn(Optional.of(student()));
        when(userRepository.saveAndFlush(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

        UserProfileResponse updated = userProfileService.updateProfile(USER_ID, new UpdateProfileRequest(
                "  Sara El Idrissi Alaoui  ",
                "+212698765432",
                "  GI  ",
                " 2026-2027 ",
                " https://cdn.emsidrive.ma/new.jpg "));

        assertThat(updated.fullName()).isEqualTo("Sara El Idrissi Alaoui");
        assertThat(updated.phoneNumber()).isEqualTo("+212698765432");
        assertThat(updated.filiere()).isEqualTo("GI");
        assertThat(updated.academicYear()).isEqualTo("2026-2027");
        assertThat(updated.photoUrl()).isEqualTo("https://cdn.emsidrive.ma/new.jpg");

        ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).saveAndFlush(captor.capture());
        assertThat(captor.getValue().getFiliere()).isEqualTo("GI");
    }

    @Test
    void updateProfileBlanksOptionalFieldsToNull() {
        when(userRepository.findById(USER_ID)).thenReturn(Optional.of(student()));
        when(userRepository.saveAndFlush(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

        UserProfileResponse updated = userProfileService.updateProfile(
                USER_ID, new UpdateProfileRequest("Sara El Idrissi", "   ", "", null, ""));

        assertThat(updated.phoneNumber()).isNull();
        assertThat(updated.filiere()).isNull();
        assertThat(updated.academicYear()).isNull();
        assertThat(updated.photoUrl()).isNull();
    }

    @Test
    void updateProfileRejectsUnknownAccountWithoutSaving() {
        when(userRepository.findById(USER_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> userProfileService.updateProfile(
                USER_ID, new UpdateProfileRequest("Sara", null, null, null, null)))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getStatus()).isEqualTo(HttpStatus.NOT_FOUND));

        verify(userRepository, never()).saveAndFlush(any(User.class));
    }

    private static User student() {
        return User.builder()
                .id(USER_ID)
                .email("sara.elidrissi@emsi-edu.ma")
                .passwordHash("$2a$10$0123456789012345678901234567890123456789012345678901234567")
                .fullName("Sara El Idrissi")
                .phoneNumber("+212612345678")
                .filiere("2DSI")
                .academicYear("2025-2026")
                .photoUrl("https://cdn.emsidrive.ma/sara.jpg")
                .role(UserRole.STUDENT)
                .enabled(true)
                .build();
    }
}
