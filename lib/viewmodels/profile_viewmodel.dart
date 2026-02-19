import 'package:flutter/foundation.dart';
import '../services/user_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final _service = UserService();

  FullProfile? _profile;
  bool   _isLoading   = false;
  bool   _isUpdating  = false;
  String? _loadError;
  String? _updateError;
  bool   _updateSuccess = false;

  // ── Getters ───────────────────────────────────────────────────────────────

  FullProfile? get profile      => _profile;
  bool         get isLoading    => _isLoading;
  bool         get isUpdating   => _isUpdating;
  String?      get loadError    => _loadError;
  String?      get updateError  => _updateError;
  bool         get updateSuccess => _updateSuccess;

  // Convenience getters used directly in the UI
  String get name          => _profile?.name          ?? '';
  String get phone         => _profile?.phone         ?? '';
  String get email         => _profile?.email         ?? '';
  String get state         => _profile?.address.state   ?? '';
  String get city          => _profile?.address.city    ?? '';
  String get houseNo       => _profile?.address.houseNo ?? '';
  String get address       => _profile?.address.address ?? '';
  String get pinCode       => _profile?.address.pinCode ?? '';
  double get walletBalance => _profile?.walletBalance ?? 0.0;
  String get kycStatus     => _profile?.kycStatus     ?? 'not_submitted';

  final List<String> states = [
    'Andhra Pradesh', 'Assam', 'Bihar', 'Delhi', 'Gujarat',
    'Haryana', 'Karnataka', 'Kerala', 'Madhya Pradesh',
    'Maharashtra', 'Punjab', 'Rajasthan', 'Tamil Nadu',
    'Telangana', 'Uttar Pradesh', 'West Bengal',
  ];

  final List<String> cities = [
    'Ahmedabad', 'Bangalore', 'Bawana', 'Chennai', 'Delhi',
    'Dwarka', 'Gurgaon', 'Hyderabad', 'Jaipur', 'Kolkata',
    'Lajpat Nagar', 'Lucknow', 'Mumbai', 'Noida', 'Pune',
    'Rohini', 'Saket', 'Surat',
  ];

  // ── Load profile from API ─────────────────────────────────────────────────

  Future<void> loadProfile() async {
    _isLoading  = true;
    _loadError  = null;
    notifyListeners();

    _profile = await _service.getProfile();
    if (_profile == null) {
      _loadError = 'Failed to load profile. Please try again.';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Local field updates (before hitting save) ─────────────────────────────

  void updateName(String v)    { _profile = _profile?.copyWith(name: v);    notifyListeners(); }
  void updateEmail(String v)   { _profile = _profile?.copyWith(email: v);   notifyListeners(); }
  void updateState(String v)   {
    _profile = _profile?.copyWith(address: ProfileAddress(
      houseNo: houseNo, address: address, city: city, state: v, pinCode: pinCode,
    ));
    notifyListeners();
  }
  void updateCity(String v)    {
    _profile = _profile?.copyWith(address: ProfileAddress(
      houseNo: houseNo, address: address, city: v, state: state, pinCode: pinCode,
    ));
    notifyListeners();
  }
  void updateHouseNo(String v) {
    _profile = _profile?.copyWith(address: ProfileAddress(
      houseNo: v, address: address, city: city, state: state, pinCode: pinCode,
    ));
    notifyListeners();
  }
  void updateAddress(String v) {
    _profile = _profile?.copyWith(address: ProfileAddress(
      houseNo: houseNo, address: v, city: city, state: state, pinCode: pinCode,
    ));
    notifyListeners();
  }
  void updatePinCode(String v) {
    _profile = _profile?.copyWith(address: ProfileAddress(
      houseNo: houseNo, address: address, city: city, state: state, pinCode: v,
    ));
    notifyListeners();
  }

  // ── Save to API ───────────────────────────────────────────────────────────

  Future<void> updateProfile() async {
    if (_profile == null) return;
    _isUpdating   = true;
    _updateError  = null;
    _updateSuccess = false;
    notifyListeners();

    // Run both calls concurrently
    final results = await Future.wait([
      _service.updateProfile(name: name, email: email),
      _service.updatePrimaryAddress(
        houseNo:  houseNo,
        address:  address,
        city:     city,
        state:    state,
        pinCode:  pinCode,
      ),
    ]);

    final failed = results.where((r) => !r.success).toList();
    if (failed.isEmpty) {
      _updateSuccess = true;
    } else {
      _updateError = failed.map((r) => r.error).join(', ');
    }

    _isUpdating = false;
    notifyListeners();
  }

  void resetUpdateState() {
    _updateSuccess = false;
    _updateError   = null;
    notifyListeners();
  }
}