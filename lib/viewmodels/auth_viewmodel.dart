import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

enum AuthMode { password, otp }
enum AuthStatus { idle, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  final AuthService _service;

  AuthViewModel({AuthService? service})
      : _service = service ?? AuthService();

  // ── State ────────────────────────────────────────────────────────────────

  AuthMode _mode = AuthMode.password;
  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;
  bool _isPasswordVisible = false;
  bool _otpSent = false;

  // Form field values (set from the View)
  String _phone = '';
  String _password = '';
  String _otp = '';

  // ── Getters ──────────────────────────────────────────────────────────────

  AuthMode get mode => _mode;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get otpSent => _otpSent;
  String get phone => _phone;

  // ── Setters (called by TextFields) ───────────────────────────────────────

  void setPhone(String value) {
    _phone = value.trim();
    _clearError();
  }

  void setPassword(String value) {
    _password = value;
    _clearError();
  }

  void setOtp(String value) {
    _otp = value.trim();
    _clearError();
  }

  // ── UI actions ───────────────────────────────────────────────────────────

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void switchMode(AuthMode mode) {
    _mode = mode;
    _otpSent = false;
    _errorMessage = null;
    _status = AuthStatus.idle;
    notifyListeners();
  }

  // ── Auth actions ─────────────────────────────────────────────────────────

  /// Primary login with password.
  Future<bool> loginWithPassword() async {
    _setLoading();
    final result = await _service.loginWithPassword(
      phone: _phone,
      password: _password,
    );
    return _handleResult(result);
  }

  /// Step 1 of OTP flow — request OTP.
  Future<void> requestOtp() async {
    _setLoading();
    final result = await _service.sendOtp(phone: _phone);
    if (result.success) {
      _otpSent = true;
      _status = AuthStatus.idle;
    } else {
      _status = AuthStatus.error;
      _errorMessage = result.error;
    }
    notifyListeners();
  }

  /// Step 2 of OTP flow — verify OTP.
  Future<bool> verifyOtp() async {
    _setLoading();
    final result = await _service.verifyOtp(phone: _phone, otp: _otp);
    return _handleResult(result);
  }

  /// Forgot password flow.
  Future<bool> forgotPassword() async {
    _setLoading();
    final result = await _service.forgotPassword(phone: _phone);
    return _handleResult(result);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  bool _handleResult(AuthResult result) {
    if (result.success) {
      _status = AuthStatus.success;
      notifyListeners();
      return true;
    } else {
      _status = AuthStatus.error;
      _errorMessage = result.error;
      notifyListeners();
      return false;
    }
  }

  void _clearError() {
    if (_errorMessage != null || _status == AuthStatus.error) {
      _errorMessage = null;
      _status = AuthStatus.idle;
      notifyListeners();
    }
  }

  void resetState() {
    _status = AuthStatus.idle;
    _errorMessage = null;
    _otpSent = false;
    notifyListeners();
  }
}