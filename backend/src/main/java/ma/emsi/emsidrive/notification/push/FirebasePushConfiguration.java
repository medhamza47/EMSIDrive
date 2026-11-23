package ma.emsi.emsidrive.notification.push;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.*;
import java.io.IOException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;

@Configuration
@EnableScheduling
@ConditionalOnProperty(name = "app.push.enabled", havingValue = "true")
public class FirebasePushConfiguration {
    private static final Logger LOG = LoggerFactory.getLogger(FirebasePushConfiguration.class);

    @Bean(destroyMethod = "delete")
    FirebaseApp pushFirebaseApp() throws IOException {
        return FirebaseApp.initializeApp(FirebaseOptions.builder()
                .setCredentials(GoogleCredentials.getApplicationDefault())
                .setConnectTimeout(3000).setReadTimeout(5000)
                .build(), "emsidrive-push");
    }

    @Bean
    PushSender pushSender(FirebaseApp pushFirebaseApp) {
        var messaging = FirebaseMessaging.getInstance(pushFirebaseApp);
        return (token, notice, user, booking, event) -> {
            String title = switch (event) {
                case "REQUEST_ACCEPTED", "OFFER_ACCEPTED" -> "Trajet accepté";
                case "BOOKING_CONFIRMED" -> "Réservation confirmée";
                case "RIDE_EN_ROUTE" -> "Le conducteur est en route";
                case "RIDE_ARRIVED" -> "Le conducteur est arrivé";
                case "TRIP_STARTED", "RIDE_IN_PROGRESS" -> "Trajet démarré";
                case "TRIP_COMPLETED", "RIDE_COMPLETED" -> "Trajet terminé";
                case "TRIP_CANCELLED", "RIDE_CANCELLED" -> "Trajet annulé";
                case "CHAT_MESSAGE", "RIDE_MESSAGE" -> "Nouveau message";
                default -> "EMSIDrive";
            };
            var message = Message.builder().setFid(token)
                    .setNotification(Notification.builder().setTitle(title)
                            .setBody("Ouvrez EMSIDrive pour consulter votre trajet.").build())
                    .putData("notification_id", notice.toString())
                    .putData("booking_id", booking.toString())
                    .putData("user_id", user.toString())
                    .setAndroidConfig(AndroidConfig.builder().setPriority(AndroidConfig.Priority.HIGH)
                            .setTtl(3600000)
                            .setNotification(AndroidNotification.builder()
                                    .setChannelId("emsidrive_rides").setTag(notice.toString())
                                    .setIcon("ic_notification").build()).build())
                    .build();
            try {
                messaging.send(message);
                return PushSender.Result.SENT;
            } catch (FirebaseMessagingException error) {
                // Tokens, credentials and private message contents never enter the logs.
                LOG.warn("Push delivery failed with code {}", error.getMessagingErrorCode());
                return error.getMessagingErrorCode() == MessagingErrorCode.UNREGISTERED
                        ? PushSender.Result.UNREGISTERED : PushSender.Result.RETRY;
            }
        };
    }
}
