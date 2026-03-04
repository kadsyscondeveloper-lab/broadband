// lib/viewmodels/signup_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

enum SignupStatus { idle, loading, success, error }

/// A single password requirement — label shown in the UI, check run live.
class PasswordRule {
  final String label;
  final bool Function(String) check;
  const PasswordRule({required this.label, required this.check});
}

class SignupViewModel extends ChangeNotifier {
  final AuthService _service;

  SignupViewModel({AuthService? service})
      : _service = service ?? AuthService();

  // ── Password rules (static so the UI can reference them) ──────────────────

  static final List<PasswordRule> passwordRules = [
    PasswordRule(
      label: 'At least 8 characters',
      check: (p) => p.length >= 8,
    ),
    PasswordRule(
      label: 'One uppercase letter (A–Z)',
      check: (p) => p.contains(RegExp(r'[A-Z]')),
    ),
    PasswordRule(
      label: 'One lowercase letter (a–z)',
      check: (p) => p.contains(RegExp(r'[a-z]')),
    ),
    PasswordRule(
      label: 'One number (0–9)',
      check: (p) => p.contains(RegExp(r'[0-9]')),
    ),
    PasswordRule(
      label: r'One special character (!@#$...)',
      check: (p) => p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]')),
    ),
  ];

  // ── State ─────────────────────────────────────────────────────────────────

  SignupStatus _status                  = SignupStatus.idle;
  String?      _errorMessage;
  bool         _isPasswordVisible        = false;
  bool         _isConfirmPasswordVisible = false;
  bool         _agreedToTerms            = false;

  String _name            = '';
  String _phone           = '';
  String _password        = '';
  String _confirmPassword = '';
  String _referralCode    = '';

  // ── Getters ───────────────────────────────────────────────────────────────

  SignupStatus get status                   => _status;
  String?      get errorMessage            => _errorMessage;
  bool         get isLoading               => _status == SignupStatus.loading;
  bool         get isPasswordVisible       => _isPasswordVisible;
  bool         get isConfirmPasswordVisible => _isConfirmPasswordVisible;
  bool         get agreedToTerms           => _agreedToTerms;
  String       get password                => _password;
  String       get confirmPassword         => _confirmPassword;

  /// Pass/fail for each rule against the current password.
  List<bool> get passwordRuleResults =>
      passwordRules.map((r) => r.check(_password)).toList();

  /// 0.0–1.0 based on how many rules pass.
  double get passwordStrength => _password.isEmpty
      ? 0
      : passwordRuleResults.where((v) => v).length / passwordRules.length;

  bool get passwordsMatch =>
      _confirmPassword.isNotEmpty && _password == _confirmPassword;

  // ── Field setters ─────────────────────────────────────────────────────────

  void setName(String v)            { _name            = v.trim(); _clearError(); }
  void setPhone(String v)           { _phone           = v.trim(); _clearError(); }
  void setPassword(String v)        { _password        = v;        _clearError(); notifyListeners(); }
  void setConfirmPassword(String v) { _confirmPassword = v;        _clearError(); notifyListeners(); }
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

  /// Returns a specific, human-readable error or null if all valid.
  String? validate() {
    if (_name.isEmpty)       return 'Please enter your full name';
    if (_phone.length != 10) return 'Please enter a valid 10-digit mobile number';

    // Return the first failing rule as a clear actionable message
    for (final rule in passwordRules) {
      if (!rule.check(_password)) {
        return 'Password needs: ${rule.label}';
      }
    }

    if (_password != _confirmPassword) return 'Passwords do not match';
    if (!_agreedToTerms)               return 'Please agree to the Terms & Conditions';
    return null;
  }

  // ── Signup ────────────────────────────────────────────────────────────────

  Future<bool> signup() async {
    final err = validate();
    if (err != null) {
      _status       = SignupStatus.error;
      _errorMessage = err;
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
    _status                   = SignupStatus.idle;
    _errorMessage             = null;
    _agreedToTerms            = false;
    _isPasswordVisible        = false;
    _isConfirmPasswordVisible = false;
    notifyListeners();
  }
}