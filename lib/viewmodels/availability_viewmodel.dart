// lib/viewmodels/availability_viewmodel.dart

import 'package:flutter/foundation.dart';
import '../services/availability_service.dart';

enum AvailabilityStep { idle, submitting, success, error }

class AvailabilityViewModel extends ChangeNotifier {
  final _service = AvailabilityService();

  // ── State ─────────────────────────────────────────────────────────────────
  AvailabilityStep _step        = AvailabilityStep.idle;
  String?          _error;
  String?          _referenceId;

  // Form inputs
  String _name    = '';
  String _phone   = '';
  String _pinCode = '';
  String _address = '';
  String _email   = '';

  // ── Getters ───────────────────────────────────────────────────────────────
  AvailabilityStep get step        => _step;
  String?          get error       => _error;
  String?          get referenceId => _referenceId;

  bool get isSubmitting => _step == AvailabilityStep.submitting;
  bool get isSuccess    => _step == AvailabilityStep.success;

  bool get canSubmit =>
      _name.trim().isNotEmpty &&
          _phone.trim().length == 10 &&
          _pinCode.trim().length == 6;

  // ── Setters ───────────────────────────────────────────────────────────────
  void setName(String v) {
    _name = v;
    _clearError();
  }

  void setPhone(String v) {
    _phone = v;
    _clearError();
  }

  void setPinCode(String v) {
    _pinCode = v;
    _clearError();
  }

  void setAddress(String v) {
    _address = v;
    notifyListeners();
  }

  void setEmail(String v) {
    _email = v;
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) _error = null;
    notifyListeners();
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> submit() async {
    if (!canSubmit) return;

    _step  = AvailabilityStep.submitting;
    _error = null;
    notifyListeners();

    final res = await _service.submitInquiry(
      name:    _name.trim(),
      phone:   _phone.trim(),
      pinCode: _pinCode.trim(),
      address: _address.trim().isEmpty ? null : _address.trim(),
      email:   _email.trim().isEmpty   ? null : _email.trim(),
    );

    if (res.success) {
      _referenceId = res.referenceId;
      _step        = AvailabilityStep.success;
    } else {
      _error = res.error ?? 'Something went wrong. Please try again.';
      _step  = AvailabilityStep.error;
    }
    notifyListeners();
  }

  // ── Reset ─────────────────────────────────────────────────────────────────
  void reset() {
    _step        = AvailabilityStep.idle;
    _error       = null;
    _referenceId = null;
    _name = _phone = _pinCode = _address = _email = '';
    notifyListeners();
  }
}