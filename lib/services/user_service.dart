import 'package:dio/dio.dart';
import '../core/api_client.dart';

// ── AddressItem — used for localities, areas, buildings ───────────────────────

class AddressItem {
  final int    id;
  final String name;
  const AddressItem({required this.id, required this.name});

  factory AddressItem.fromJson(Map<String, dynamic> j) => AddressItem(
    id:   (j['id']   as num?)?.toInt() ?? 0,
    name:  j['name'] as String? ?? '',
  );

  static const empty = AddressItem(id: 0, name: '');
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
  final bool    availabilityConfirmed;

  // CRM address hierarchy (from customers table)
  final int?    localityId;
  final int?    areaId;
  final int?    buildingId;
  final String  localityName;
  final String  areaName;
  final String  buildingName;
  final String  flatNo;      // house / flat number
  final String  pinCode;

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
    this.availabilityConfirmed = false,
    this.localityId,
    this.areaId,
    this.buildingId,
    this.localityName    = '',
    this.areaName        = '',
    this.buildingName    = '',
    this.flatNo          = '',
    this.pinCode         = '',
  });

  factory FullProfile.fromJson(Map<String, dynamic> j) {
    final rawId  = j['id'];
    final id     = rawId is num ? rawId.toInt() : int.tryParse(rawId?.toString() ?? '') ?? 0;

    final rawBal = j['wallet_balance'];
    final bal    = rawBal is num ? rawBal.toDouble() : double.tryParse(rawBal?.toString() ?? '') ?? 0.0;

    int? toInt(dynamic v) => v == null ? null : (v is num ? v.toInt() : int.tryParse(v.toString()));

    return FullProfile(
      id:                     id,
      name:                   j['name']           as String? ?? '',
      phone:                  j['phone']          as String? ?? '',
      email:                  j['email']          as String? ?? '',
      walletBalance:          bal,
      profileImageUrl:        j['profile_image']  as String?,
      kycStatus:              j['kyc_status']     as String? ?? 'not_submitted',
      referralCode:           j['referral_code']  as String?,
      referralUrl:            j['referral_url']   as String?,
      availabilityConfirmed:  j['availability_confirmed'] as bool? ?? false,
      // CRM address hierarchy
      localityId:   toInt(j['locality_id']),
      areaId:       toInt(j['area_id']),
      buildingId:   toInt(j['building_id']),
      localityName: j['locality_name'] as String? ?? '',
      areaName:     j['area_name']     as String? ?? '',
      buildingName: j['building_name'] as String? ?? '',
      flatNo:       j['flat_no']       as String? ?? '',
      pinCode:      j['crm_pin_code']  as String? ?? (j['pin_code'] as String? ?? ''),
    );
  }

  FullProfile copyWith({
    String?  name,
    String?  email,
    String?  profileImageUrl,
    int?     localityId,
    String?  localityName,
    int?     areaId,
    String?  areaName,
    int?     buildingId,
    String?  buildingName,
    String?  flatNo,
    String?  pinCode,
  }) => FullProfile(
    id:                    id,
    name:                  name            ?? this.name,
    phone:                 phone,
    email:                 email           ?? this.email,
    walletBalance:         walletBalance,
    profileImageUrl:       profileImageUrl ?? this.profileImageUrl,
    kycStatus:             kycStatus,
    referralCode:          referralCode,
    referralUrl:           referralUrl,
    availabilityConfirmed: availabilityConfirmed,
    localityId:            localityId   ?? this.localityId,
    areaId:                areaId       ?? this.areaId,
    buildingId:            buildingId   ?? this.buildingId,
    localityName:          localityName ?? this.localityName,
    areaName:              areaName     ?? this.areaName,
    buildingName:          buildingName ?? this.buildingName,
    flatNo:                flatNo       ?? this.flatNo,
    pinCode:               pinCode      ?? this.pinCode,
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
  Future<FullProfile?> getProfile() async {
    try {
      final res = await _api.get('/user/profile');
      final profileJson = res.data['data']?['profile'] as Map<String, dynamic>?;
      if (profileJson == null) return null;
      return FullProfile.fromJson(profileJson);
    } catch (_) {
      return null;
    }
  }

  // GET /address/localities  — tenant-scoped, public endpoint
  Future<List<AddressItem>> getLocalities() async {
    try {
      final res  = await _api.get('/address/localities');
      final list = res.data['data']?['localities'] as List? ?? [];
      return list.map((e) => AddressItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // GET /address/areas?locality_id=X
  Future<List<AddressItem>> getAreas(int localityId) async {
    try {
      final res  = await _api.get('/address/areas', params: {'locality_id': localityId});
      final list = res.data['data']?['areas'] as List? ?? [];
      return list.map((e) => AddressItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // GET /address/buildings?area_id=X
  Future<List<AddressItem>> getBuildings(int areaId) async {
    try {
      final res  = await _api.get('/address/buildings', params: {'area_id': areaId});
      final list = res.data['data']?['buildings'] as List? ?? [];
      return list.map((e) => AddressItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // PUT /user/profile
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

  // PUT /user/addresses/primary
  // Now sends CRM address hierarchy IDs instead of free-text state/city.
  Future<UserResult> updatePrimaryAddress({
    required int?   localityId,
    required int?   areaId,
    required int?   buildingId,
    required String flatNo,
    required String pinCode,
  }) async {
    try {
      await _api.put('/user/addresses/primary', data: {
        if (localityId != null) 'locality_id': localityId,
        if (areaId     != null) 'area_id':     areaId,
        if (buildingId != null) 'building_id': buildingId,
        'flat_no': flatNo,
        'pin_code':  pinCode,
      });
      return const UserResult(success: true);
    } on DioException catch (e) {
      return UserResult(success: false, error: ApiException.fromDio(e).message);
    } catch (e) {
      return UserResult(success: false, error: e.toString());
    }
  }
}