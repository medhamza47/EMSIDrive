package ma.emsi.emsidrive.auth.security;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class TokenHasherTest {

    @Test
    void producesDeterministicSha256Hex() {
        // SHA-256 of "emsidrive".
        assertThat(TokenHasher.sha256Hex("emsidrive"))
                .isEqualTo("7f9eb1f9b7606063e54be5d24009ae7969be70243f263b9223d821c89bf58736");
    }

    @Test
    void producesSixtyFourHexadecimalCharacters() {
        String hash = TokenHasher.sha256Hex("any-opaque-refresh-token");

        assertThat(hash).hasSize(64).matches("[0-9a-f]{64}");
    }

    @Test
    void differentTokensProduceDifferentHashes() {
        assertThat(TokenHasher.sha256Hex("token-a")).isNotEqualTo(TokenHasher.sha256Hex("token-b"));
    }
}
