package ma.emsi.emsidrive;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class EmsiDriveApplication {

    public static void main(String[] args) {
        SpringApplication.run(EmsiDriveApplication.class, args);
    }
}
