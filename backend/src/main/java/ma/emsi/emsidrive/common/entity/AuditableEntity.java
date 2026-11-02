package ma.emsi.emsidrive.common.entity;

import jakarta.persistence.Column;
import jakarta.persistence.MappedSuperclass;
import java.time.Instant;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

/**
 * Shared audit columns for mutable aggregates.
 *
 * <p>The Flyway migrations declare {@code created_at}/{@code updated_at} with a
 * database default; Hibernate also sets both values so that a freshly persisted
 * entity is populated without an extra reload.
 */
@Getter
@Setter
@MappedSuperclass
public abstract class AuditableEntity {

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
}
