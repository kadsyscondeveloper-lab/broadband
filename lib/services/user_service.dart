import 'package:dio/dio.dart';
import '../core/api_client.dart';

// ── Address model ─────────────────────────────────────────────────────────────

class ProfileAddress {
  final String houseNo;
  final String address;
  final String city;
  final String state;
  final String pinCode;

  const ProfileAddress({
    this.houseNo = '',
    this.address = '',
    this.city    = '',
    this.state   = '',
    this.pinCode = '',
  });

  // Fields are FLAT on the profile object (not nested)
  factory ProfileAddress.fromFlatJson(Map<String, dynamic> j) => ProfileAddress(
    houseNo: j['house_no']  as String? ?? '',
    address: j['address']   as String? ?? '',
    city:    j['city']      as String? ?? '',
    state:   j['state']     as String? ?? '',
    pinCode: j['pin_code']  as String? ?? '',
  );
}

// ── Full profile model ────────────────────────────────────────────────────────

class FullProfile {
  final int     id;
  final String  name;
  final String  phone;
  final String  email;
  final double  walletBalance;
  final String? profileImageUrl;
  final String  kycStatus;
  final String? referralCode;
  final String? referralUrl;
  final ProfileAddress address;

  const FullProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.walletBalance   = 0.0,
    this.profileImageUrl,
    this.kycStatus       = 'not_submitted',
    this.referralCode,
    this.referralUrl,
    required this.address,
  });

  // API response: data.profile — all fields are FLAT (no nested address object)
  // Example: { "name": "...", "house_no": "...", "city": "...", "kyc_status": "pending" }
  factory FullProfile.fromJson(Map<String, dynamic> j) {
    final rawId = j['id'];
    final id = rawId is num
        ? rawId.toInt()
        : int.tryParse(rawId?.toString() ?? '') ?? 0;

    final rawBalance = j['wallet_balance'];
    final balance = rawBalance is num
        ? rawBalance.toDouble()
        : double.tryParse(rawBalance?.toString() ?? '') ?? 0.0;

    return FullProfile(
      id:              id,
      name:            j['name']          as String? ?? '',
      phone:           j['phone']         as String? ?? '',
      email:           j['email']         as String? ?? '',
      walletBalance:   balance,
      profileImageUrl: j['profile_image'] as String?,   // key is profile_image not profile_image_url
      kycStatus:       j['kyc_status']    as String? ?? 'not_submitted',
      referralCode:    j['referral_code'] as String?,
      referralUrl:     j['referral_url']  as String?,
      address:         ProfileAddress.fromFlatJson(j),  // flat — same object
    );
  }

  FullProfile copyWith({
    String?         name,
    String?         email,
    String?         profileImageUrl,
    ProfileAddress? address,
  }) => FullProfile(
    id:              id,
    name:            name            ?? this.name,
    phone:           phone,
    email:           email           ?? this.email,
    walletBalance:   walletBalance,
    profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    kycStatus:       kycStatus,
    referralCode:    referralCode,
    referralUrl:     referralUrl,
    address:         address         ?? this.address,
  );
}

// ── Result wrapper ────────────────────────────────────────────────────────────

class UserResult {
  final bool    success;
  final String? error;
  const UserResult({required this.success, this.error});
}

// ── Service ───────────────────────────────────────────────────────────────────

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final _api = ApiClient();

  // GET /user/profile
  // Response: { "data": { "profile": { ...flat fields... } } }
  Future<FullProfile?> getProfile() async {
    try {
      final res = await _api.get('/user/profile');
      // Unwrap: res.data['data']['profile']
      final profileJson = res.data['data']?['profile'] as Map<String, dynamic>?;
      if (profileJson == null) return null;
      return FullProfile.fromJson(profileJson);
    } catch (e) {
      return null;
    }
  }

  // PUT /user/profile — { name, email }
  Future<UserResult> updateProfile({
    required String name,
    required String email,
  }) async {
    try {
      await _api.put('/user/profile', data: {'name': name, 'email': email});
      return const UserResult(success: true);
    } on DioException catch (e) {
      return UserResult(success: false, error: ApiException.fromDio(e).message);
    } catch (e) {
      return UserResult(success: false, error: e.toString());
    }
  }

  // PUT /user/addresses/primary — { house_no, address, city, state, pin_code }
  Future<UserResult> updatePrimaryAddress({
    required String houseNo,
    required String address,
    required String city,
    required String state,
    required String pinCode,
  }) async {
    try {
      await _api.put('/user/addresses/primary', data: {
        'house_no': houseNo,
        'address':  address,
        'city':     city,
        'state':    state,
        'pin_code': pinCode,
      });
      return const UserResult(success: true);
    } on DioException catch (e) {
      return UserResult(success: false, error: ApiException.fromDio(e).message);
    } catch (e) {
      return UserResult(success: false, error: e.toString());
    }
  }
}