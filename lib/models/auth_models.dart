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

  const AuthUser({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    // Backend returns id as String ("2") — handle both String and num safely
    final rawId = json['id'];
    final id = rawId is num
        ? rawId.toInt()
        : int.tryParse(rawId?.toString() ?? '') ?? 0;

    return AuthUser(
      id:    id,
      name:  json['name']  as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
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