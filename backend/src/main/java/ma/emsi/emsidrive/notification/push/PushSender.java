package ma.emsi.emsidrive.notification.push;

import java.util.UUID;

public interface PushSender {
    enum Result { SENT, RETRY, UNREGISTERED }

    Result send(String token, UUID notification, UUID user, UUID booking, String event);
}
