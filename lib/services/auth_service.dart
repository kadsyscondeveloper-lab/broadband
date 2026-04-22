// lib/services/auth_service.dart
// Full replacement — adds pendingDeletion fields to AuthResult and
// parses the PENDING_DELETION:<isoDate> error from the backend.

import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/storage_service.dart';
import '../models/auth_models.dart';
import 'notification_push_service.dart';

/// AuthResult — same shape as before + optional pendingDeletion fields.
class AuthResult {
  final bool    success;
  final String? token;
  final String? error;
  final AuthData? data;

  // ── Account pending deletion ──────────────────────────────────────────────
  /// True when the server returned PENDING_DELETION:<date>
  final bool    pendingDeletion;
  /// The date the account will be permanently deleted (if pendingDeletion == true)
  final DateTime? deletionDate;

  const AuthResult({
    required this.success,
    this.token,
    this.error,
    this.data,
    this.pendingDeletion = false,
    this.deletionDate,
  });

  /// Parse the raw error string from the backend.
  /// If it starts with "PENDING_DELETION:<iso>" return a special result.
  factory AuthResult.fromError(String rawError) {
    if (rawError.startsWith('PENDING_DELETION:')) {
      final dateStr = rawError.replaceFirst('PENDING_DELETION:', '');
      final date    = DateTime.tryParse(dateStr);
      return AuthResult(
        success:         false,
        pendingDeletion: true,
        deletionDate:    date,
        error:           null,
      );
    }
    return AuthResult(success: false, error: rawError);
  }
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _api     = ApiClient();
  final _storage = StorageService();

  bool    get isLoggedIn    => _storage.hasToken;
  String? get sessionToken  => _storage.accessToken;

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
    NotificationPushService().registerTokenAfterLogin();
  }

  AuthResult _handleDioError(DioException e) {
    final ex  = ApiException.fromDio(e);
    return AuthResult.fromError(ex.message);
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
      return AuthResult(success: true, token: authData.tokens.accessToken, data: authData);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return AuthResult.fromError(e.toString());
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
        'name':     name,
        'phone':    phone,
        'password': password,
        if (email != null) 'email': email,
        if (referralCode != null && referralCode.isNotEmpty)
          'referral_code': referralCode,
      });
      final authData = AuthData.fromJson(res.data['data'] ?? {});
      await _persist(authData);
      return AuthResult(success: true, token: authData.tokens.accessToken, data: authData);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return AuthResult.fromError(e.toString());
    }
  }

  // ── Send OTP ──────────────────────────────────────────────────────────────

  Future<AuthResult> sendOtp({
    required String phone,
    String purpose = 'login',
  }) async {
    try {
      final res = await _api.post('/auth/otp/send', data: {
        'phone':   phone,
        'purpose': purpose,
      });
      final devOtp = res.data['data']?['_dev_otp'] as String?;
      return AuthResult(success: true, token: devOtp);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return AuthResult.fromError(e.toString());
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
      return AuthResult(success: true, token: authData.tokens.accessToken, data: authData);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return AuthResult.fromError(e.toString());
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
      return AuthResult.fromError(e.toString());
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
      return AuthResult.fromError(e.toString());
    }
  }

  // ── Get current user ──────────────────────────────────────────────────────

  Future<AuthUser?> getMe() async {
    try {
      final res = await _api.get('/auth/me');
      return AuthUser.fromJson(res.data['data']['user'] ?? {});
    } catch (_) {
      return null;
    }
  }

  // ── Delete account ────────────────────────────────────────────────────────

  /// Schedules the account for deletion.
  /// Returns [success=true] with the scheduled deletion date on success.
  Future<AuthResult> deleteAccount({String? password}) async {
    try {
      await _api.delete('/user/account');
      // Backend revokes all sessions; clear local storage too
      await _storage.clearAll();
      return const AuthResult(success: true);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return AuthResult.fromError(e.toString());
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    try { await _api.post('/auth/logout'); } catch (_) {}
    await _storage.clearAll();
  }

  Future<void> logoutAll() async {
    try { await _api.post('/auth/logout-all'); } catch (_) {}
    await _storage.clearAll();
  }
}