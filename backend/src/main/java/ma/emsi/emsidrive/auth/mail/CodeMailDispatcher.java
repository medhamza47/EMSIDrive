package ma.emsi.emsidrive.auth.mail;

import java.time.Duration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.task.SimpleAsyncTaskExecutor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

/**
 * Sends a code email once the current transaction commits, on a separate thread:
 * a rolled back request never emails a code, and the response time does not depend
 * on the SMTP server. Failures are logged, never returned to the client.
 */
@Component
public class CodeMailDispatcher {

    private static final Logger log = LoggerFactory.getLogger(CodeMailDispatcher.class);

    private final CodeMailer mailer;
    private final SimpleAsyncTaskExecutor executor = new SimpleAsyncTaskExecutor("code-mail-");

    public CodeMailDispatcher(CodeMailer mailer) {
        this.mailer = mailer;
        this.executor.setConcurrencyLimit(4);
    }

    /** Must be called inside a transaction. */
    public void sendAfterCommit(CodePurpose purpose, String email, String fullName, String code, Duration validity) {
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                executor.execute(() -> {
                    try {
                        mailer.sendCode(purpose, email, fullName, code, validity);
                    } catch (RuntimeException ex) {
                        log.error("{} email could not be sent", purpose, ex);
                    }
                });
            }
        });
    }
}
