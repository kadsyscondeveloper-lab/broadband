// lib/viewmodels/signup_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

enum SignupStatus { idle, loading, success, error }

class SignupViewModel extends ChangeNotifier {
  final AuthService _service;

  SignupViewModel({AuthService? service})
      : _service = service ?? AuthService();

  // ── State ─────────────────────────────────────────────────────────────────

  SignupStatus _status           = SignupStatus.idle;
  String?      _errorMessage;
  bool         _isPasswordVisible        = false;
  bool         _isConfirmPasswordVisible = false;
  bool         _agreedToTerms            = false;

  String _name         = '';
  String _phone        = '';
  String _password     = '';
  String _confirmPassword = '';
  String _referralCode = '';

  // ── Getters ───────────────────────────────────────────────────────────────

  SignupStatus get status                  => _status;
  String?      get errorMessage           => _errorMessage;
  bool         get isLoading              => _status == SignupStatus.loading;
  bool         get isPasswordVisible      => _isPasswordVisible;
  bool         get isConfirmPasswordVisible => _isConfirmPasswordVisible;
  bool         get agreedToTerms          => _agreedToTerms;

  // ── Field setters ─────────────────────────────────────────────────────────

  void setName(String v)            { _name            = v.trim(); _clearError(); }
  void setPhone(String v)           { _phone           = v.trim(); _clearError(); }
  void setPassword(String v)        { _password        = v;        _clearError(); }
  void setConfirmPassword(String v) { _confirmPassword = v;        _clearError(); }
  void setReferralCode(String v)    { _referralCode    = v.trim(); }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    notifyListeners();
  }

  void toggleAgreedToTerms() {
    _agreedToTerms = !_agreedToTerms;
    notifyListeners();
  }

  // ── Validation ────────────────────────────────────────────────────────────

  String? validate() {
    if (_name.isEmpty)                        return 'Please enter your full name';
    if (_phone.length != 10)                  return 'Please enter a valid 10-digit mobile number';
    if (_password.length < 6)                 return 'Password must be at least 6 characters';
    if (_password != _confirmPassword)        return 'Passwords do not match';
    if (!_agreedToTerms)                      return 'Please agree to the Terms & Conditions';
    return null;
  }

  // ── Signup ────────────────────────────────────────────────────────────────

  Future<bool> signup() async {
    final validationError = validate();
    if (validationError != null) {
      _status       = SignupStatus.error;
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    _status       = SignupStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _service.signup(
      name:         _name,
      phone:        _phone,
      password:     _password,
      referralCode: _referralCode.isNotEmpty ? _referralCode : null,
    );

    if (result.success) {
      _status = SignupStatus.success;
      notifyListeners();
      return true;
    } else {
      _status       = SignupStatus.error;
      _errorMessage = result.error;
      notifyListeners();
      return false;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _clearError() {
    if (_errorMessage != null || _status == SignupStatus.error) {
      _errorMessage = null;
      _status       = SignupStatus.idle;
      notifyListeners();
    }
  }

  void resetState() {
    _status                  = SignupStatus.idle;
    _errorMessage            = null;
    _agreedToTerms           = false;
    _isPasswordVisible       = false;
    _isConfirmPasswordVisible = false;
    notifyListeners();
  }
}