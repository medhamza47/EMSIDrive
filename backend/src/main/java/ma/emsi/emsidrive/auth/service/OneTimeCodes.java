package ma.emsi.emsidrive.auth.service;

import java.nio.charset.StandardCharsets;
import java.security.InvalidKeyException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.HexFormat;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import ma.emsi.emsidrive.config.SecurityProperties;
import org.springframework.stereotype.Component;

/**
 * Emailed 6-digit codes: generation and keyed hashing. Only the HMAC is stored, so a
 * database leak alone cannot reveal or replay a code.
 */
@Component
public class OneTimeCodes {

    private final SecretKeySpec key;
    private final SecureRandom random = new SecureRandom();

    public OneTimeCodes(SecurityProperties securityProperties) {
        this.key = new SecretKeySpec(
                securityProperties.jwt().secret().getBytes(StandardCharsets.UTF_8), "HmacSHA256");
    }

    public String generate() {
        return "%06d".formatted(random.nextInt(1_000_000));
    }

    /** HMAC of the code, salted with what it belongs to (an account id or an email). */
    public String hash(String owner, String code) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(key);
            return HexFormat.of().formatHex(mac.doFinal((owner + ":" + code).getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException | InvalidKeyException ex) {
            throw new IllegalStateException("HmacSHA256 is not available", ex);
        }
    }

    /** Constant time comparison of a submitted code with a stored hash. */
    public boolean matches(String storedHash, String owner, String code) {
        return MessageDigest.isEqual(
                storedHash.getBytes(StandardCharsets.UTF_8),
                hash(owner, code).getBytes(StandardCharsets.UTF_8));
    }
}
