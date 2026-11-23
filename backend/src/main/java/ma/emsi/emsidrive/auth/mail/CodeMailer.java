package ma.emsi.emsidrive.auth.mail;

import java.time.Duration;

/** Delivers emailed one-time codes: password reset and email confirmation. */
public interface CodeMailer {

    void sendCode(CodePurpose purpose, String email, String fullName, String code, Duration validity);
}
