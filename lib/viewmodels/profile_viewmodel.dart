// lib/viewmodels/profile_viewmodel.dart
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
  List<String> _states          = [];
  List<String> _cities          = [];
  bool         _statesLoading   = false;
  bool         _citiesLoading   = false;
  String?      _locationsError;

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
  List<String> get states         => _states;
  List<String> get cities         => _cities;
  bool         get statesLoading  => _statesLoading;
  bool         get citiesLoading  => _citiesLoading;
  String?      get locationsError => _locationsError;

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

  String? get profileImageUrl => _profile?.profileImageUrl;

  // ── Load profile from API ─────────────────────────────────────────────────

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

    // After profile loads, fetch states and cities for the current state
    await loadStates();
    if (state.isNotEmpty) {
      await loadCitiesForState(state);
    }
  }

  // ── Location loaders ──────────────────────────────────────────────────────

  Future<void> loadStates() async {
    if (_statesLoading) return;
    _statesLoading   = true;
    _locationsError  = null;
    notifyListeners();

    try {
      _states = await _service.getStates();
    } catch (_) {
      _locationsError = 'Could not load states. Please try again.';
    }

    _statesLoading = false;
    notifyListeners();
  }

  /// Called whenever the user picks a new state — clears city and fetches
  /// the fresh city list for that state from the backend.
  Future<void> loadCitiesForState(String stateName) async {
    if (_citiesLoading) return;
    _cities        = [];
    _citiesLoading = true;
    notifyListeners();

    try {
      _cities = await _service.getCities(stateName);
    } catch (_) {
      _locationsError = 'Could not load cities. Please try again.';
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

  // ── Local field updates (before hitting save) ─────────────────────────────

  void updateName(String v)  { _profile = _profile?.copyWith(name: v);  notifyListeners(); }
  void updateEmail(String v) { _profile = _profile?.copyWith(email: v); notifyListeners(); }

  void updateState(String v) {
    _profile = _profile?.copyWith(address: ProfileAddress(
      houseNo: houseNo, address: address,
      // Clear city when state changes — old city may not belong to new state
      city: '', state: v, pinCode: pinCode,
    ));
    notifyListeners();
    // Fetch fresh city list for the newly selected state
    loadCitiesForState(v);
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