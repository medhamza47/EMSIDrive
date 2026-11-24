package ma.emsi.emsidrive.auth.mail;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import jakarta.mail.BodyPart;
import jakarta.mail.Multipart;
import jakarta.mail.Part;
import jakarta.mail.Session;
import jakarta.mail.internet.MimeMessage;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;
import org.mockito.ArgumentCaptor;
import org.springframework.mail.javamail.JavaMailSender;

class SmtpCodeMailerTest {

    @Test
    void sendsBrandedHtmlWithPlainTextAndInlineLogo() throws Exception {
        MimeMessage message = send(CodePurpose.PASSWORD_RESET, "Sara <script>alert(1)</script>");

        assertThat(message.getSubject()).isEqualTo(CodePurpose.PASSWORD_RESET.subject).doesNotContain("482913");
        assertThat(message.getAllRecipients()[0].toString()).isEqualTo("sara@emsi-edu.ma");

        List<Part> parts = parts(message);
        assertThat(textOf(parts, "text/html"))
                .contains("482913", "15 minutes", "#015629", "cid:" + SmtpCodeMailer.LOGO_CONTENT_ID)
                .contains("Sara &lt;script&gt;").doesNotContain("<script>");
        assertThat(textOf(parts, "text/plain")).contains("482913", "15 minutes");
        assertThat(parts).anySatisfy(part -> {
            assertThat(part.isMimeType("image/jpeg")).isTrue();
            assertThat(((BodyPart) part).getHeader("Content-ID")[0])
                    .isEqualTo("<" + SmtpCodeMailer.LOGO_CONTENT_ID + ">");
        });
    }

    @ParameterizedTest
    @EnumSource(CodePurpose.class)
    void eachPurposeFillsEveryPlaceholderWithItsOwnWording(CodePurpose purpose) throws Exception {
        List<Part> parts = parts(send(purpose, "Sara"));
        String html = textOf(parts, "text/html");

        assertThat(html).doesNotContain("{{").contains("Confirmez votre adresse e-mail".equals(purpose.title)
                ? "création de votre compte" : "nouveau mot de passe");
        assertThat(textOf(parts, "text/plain")).contains(purpose.intro, purpose.notice);
    }

    private static MimeMessage send(CodePurpose purpose, String name) throws Exception {
        JavaMailSender sender = mock(JavaMailSender.class);
        when(sender.createMimeMessage()).thenReturn(new MimeMessage(Session.getInstance(new Properties())));

        new SmtpCodeMailer(sender, "EMSIDrive <no-reply@emsidrive.local>")
                .sendCode(purpose, "sara@emsi-edu.ma", name, "482913", Duration.ofMinutes(15));

        ArgumentCaptor<MimeMessage> sent = ArgumentCaptor.forClass(MimeMessage.class);
        verify(sender).send(sent.capture());
        MimeMessage message = sent.getValue();
        message.saveChanges();
        return message;
    }

    private static List<Part> parts(Part root) throws Exception {
        List<Part> parts = new ArrayList<>();
        collect(root, parts);
        return parts;
    }

    private static void collect(Part part, List<Part> parts) throws Exception {
        if (part.getContent() instanceof Multipart multipart) {
            for (int i = 0; i < multipart.getCount(); i++) {
                collect(multipart.getBodyPart(i), parts);
            }
        } else {
            parts.add(part);
        }
    }

    private static String textOf(List<Part> parts, String mimeType) throws Exception {
        for (Part part : parts) {
            if (part.isMimeType(mimeType)) {
                return (String) part.getContent();
            }
        }
        throw new AssertionError("No " + mimeType + " part");
    }
}
