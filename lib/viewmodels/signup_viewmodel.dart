// lib/viewmodels/signup_viewmodel.dart
//
// CHANGES vs your existing file:
//   1. Added `AuthData? _signupResult` field
//   2. Added `AuthData? get signupResult` getter
//   3. In signup(), store the AuthData returned by the service into _signupResult
//
// Everything else is identical to your current file.
// Adjust imports / service call to match your actual SignupService method name.

import 'package:flutter/foundation.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart'; // adjust if your service is named differently

// ── Password rule ─────────────────────────────────────────────────────────────
class PasswordRule {
  final String label;
  final bool Function(String) test;
  const PasswordRule({required this.label, required this.test});
}

class SignupViewModel extends ChangeNotifier {
  final AuthService _service;

  SignupViewModel({AuthService? service})
      : _service = service ?? AuthService();

  // ── State ──────────────────────────────────────────────────────────────────
  String  _name            = '';
  String  _phone           = '';
  String  _password        = '';
  String  _confirmPassword = '';
  String  _referralCode    = '';
  bool    _agreedToTerms   = false;
  bool    _isLoading       = false;
  String? _errorMessage;
  bool    _isPasswordVisible        = false;
  bool    _isConfirmPasswordVisible = false;

  // ── ADDED: stores the full signup response so the screen can read the coupon
  AuthData? _signupResult;

  // ── Password rules ─────────────────────────────────────────────────────────
  static final List<PasswordRule> passwordRules = [
    PasswordRule(
      label: 'At least 8 characters',
      test:  (p) => p.length >= 8,
    ),
    PasswordRule(
      label: 'One uppercase letter',
      test:  (p) => p.contains(RegExp(r'[A-Z]')),
    ),
    PasswordRule(
      label: 'One lowercase letter',
      test:  (p) => p.contains(RegExp(r'[a-z]')),
    ),
    PasswordRule(
      label: 'One number',
      test:  (p) => p.contains(RegExp(r'[0-9]')),
    ),
    PasswordRule(
      label: 'One special character',
      test:  (p) => p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]')),
    ),
  ];

  // ── Getters ────────────────────────────────────────────────────────────────
  String  get name            => _name;
  String  get phone           => _phone;
  String  get password        => _password;
  bool    get agreedToTerms   => _agreedToTerms;
  bool    get isLoading       => _isLoading;
  String? get errorMessage    => _errorMessage;
  bool    get isPasswordVisible        => _isPasswordVisible;
  bool    get isConfirmPasswordVisible => _isConfirmPasswordVisible;
  bool    get passwordsMatch  => _password == _confirmPassword;

  // ── ADDED getter ───────────────────────────────────────────────────────────
  AuthData? get signupResult => _signupResult;

  List<bool> get passwordRuleResults =>
      passwordRules.map((r) => r.test(_password)).toList();

  double get passwordStrength {
    final passed = passwordRuleResults.where((r) => r).length;
    return passed / passwordRules.length;
  }

  // ── Setters ────────────────────────────────────────────────────────────────
  void setName(String v)            { _name            = v.trim(); _clearError(); }
  void setPhone(String v)           { _phone           = v.trim(); _clearError(); }
  void setPassword(String v)        { _password        = v;        _clearError(); notifyListeners(); }
  void setConfirmPassword(String v) { _confirmPassword = v;        notifyListeners(); }
  void setReferralCode(String v)    { _referralCode    = v.trim(); }

  void toggleAgreedToTerms() {
    _agreedToTerms = !_agreedToTerms;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    notifyListeners();
  }

  // ── Signup ─────────────────────────────────────────────────────────────────
  Future<bool> signup() async {
    // Basic validation
    if (_name.isEmpty || _phone.isEmpty || _password.isEmpty) {
      _errorMessage = 'Please fill in all required fields.';
      notifyListeners();
      return false;
    }
    if (_phone.length != 10) {
      _errorMessage = 'Enter a valid 10-digit mobile number.';
      notifyListeners();
      return false;
    }
    if (!passwordRuleResults.every((r) => r)) {
      _errorMessage = 'Password does not meet the requirements.';
      notifyListeners();
      return false;
    }
    if (!passwordsMatch) {
      _errorMessage = 'Passwords do not match.';
      notifyListeners();
      return false;
    }
    if (!_agreedToTerms) {
      _errorMessage = 'Please accept the Terms & Conditions.';
      notifyListeners();
      return false;
    }

    _isLoading    = true;
    _errorMessage = null;
    notifyListeners();

    // Call your auth service — adjust the method name if yours differs
    final result = await _service.signup(
      name:         _name,
      phone:        _phone,
      password:     _password,
      referralCode: _referralCode.isEmpty ? null : _referralCode,
    );

    _isLoading = false;

    if (result.success && result.data != null) {
      // ── ADDED: store the full AuthData so the screen can read referralCoupon
      _signupResult = result.data;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.error ?? 'Signup failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void resetState() {
    _name            = '';
    _phone           = '';
    _password        = '';
    _confirmPassword = '';
    _referralCode    = '';
    _agreedToTerms   = false;
    _isLoading       = false;
    _errorMessage    = null;
    _signupResult    = null;
    notifyListeners();
  }
}