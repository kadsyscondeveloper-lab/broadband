// lib/models/auth_models.dart

class AuthTokens {
  final String accessToken;
  final String refreshToken;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken:  json['access_token']  as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
    );
  }
}

class AuthUser {
  final int     id;
  final String  name;
  final String  phone;
  final String? email;
  final double  walletBalance;
  final String? referralCode;
  // ── ADDED: coupon generated when this user signed up via a referral link ──
  final String? referralCoupon;

  const AuthUser({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.walletBalance,
    this.referralCode,
    this.referralCoupon,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is num
        ? rawId.toInt()
        : int.tryParse(rawId?.toString() ?? '') ?? 0;

    return AuthUser(
      id:             id,
      name:           json['name']             as String? ?? '',
      phone:          json['phone']            as String? ?? '',
      email:          json['email']            as String?,
      walletBalance:  (json['wallet_balance']  ?? 0).toDouble(),
      referralCode:   json['referral_code']    as String?,
      referralCoupon: json['referral_coupon']  as String?, // ← ADDED
    );
  }
}

class AuthData {
  final AuthUser   user;
  final AuthTokens tokens;

  const AuthData({
    required this.user,
    required this.tokens,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      user:   AuthUser.fromJson(
          (json['user'] as Map<String, dynamic>?) ?? {}),
      tokens: AuthTokens.fromJson(
          (json['tokens'] as Map<String, dynamic>?) ?? {}),
    );
  }
}