import 'dart:async';

/// Simulated response from the auth backend.
class AuthResult {
  final bool success;
  final String? token;
  final String? error;

  const AuthResult({required this.success, this.token, this.error});
}

/// Data layer — handles all authentication API calls.
/// Replace the `Future.delayed` stubs with real HTTP calls (e.g. dio / http).
class AuthService {
  // Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Simulated valid credentials for demo
  static const _demoPhone = '9999999999';
  static const _demoPassword = 'speedonet123';
  static const _demoOtp = '123456';

  String? _sessionToken;
  String? get sessionToken => _sessionToken;
  bool get isLoggedIn => _sessionToken != null;

  /// Login with mobile number + password.
  Future<AuthResult> loginWithPassword({
    required String phone,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1200));

    if (phone.isEmpty || phone.length < 10) {
      return const AuthResult(
          success: false, error: 'Please enter a valid 10-digit mobile number.');
    }
    if (password.length < 6) {
      return const AuthResult(
          success: false, error: 'Password must be at least 6 characters.');
    }

    // Demo check — replace with real API call
    if (phone == _demoPhone && password == _demoPassword) {
      _sessionToken = 'tok_${DateTime.now().millisecondsSinceEpoch}';
      return AuthResult(success: true, token: _sessionToken);
    }

    return const AuthResult(
        success: false, error: 'Invalid mobile number or password.');
  }

  /// Send OTP to the given phone number.
  Future<AuthResult> sendOtp({required String phone}) async {
    await Future.delayed(const Duration(milliseconds: 900));

    if (phone.isEmpty || phone.length < 10) {
      return const AuthResult(
          success: false, error: 'Please enter a valid 10-digit mobile number.');
    }

    // In production, trigger an SMS OTP here.
    return const AuthResult(success: true);
  }

  /// Verify OTP and log the user in.
  Future<AuthResult> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    if (otp.length != 6) {
      return const AuthResult(
          success: false, error: 'Please enter the 6-digit OTP.');
    }

    if (otp == _demoOtp) {
      _sessionToken = 'tok_${DateTime.now().millisecondsSinceEpoch}';
      return AuthResult(success: true, token: _sessionToken);
    }

    return const AuthResult(success: false, error: 'Incorrect OTP. Try again.');
  }

  /// Send password reset link / OTP to phone.
  Future<AuthResult> forgotPassword({required String phone}) async {
    await Future.delayed(const Duration(milliseconds: 900));

    if (phone.isEmpty || phone.length < 10) {
      return const AuthResult(
          success: false, error: 'Please enter a valid 10-digit mobile number.');
    }

    return const AuthResult(success: true);
  }

  /// Log out the current session.
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _sessionToken = null;
  }
}