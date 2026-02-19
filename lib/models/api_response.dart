/// Generic wrapper matching your backend's response shape:
/// { success, message, data?, meta?, errors? }
class ApiResponse<T> {
  final bool    success;
  final String  message;
  final T?      data;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ApiResponse.fromJson(
      Map<String, dynamic> json,
      T Function(dynamic)? fromData,
      ) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data:    json['data'] != null && fromData != null
          ? fromData(json['data'])
          : null,
    );
  }
}

// ── Auth-specific response models ─────────────────────────────────────────────

class AuthTokens {
  final String accessToken;
  final String refreshToken;

  const AuthTokens({required this.accessToken, required this.refreshToken});

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
    accessToken:  json['access_token']  ?? '',
    refreshToken: json['refresh_token'] ?? '',
  );
}

class AuthUser {
  final int    id;
  final String name;
  final String phone;
  final String? email;
  final double walletBalance;
  final String? referralCode;

  const AuthUser({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.walletBalance,
    this.referralCode,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id:            json['id']             ?? 0,
    name:          json['name']           ?? '',
    phone:         json['phone']          ?? '',
    email:         json['email'],
    walletBalance: (json['wallet_balance'] ?? 0).toDouble(),
    referralCode:  json['referral_code'],
  );
}

class AuthData {
  final AuthUser   user;
  final AuthTokens tokens;

  const AuthData({required this.user, required this.tokens});

  factory AuthData.fromJson(Map<String, dynamic> json) => AuthData(
    user:   AuthUser.fromJson(json['user']     ?? {}),
    tokens: AuthTokens.fromJson(json['tokens'] ?? {}),
  );
}

// ── OTP send response ─────────────────────────────────────────────────────────

class OtpSendData {
  final String  maskedPhone;
  final String  expiresIn;
  final String? devOtp; // only present in dev mode

  const OtpSendData({
    required this.maskedPhone,
    required this.expiresIn,
    this.devOtp,
  });

  factory OtpSendData.fromJson(Map<String, dynamic> json) => OtpSendData(
    maskedPhone: json['phone']      ?? '',
    expiresIn:   json['expires_in'] ?? '10 minutes',
    devOtp:      json['_dev_otp'],
  );
}