package ma.emsi.emsidrive.auth.mail;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.mail.javamail.JavaMailSender;

/**
 * Uses SMTP when {@code spring.mail.host} is configured. Without it, requests are
 * still accepted but no email leaves the server: the code is never logged.
 */
@Configuration
public class MailConfiguration {

    private static final Logger log = LoggerFactory.getLogger(MailConfiguration.class);

    @Bean
    CodeMailer codeMailer(
            ObjectProvider<JavaMailSender> sender,
            @Value("${app.mail.from:EMSIDrive <no-reply@emsidrive.local>}") String from) {
        JavaMailSender smtp = sender.getIfAvailable();
        if (smtp != null) {
            return new SmtpCodeMailer(smtp, from);
        }
        log.warn("spring.mail.host is not set: emailed codes will not be delivered");
        return (purpose, email, fullName, code, validity) ->
                log.warn("{} code requested but no mail server is configured", purpose);
    }
}
