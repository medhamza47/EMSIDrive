package ma.emsi.emsidrive.user.repository;

import java.util.Optional;
import java.util.UUID;
import ma.emsi.emsidrive.user.entity.User;
import ma.emsi.emsidrive.user.entity.UserRole;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import org.springframework.data.jpa.repository.Query;

@Repository
public interface UserRepository extends JpaRepository<User, UUID> {

    @Query(value = "SELECT avg(score) FROM ratings WHERE target_id = :id", nativeQuery = true)
    Double averageRating(UUID id);

    @Query(value = "SELECT count(*) FROM ratings WHERE target_id = :id", nativeQuery = true)
    long ratingCount(UUID id);

    Optional<User> findByEmailIgnoreCase(String email);

    boolean existsByEmailIgnoreCase(String email);

    Page<User> findAllByRole(UserRole role, Pageable pageable);

    Page<User> findAllByEnabled(boolean enabled, Pageable pageable);
}
