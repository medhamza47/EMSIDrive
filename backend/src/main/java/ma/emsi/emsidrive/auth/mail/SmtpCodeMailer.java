package ma.emsi.emsidrive.auth.mail;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import org.springframework.core.io.ClassPathResource;
import org.springframework.mail.MailPreparationException;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.web.util.HtmlUtils;

/**
 * Sends a code as a branded HTML email (green and white, logo inline) with a plain
 * text alternative for mail apps that do not render HTML.
 */
public class SmtpCodeMailer implements CodeMailer {

    static final String LOGO_CONTENT_ID = "emsidrive-logo";

    private static final ClassPathResource LOGO = new ClassPathResource("mail/logo.jpg");
    private static final String UTF_8 = StandardCharsets.UTF_8.name();

    private final JavaMailSender sender;
    private final String from;
    private final String htmlTemplate;

    public SmtpCodeMailer(JavaMailSender sender, String from) {
        this.sender = sender;
        this.from = from;
        try {
            this.htmlTemplate = new ClassPathResource("mail/code.html").getContentAsString(StandardCharsets.UTF_8);
        } catch (IOException ex) {
            throw new UncheckedIOException("Code email template is missing", ex);
        }
    }

    @Override
    public void sendCode(CodePurpose purpose, String email, String fullName, String code, Duration validity) {
        String minutes = Long.toString(validity.toMinutes());
        // The name is typed by the student: escape it before it enters the HTML.
        String html = htmlTemplate
                .replace("{{title}}", escape(purpose.title))
                .replace("{{intro}}", escape(purpose.intro))
                .replace("{{afterValidity}}", escape(purpose.afterValidity))
                .replace("{{notice}}", escape(purpose.notice))
                .replace("{{name}}", escape(fullName))
                .replace("{{code}}", code)
                .replace("{{minutes}}", minutes);
        try {
            MimeMessage message = sender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, MimeMessageHelper.MULTIPART_MODE_MIXED_RELATED, UTF_8);
            helper.setFrom(from);
            helper.setTo(email);
            helper.setSubject(purpose.subject);
            helper.setText(plainText(purpose, fullName, code, minutes), html);
            helper.addInline(LOGO_CONTENT_ID, LOGO, "image/jpeg");
            sender.send(message);
        } catch (MessagingException ex) {
            throw new MailPreparationException("Code email could not be built", ex);
        }
    }

    private static String escape(String text) {
        return HtmlUtils.htmlEscape(text, UTF_8);
    }

    private static String plainText(CodePurpose purpose, String fullName, String code, String minutes) {
        return """
                Bonjour %s,

                %s

                    %s

                Ce code est valable %s minutes et ne peut être utilisé qu'une seule fois.%s

                %s

                EMSIDrive - Le covoiturage entre étudiants EMSI
                """.formatted(fullName, purpose.intro, code, minutes, purpose.afterValidity, purpose.notice);
    }
}
