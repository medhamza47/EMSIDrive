package ma.emsi.emsidrive.common;

import java.sql.DriverManager;
import java.util.Map;
import java.util.TreeMap;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import static org.assertj.core.api.Assertions.assertThat;

@Testcontainers
class DatabaseMigrationIntegrationTest {
    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @Test
    void upgradesPublishedDevelopHistoryWithoutRenumberingExistingMigrations() throws Exception {
        Flyway.configure().dataSource(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword())
                .target("27").load().migrate();
        try (var connection = DriverManager.getConnection(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword());
             var statement = connection.createStatement()) {
            Map<String, Integer> originalChecksums = new TreeMap<>();
            try (var rows = statement.executeQuery("SELECT version, checksum FROM flyway_schema_history ORDER BY installed_rank")) {
                while (rows.next()) originalChecksums.put(rows.getString(1), rows.getInt(2));
            }
            statement.executeUpdate("""
                    INSERT INTO users(id,email,password_hash,full_name,role)
                    VALUES ('00000000-0000-0000-0000-000000000001','driver@emsi-edu.ma','test','Driver','STUDENT'),
                           ('00000000-0000-0000-0000-000000000002','passenger@emsi-edu.ma','test','Passenger','STUDENT');
                    INSERT INTO ride_offers(id,driver_id,origin_label,origin_latitude,origin_longitude,
                        destination_label,destination_latitude,destination_longitude,departure_time,available_seats)
                    VALUES ('00000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000001',
                            'Marrakech',31.63,-8.01,'EMSI Marrakech Centre',31.65,-8.02,now(),0);
                    INSERT INTO bookings(ride_offer_id,passenger_id,status)
                    SELECT '00000000-0000-0000-0000-000000000003'::uuid,
                           '00000000-0000-0000-0000-000000000002'::uuid,status
                    FROM (VALUES ('COMPLETED'),('CANCELLED'),('CONFIRMED')) AS existing(status);
                    """);
            var upgraded = Flyway.configure().dataSource(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword())
                    .load();
            assertThat(upgraded.migrate().migrationsExecuted).isEqualTo(3);
            upgraded.validate();
            assertThat(upgraded.info().current().getVersion().toString()).isEqualTo("30");
            try (var rows = statement.executeQuery("SELECT version, checksum FROM flyway_schema_history WHERE version::integer <= 27")) {
                while (rows.next()) assertThat(rows.getInt(2)).isEqualTo(originalChecksums.get(rows.getString(1)));
            }
            try (var rows = statement.executeQuery("SELECT status, tracking_state FROM bookings")) {
                int preserved = 0;
                while (rows.next()) {
                    assertThat(rows.getString(2)).isEqualTo(rows.getString(1));
                    preserved++;
                }
                assertThat(preserved).isEqualTo(3);
            }
        }
    }
}
