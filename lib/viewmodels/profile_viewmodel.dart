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

  // ── CRM address hierarchy ─────────────────────────────────────────────────
  // Selections (IDs + names)
  int?    _selectedLocalityId;
  String  _selectedLocalityName = '';
  int?    _selectedAreaId;
  String  _selectedAreaName     = '';
  int?    _selectedBuildingId;
  String  _selectedBuildingName = '';

  // Dropdown lists
  List<AddressItem> _localities      = [];
  List<AddressItem> _areas           = [];
  List<AddressItem> _buildings       = [];
  bool              _localitiesLoading = false;
  bool              _areasLoading      = false;
  bool              _buildingsLoading  = false;
  String?           _addressError;

  // ── Getters ───────────────────────────────────────────────────────────────

  FullProfile? get profile        => _profile;
  bool         get isLoading      => _isLoading;
  bool         get isUpdating     => _isUpdating;
  String?      get loadError      => _loadError;
  String?      get updateError    => _updateError;
  bool         get updateSuccess  => _updateSuccess;

  // Image
  String? get localImageBase64 => _localImageBase64;
  bool    get imageUploading   => _imageUploading;
  String? get imageError       => _imageError;

  // Address dropdowns
  List<AddressItem> get localities       => _localities;
  List<AddressItem> get areas            => _areas;
  List<AddressItem> get buildings        => _buildings;
  bool              get localitiesLoading => _localitiesLoading;
  bool              get areasLoading      => _areasLoading;
  bool              get buildingsLoading  => _buildingsLoading;
  String?           get addressError      => _addressError;

  // Selected address values
  int?   get selectedLocalityId   => _selectedLocalityId;
  String get selectedLocalityName => _selectedLocalityName;
  int?   get selectedAreaId       => _selectedAreaId;
  String get selectedAreaName     => _selectedAreaName;
  int?   get selectedBuildingId   => _selectedBuildingId;
  String get selectedBuildingName => _selectedBuildingName;

  // Basic profile getters
  String get name          => _profile?.name            ?? '';
  String get phone         => _profile?.phone           ?? '';
  String get email         => _profile?.email           ?? '';
  double get walletBalance => _profile?.walletBalance   ?? 0.0;
  String get kycStatus     => _profile?.kycStatus       ?? 'not_submitted';
  String? get profileImageUrl => _profile?.profileImageUrl;
  String get flatNo        => _profile?.flatNo          ?? '';
  String get pinCode       => _profile?.pinCode         ?? '';

  // ── Load profile ──────────────────────────────────────────────────────────

  Future<void> loadProfile() async {
    _isLoading = true;
    _loadError = null;
    notifyListeners();

    _profile = await _service.getProfile();
    if (_profile == null) {
      _loadError = 'Failed to load profile. Please try again.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Pre-populate selections from profile
    _selectedLocalityId   = _profile!.localityId;
    _selectedLocalityName = _profile!.localityName;
    _selectedAreaId       = _profile!.areaId;
    _selectedAreaName     = _profile!.areaName;
    _selectedBuildingId   = _profile!.buildingId;
    _selectedBuildingName = _profile!.buildingName;

    _isLoading = false;
    notifyListeners();

    // Load all localities, then pre-fetch areas/buildings for current selection
    await loadLocalities();
    if (_selectedLocalityId != null && _selectedLocalityId! > 0) {
      await loadAreasForLocality(_selectedLocalityId!);
    }
    if (_selectedAreaId != null && _selectedAreaId! > 0) {
      await loadBuildingsForArea(_selectedAreaId!);
    }
  }

  // ── Address dropdown loaders ──────────────────────────────────────────────

  Future<void> loadLocalities() async {
    if (_localitiesLoading) return;
    _localitiesLoading = true;
    _addressError      = null;
    notifyListeners();

    try {
      _localities = await _service.getLocalities();
    } catch (_) {
      _addressError = 'Could not load localities.';
    }

    _localitiesLoading = false;
    notifyListeners();
  }

  Future<void> loadAreasForLocality(int localityId) async {
    if (_areasLoading) return;
    _areas         = [];
    _buildings     = [];
    _areasLoading  = true;
    notifyListeners();

    try {
      _areas = await _service.getAreas(localityId);
    } catch (_) {
      _addressError = 'Could not load areas.';
    }

    _areasLoading = false;
    notifyListeners();
  }

  Future<void> loadBuildingsForArea(int areaId) async {
    if (_buildingsLoading) return;
    _buildings        = [];
    _buildingsLoading = true;
    notifyListeners();

    try {
      _buildings = await _service.getBuildings(areaId);
    } catch (_) {
      _addressError = 'Could not load buildings.';
    }

    _buildingsLoading = false;
    notifyListeners();
  }

  // ── Address selection updates ─────────────────────────────────────────────

  void selectLocality(AddressItem item) {
    _selectedLocalityId   = item.id;
    _selectedLocalityName = item.name;
    // Reset downstream selections
    _selectedAreaId       = null;
    _selectedAreaName     = '';
    _selectedBuildingId   = null;
    _selectedBuildingName = '';
    _areas                = [];
    _buildings            = [];
    notifyListeners();
    loadAreasForLocality(item.id);
  }

  void selectArea(AddressItem item) {
    _selectedAreaId       = item.id;
    _selectedAreaName     = item.name;
    // Reset downstream selection
    _selectedBuildingId   = null;
    _selectedBuildingName = '';
    _buildings            = [];
    notifyListeners();
    loadBuildingsForArea(item.id);
  }

  void selectBuilding(AddressItem item) {
    _selectedBuildingId   = item.id;
    _selectedBuildingName = item.name;
    notifyListeners();
  }

  void updateFlatNo(String v) {
    _profile = _profile?.copyWith(flatNo: v);
    notifyListeners();
  }

  void updatePinCode(String v) {
    _profile = _profile?.copyWith(pinCode: v);
    notifyListeners();
  }

  // ── Basic field updates ───────────────────────────────────────────────────

  void updateName(String v) {
    _profile = _profile?.copyWith(name: v);
    notifyListeners();
  }

  void updateEmail(String v) {
    _profile = _profile?.copyWith(email: v);
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
        localityId: _selectedLocalityId,
        areaId:     _selectedAreaId,
        buildingId: _selectedBuildingId,
        flatNo:     flatNo,
        pinCode:    pinCode,
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