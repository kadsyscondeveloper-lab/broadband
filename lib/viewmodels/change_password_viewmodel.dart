// lib/viewmodels/change_password_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import 'package:dio/dio.dart';

enum ChangePasswordStatus { idle, loading, success, error }

class ChangePasswordViewModel extends ChangeNotifier {
  final ApiClient _api;

  ChangePasswordViewModel({ApiClient? api})
      : _api = api ?? ApiClient();

  // ── State ─────────────────────────────────────────────────────────────────

  ChangePasswordStatus _status = ChangePasswordStatus.idle;
  String? _errorMessage;
  bool    _isOldPasswordVisible     = false;
  bool    _isNewPasswordVisible     = false;
  bool    _isConfirmPasswordVisible = false;

  // Validation flags shown as checklist
  bool _oldPasswordFilled = false;
  bool _hasMinLength      = false;
  bool _hasSymbolOrNumber = false;
  bool _passwordsMatch    = false;

  String _oldPassword     = '';
  String _newPassword     = '';
  String _confirmPassword = '';

  // ── Getters ───────────────────────────────────────────────────────────────

  ChangePasswordStatus get status                   => _status;
  String?              get errorMessage             => _errorMessage;
  bool                 get isLoading                => _status == ChangePasswordStatus.loading;
  bool                 get isOldPasswordVisible     => _isOldPasswordVisible;
  bool                 get isNewPasswordVisible     => _isNewPasswordVisible;
  bool                 get isConfirmPasswordVisible => _isConfirmPasswordVisible;

  bool get oldPasswordFilled => _oldPasswordFilled;
  bool get hasMinLength      => _hasMinLength;
  bool get hasSymbolOrNumber => _hasSymbolOrNumber;
  bool get passwordsMatch    => _passwordsMatch;

  bool get canSubmit =>
      _oldPasswordFilled && _hasMinLength && _hasSymbolOrNumber && _passwordsMatch;

  // ── Field setters ─────────────────────────────────────────────────────────

  void setOldPassword(String v) {
    _oldPassword       = v;
    _oldPasswordFilled = v.isNotEmpty;
    _clearError();
    notifyListeners();
  }

  void setNewPassword(String v) {
    _newPassword       = v;
    _hasMinLength      = v.length >= 8;
    _hasSymbolOrNumber = RegExp(r'[0-9!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;`~/]').hasMatch(v);
    _passwordsMatch    = v.isNotEmpty && v == _confirmPassword;
    _clearError();
    notifyListeners();
  }

  void setConfirmPassword(String v) {
    _confirmPassword = v;
    _passwordsMatch  = v.isNotEmpty && v == _newPassword;
    _clearError();
    notifyListeners();
  }

  // ── Visibility toggles ────────────────────────────────────────────────────

  void toggleOldPasswordVisibility() {
    _isOldPasswordVisible = !_isOldPasswordVisible;
    notifyListeners();
  }

  void toggleNewPasswordVisibility() {
    _isNewPasswordVisible = !_isNewPasswordVisible;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    notifyListeners();
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  /// Calls POST /auth/change-password with the bearer token already attached
  /// by ApiClient's _AuthInterceptor — no OTP needed since user is logged in.
  Future<bool> changePassword() async {
    if (!canSubmit) return false;

    _status       = ChangePasswordStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _api.post('/auth/change-password', data: {
        'old_password': _oldPassword,
        'new_password': _newPassword,
      });

      _status = ChangePasswordStatus.success;
      notifyListeners();
      return true;

    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?
          ?? e.message
          ?? 'Something went wrong.';

      _errorMessage = (e.response?.statusCode == 401)
          ? 'Old password is incorrect.'
          : msg;

      _status = ChangePasswordStatus.error;
      notifyListeners();
      return false;

    } catch (e) {
      _errorMessage = e.toString();
      _status       = ChangePasswordStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _clearError() {
    if (_errorMessage != null || _status == ChangePasswordStatus.error) {
      _errorMessage = null;
      _status       = ChangePasswordStatus.idle;
    }
  }

  void resetState() {
    _status                   = ChangePasswordStatus.idle;
    _errorMessage             = null;
    _isOldPasswordVisible     = false;
    _isNewPasswordVisible     = false;
    _isConfirmPasswordVisible = false;
    _oldPasswordFilled        = false;
    _hasMinLength             = false;
    _hasSymbolOrNumber        = false;
    _passwordsMatch           = false;
    _oldPassword              = '';
    _newPassword              = '';
    _confirmPassword          = '';
    notifyListeners();
  }
}