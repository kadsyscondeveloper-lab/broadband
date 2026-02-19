import 'package:shared_preferences/shared_preferences.dart';
import 'app_config.dart';

/// Persists auth tokens and basic user info across app restarts.
/// Uses shared_preferences (simple, no native setup needed).
/// Swap to flutter_secure_storage for production if you need hardware encryption.
class StorageService {
  // Singleton
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  /// Call once at app startup (before runApp).
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    assert(_prefs != null, 'StorageService.init() must be called before use');
    return _prefs!;
  }

  // ── Tokens ─────────────────────────────────────────────────────────────────

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _p.setString(AppConfig.kAccessToken,  accessToken);
    await _p.setString(AppConfig.kRefreshToken, refreshToken);
  }

  String? get accessToken  => _p.getString(AppConfig.kAccessToken);
  String? get refreshToken => _p.getString(AppConfig.kRefreshToken);
  bool   get hasToken      => accessToken != null && accessToken!.isNotEmpty;

  // ── User basics (for offline display before API returns) ──────────────────

  Future<void> saveUserInfo({
    required int    id,
    required String phone,
    required String name,
  }) async {
    await _p.setInt(   AppConfig.kUserId,    id);
    await _p.setString(AppConfig.kUserPhone, phone);
    await _p.setString(AppConfig.kUserName,  name);
  }

  int?    get userId    => _p.getInt(AppConfig.kUserId);
  String? get userPhone => _p.getString(AppConfig.kUserPhone);
  String? get userName  => _p.getString(AppConfig.kUserName);

  // ── Clear (logout) ────────────────────────────────────────────────────────

  Future<void> clearAll() async => _p.clear();
}