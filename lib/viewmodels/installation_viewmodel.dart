// lib/viewmodels/installation_viewmodel.dart

import 'package:flutter/foundation.dart';
import '../services/installation_service.dart';
import '../services/user_service.dart';

enum InstallationAddressStep { loading, form, submitting, success, error }

// ── Address Confirmation ViewModel ───────────────────────────────────────────

class InstallationAddressViewModel extends ChangeNotifier {
  final _installService = InstallationService();
  final _userService    = UserService();

  // ── State ─────────────────────────────────────────────────────────────────
  InstallationAddressStep _step = InstallationAddressStep.loading;
  String? _error;

  // Address fields (pre-filled from profile)
  String _houseNo  = '';
  String _address  = '';
  String _city     = '';
  String _state    = '';
  String _pinCode  = '';
  String _notes    = '';

  // Date selection (optional)
  DateTime? _preferredDate;

  InstallationRequest? _createdRequest;

  // ── Getters ───────────────────────────────────────────────────────────────
  InstallationAddressStep get step            => _step;
  String?                 get error           => _error;
  String                  get houseNo         => _houseNo;
  String                  get address         => _address;
  String                  get city            => _city;
  String                  get state           => _state;
  String                  get pinCode         => _pinCode;
  String                  get notes           => _notes;
  DateTime?               get preferredDate   => _preferredDate;
  InstallationRequest?    get createdRequest  => _createdRequest;

  bool get isSubmitting => _step == InstallationAddressStep.submitting;
  bool get canSubmit    =>
      _houseNo.isNotEmpty && _address.isNotEmpty &&
      _city.isNotEmpty    && _state.isNotEmpty &&
      _pinCode.length == 6;

  // ── Setters ───────────────────────────────────────────────────────────────
  void setHouseNo(String v)  { _houseNo  = v; notifyListeners(); }
  void setAddress(String v)  { _address  = v; notifyListeners(); }
  void setCity(String v)     { _city     = v; notifyListeners(); }
  void setState_(String v)   { _state    = v; notifyListeners(); }
  void setPinCode(String v)  { _pinCode  = v; notifyListeners(); }
  void setNotes(String v)    { _notes    = v; notifyListeners(); }
  void setPreferredDate(DateTime? d) { _preferredDate = d; notifyListeners(); }

  // ── Init — pre-fill from user profile ────────────────────────────────────
  Future<void> init() async {
    _step = InstallationAddressStep.loading;
    notifyListeners();

    final profile = await _userService.getProfile();
    if (profile != null) {
      final addr = profile.address;
      _houseNo = addr.houseNo;
      _address = addr.address;
      _city    = addr.city;
      _state   = addr.state;
      _pinCode = addr.pinCode;
    }

    _step = InstallationAddressStep.form;
    notifyListeners();
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> submit() async {
    if (!canSubmit) return;

    _step  = InstallationAddressStep.submitting;
    _error = null;
    notifyListeners();

    final result = await _installService.createRequest(
      houseNo:       _houseNo,
      address:       _address,
      city:          _city,
      state:         _state,
      pinCode:       _pinCode,
      notes:         _notes.isEmpty ? null : _notes,
      preferredDate: _preferredDate?.toIso8601String(),
    );

    if (result.success) {
      _createdRequest = result.request;
      _step           = InstallationAddressStep.success;
    } else {
      _error = result.error;
      _step  = InstallationAddressStep.form;
    }
    notifyListeners();
  }
}

// ── Tracker ViewModel ─────────────────────────────────────────────────────────

class InstallationTrackerViewModel extends ChangeNotifier {
  final _service = InstallationService();

  InstallationRequest? _request;
  bool    _isLoading = false;
  String? _error;

  InstallationRequest? get request   => _request;
  bool                 get isLoading => _isLoading;
  String?              get error     => _error;

  bool get hasRequest => _request != null;

  Future<void> load({int? requestId}) async {
    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      _request = requestId != null
          ? await _service.getRequest(requestId)
          : await _service.getActiveRequest();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void setRequest(InstallationRequest req) {
    _request = req;
    notifyListeners();
  }
}
