/// ─────────────────────────────────────────────────────────────────────────────
/// App Config — change BASE_URL here only, everything else picks it up.
/// ─────────────────────────────────────────────────────────────────────────────
///
/// Common values:
///   Android emulator  → http://10.0.2.2:3000/api/v1
///   Real device (USB) → http://192.168.x.x:3000/api/v1   ← your PC's local IP
///   Production        → https://api.speedonet.in/api/v1
/// ─────────────────────────────────────────────────────────────────────────────

class AppConfig {
  AppConfig._();

  // ── Change only this line ──────────────────────────────────────────────────
  static const String baseUrl = 'http://192.168.0.102:3000/api/v1';
  // ──────────────────────────────────────────────────────────────────────────

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Token storage keys
  static const String kAccessToken  = 'access_token';
  static const String kRefreshToken = 'refresh_token';
  static const String kUserId       = 'user_id';
  static const String kUserPhone    = 'user_phone';
  static const String kUserName     = 'user_name';
}