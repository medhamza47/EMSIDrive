package ma.emsi.emsidrive.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI emsiDriveOpenApi() {
        return new OpenAPI().info(new Info()
                .title("EMSIDrive API")
                .description("Carpooling platform for EMSI Marrakech students.")
                .version("v1")
                .contact(new Contact().name("EMSIDrive Team").email("team@emsidrive.ma")));
    }
}
