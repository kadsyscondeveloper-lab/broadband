import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/storage_service.dart';
import '../models/auth_models.dart';

/// AuthResult — same shape as your old stub so ViewModels need zero changes.
class AuthResult {
  final bool    success;
  final String? token;   // kept for backward compat (access token)
  final String? error;
  final AuthData? data;

  const AuthResult({
    required this.success,
    this.token,
    this.error,
    this.data,
  });
}

/// AuthService — real HTTP calls to your Node.js backend.
/// ViewModels call the same method names as before — no ViewModel changes needed.
class AuthService {
  // Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _api     = ApiClient();
  final _storage = StorageService();

  bool get isLoggedIn => _storage.hasToken;
  String? get sessionToken => _storage.accessToken;

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Saves tokens + user info to storage after a successful auth response.
  Future<void> _persist(AuthData authData) async {
    await _storage.saveTokens(
      accessToken:  authData.tokens.accessToken,
      refreshToken: authData.tokens.refreshToken,
    );
    await _storage.saveUserInfo(
      id:    authData.user.id,
      phone: authData.user.phone,
      name:  authData.user.name,
    );
  }

  AuthResult _handleDioError(DioException e) {
    final ex = ApiException.fromDio(e);
    return AuthResult(success: false, error: ex.message);
  }

  // ── Login with password ───────────────────────────────────────────────────

  Future<AuthResult> loginWithPassword({
    required String phone,
    required String password,
  }) async {
    try {
      final res = await _api.post('/auth/login', data: {
        'phone':    phone,
        'password': password,
      });

      final authData = AuthData.fromJson(res.data['data'] ?? {});
      await _persist(authData);

      return AuthResult(
        success: true,
        token:   authData.tokens.accessToken,
        data:    authData,
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  // ── Signup ────────────────────────────────────────────────────────────────

  Future<AuthResult> signup({
    required String name,
    required String phone,
    required String password,
    String? email,
    String? referralCode,
  }) async {
    try {
      final res = await _api.post('/auth/signup', data: {
        'name':          name,
        'phone':         phone,
        'password':      password,
        if (email != null) 'email': email,
        if (referralCode != null && referralCode.isNotEmpty)
          'referral_code': referralCode,
      });

      final authData = AuthData.fromJson(res.data['data'] ?? {});
      await _persist(authData);

      return AuthResult(
        success: true,
        token:   authData.tokens.accessToken,
        data:    authData,
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  // ── Send OTP ─────────────────────────────────────────────────────────────

  Future<AuthResult> sendOtp({
    required String phone,
    String purpose = 'login',
  }) async {
    try {
      final res = await _api.post('/auth/otp/send', data: {
        'phone':   phone,
        'purpose': purpose,
      });

      // Surface the dev OTP in the result so the ViewModel can show it
      final devOtp = res.data['data']?['_dev_otp'] as String?;
      return AuthResult(
        success: true,
        token:   devOtp, // reusing 'token' field to pass dev OTP (ViewModel shows it)
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  // ── Verify OTP ────────────────────────────────────────────────────────────

  Future<AuthResult> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final res = await _api.post('/auth/otp/verify', data: {
        'phone': phone,
        'otp':   otp,
      });

      final authData = AuthData.fromJson(res.data['data'] ?? {});
      await _persist(authData);

      return AuthResult(
        success: true,
        token:   authData.tokens.accessToken,
        data:    authData,
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  // ── Forgot password ───────────────────────────────────────────────────────

  Future<AuthResult> forgotPassword({required String phone}) async {
    try {
      await _api.post('/auth/forgot-password', data: {'phone': phone});
      return const AuthResult(success: true);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  // ── Reset password ────────────────────────────────────────────────────────

  Future<AuthResult> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await _api.post('/auth/reset-password', data: {
        'phone':        phone,
        'otp':          otp,
        'new_password': newPassword,
      });
      return const AuthResult(success: true);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  // ── Get current user (me) ─────────────────────────────────────────────────

  Future<AuthUser?> getMe() async {
    try {
      final res = await _api.get('/auth/me');
      return AuthUser.fromJson(res.data['data']['user'] ?? {});
    } catch (_) {
      return null;
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {
      // Even if server call fails, clear local storage
    }
    await _storage.clearAll();
  }

  Future<void> logoutAll() async {
    try {
      await _api.post('/auth/logout-all');
    } catch (_) {}
    await _storage.clearAll();
  }
}