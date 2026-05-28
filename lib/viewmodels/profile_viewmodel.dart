import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../services/user_service.dart';
import '../services/profile_image_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final _service      = UserService();
  final _imageService = ProfileImageService();

  FullProfile? _profile;
  bool    _isLoading      = false;
  bool    _isUpdating     = false;
  String? _loadError;
  String? _updateError;
  bool    _updateSuccess  = false;

  // ── Image upload state ────────────────────────────────────────────────────
  String? _localImageBase64;
  bool    _imageUploading = false;
  String? _imageError;

  // ── Location state ────────────────────────────────────────────────────────
  List<AddressItem> _states        = [];
  List<AddressItem> _cities        = [];
  bool              _statesLoading = false;
  bool              _citiesLoading = false;
  String?           _locationsError;

  // ── Getters ───────────────────────────────────────────────────────────────

  FullProfile? get profile        => _profile;
  bool         get isLoading      => _isLoading;
  bool         get isUpdating     => _isUpdating;
  String?      get loadError      => _loadError;
  String?      get updateError    => _updateError;
  bool         get updateSuccess  => _updateSuccess;

  // Image
  String? get localImageBase64  => _localImageBase64;
  bool    get imageUploading    => _imageUploading;
  String? get imageError        => _imageError;

  // Locations
  List<AddressItem> get states         => _states;
  List<AddressItem> get cities         => _cities;
  bool              get statesLoading  => _statesLoading;
  bool              get citiesLoading  => _citiesLoading;
  String?           get locationsError => _locationsError;

  // Convenience getters
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
  String? get profileImageUrl => _profile?.profileImageUrl;

  // ── Load profile ──────────────────────────────────────────────────────────

  Future<void> loadProfile() async {
    _isLoading = true;
    _loadError = null;
    notifyListeners();

    _profile = await _service.getProfile();
    if (_profile == null) {
      _loadError = 'Failed to load profile. Please try again.';
    }

    _isLoading = false;
    notifyListeners();

    // Load states, then cities for the current state
    await loadStates();
    if (state.isNotEmpty) {
      final match = _states.firstWhere(
            (s) => s.name.toLowerCase() == state.toLowerCase(),
        orElse: () => const AddressItem(id: 0, name: ''),
      );
      if (match.id > 0) await loadCitiesForState(match.id);
    }
  }

  // ── Location loaders ──────────────────────────────────────────────────────

  Future<void> loadStates() async {
    if (_statesLoading) return;
    _statesLoading  = true;
    _locationsError = null;
    notifyListeners();

    try {
      _states = await _service.getStates();
    } catch (_) {
      _locationsError = 'Could not load states.';
    }

    _statesLoading = false;
    notifyListeners();
  }

  Future<void> loadCitiesForState(int stateId) async {
    if (_citiesLoading) return;
    _cities        = [];
    _citiesLoading = true;
    notifyListeners();

    try {
      _cities = await _service.getCities(stateId);
    } catch (_) {
      _locationsError = 'Could not load cities.';
    }

    _citiesLoading = false;
    notifyListeners();
  }

  // ── Profile image upload ──────────────────────────────────────────────────

  Future<void> pickAndUploadImage(ImageSource source) async {
    _imageUploading = true;
    _imageError     = null;
    notifyListeners();

    final result = await _imageService.pickAndUpload(source: source);

    if (result.success) {
      _localImageBase64 = result.imageBase64;
      loadProfile();
    } else if (result.error != null) {
      _imageError = result.error;
    }

    _imageUploading = false;
    notifyListeners();
  }

  void clearImageError() {
    _imageError = null;
    notifyListeners();
  }

  // ── Local field updates ───────────────────────────────────────────────────

  void updateName(String v)  { _profile = _profile?.copyWith(name: v);  notifyListeners(); }
  void updateEmail(String v) { _profile = _profile?.copyWith(email: v); notifyListeners(); }

  void updateState(String v) {
    _profile = _profile?.copyWith(address: ProfileAddress(
      houseNo: houseNo, address: address,
      city: '', state: v, pinCode: pinCode,
    ));
    // Reload cities for new state
    _cities = [];
    final match = _states.firstWhere(
          (s) => s.name == v,
      orElse: () => const AddressItem(id: 0, name: ''),
    );
    if (match.id > 0) loadCitiesForState(match.id);
    notifyListeners();
  }

  void updateCity(String v) {
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
    _isUpdating    = true;
    _updateError   = null;
    _updateSuccess = false;
    notifyListeners();

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