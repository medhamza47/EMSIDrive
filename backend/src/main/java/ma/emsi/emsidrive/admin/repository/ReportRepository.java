package ma.emsi.emsidrive.admin.repository;

import java.util.UUID;
import ma.emsi.emsidrive.admin.entity.Report;
import ma.emsi.emsidrive.admin.entity.ReportStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ReportRepository extends JpaRepository<Report, UUID> {

    Page<Report> findAllByStatusOrderByCreatedAtDesc(ReportStatus status, Pageable pageable);

    Page<Report> findAllByReporterId(UUID reporterId, Pageable pageable);

    Page<Report> findAllByReportedUserId(UUID reportedUserId, Pageable pageable);

    long countByStatus(ReportStatus status);
}
