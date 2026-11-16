/// This phone, linked to an account for fingerprint login.
///
/// [deviceKey] is the secret the server gave the phone; it is only sent after a
/// successful fingerprint check and is replaced on every login. [email] and
/// [fullName] let the login screen greet the student without any request.
class BiometricLink {
  const BiometricLink({
    required this.deviceId,
    required this.deviceKey,
    required this.email,
    required this.fullName,
  });

  final String deviceId;
  final String deviceKey;
  final String email;
  final String fullName;

  /// First word of [fullName], or the email when the name is empty.
  String get firstName {
    final name = fullName.trim();
    return name.isEmpty ? email : name.split(RegExp(r'\s+')).first;
  }

  BiometricLink withKey(String key) => BiometricLink(
    deviceId: deviceId,
    deviceKey: key,
    email: email,
    fullName: fullName,
  );
}
