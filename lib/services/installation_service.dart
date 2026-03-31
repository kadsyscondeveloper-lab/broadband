// lib/services/installation_service.dart

import 'package:dio/dio.dart';
import '../core/api_client.dart';

// ── Models ────────────────────────────────────────────────────────────────────

enum InstallationStatus {
  pending,
  assigned,
  scheduled,
  inProgress,
  completed,
  cancelled;

  static InstallationStatus fromString(String s) {
    switch (s.toLowerCase()) {
      case 'assigned':    return InstallationStatus.assigned;
      case 'scheduled':   return InstallationStatus.scheduled;
      case 'in_progress':
      case 'inprogress':  return InstallationStatus.inProgress;
      case 'completed':   return InstallationStatus.completed;
      case 'cancelled':   return InstallationStatus.cancelled;
      default:            return InstallationStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case InstallationStatus.pending:    return 'Pending';
      case InstallationStatus.assigned:   return 'Agent Assigned';
      case InstallationStatus.scheduled:  return 'Scheduled';
      case InstallationStatus.inProgress: return 'In Progress';
      case InstallationStatus.completed:  return 'Completed';
      case InstallationStatus.cancelled:  return 'Cancelled';
    }
  }

  int get stepIndex {
    switch (this) {
      case InstallationStatus.pending:    return 0;
      case InstallationStatus.assigned:   return 1;
      case InstallationStatus.scheduled:  return 2;
      case InstallationStatus.inProgress: return 3;
      case InstallationStatus.completed:  return 4;
      case InstallationStatus.cancelled:  return -1;
    }
  }
}

class InstallationTechnician {
  final String  name;
  final String? phone;
  final String? employeeId;

  const InstallationTechnician({
    required this.name,
    this.phone,
    this.employeeId,
  });

  factory InstallationTechnician.fromJson(Map<String, dynamic> j) =>
      InstallationTechnician(
        name:       j['name']        as String? ?? '',
        phone:      j['phone']       as String?,
        employeeId: j['employee_id'] as String?,
      );
}

class InstallationRequest {
  final int                    id;
  final String                 requestNumber;
  final InstallationStatus     status;
  final String                 houseNo;
  final String                 address;
  final String                 city;
  final String                 state;
  final String                 pinCode;
  final DateTime?              scheduledAt;
  final DateTime?              completedAt;
  final InstallationTechnician? technician;
  final String?                notes;
  final DateTime               createdAt;

  const InstallationRequest({
    required this.id,
    required this.requestNumber,
    required this.status,
    required this.houseNo,
    required this.address,
    required this.city,
    required this.state,
    required this.pinCode,
    this.scheduledAt,
    this.completedAt,
    this.technician,
    this.notes,
    required this.createdAt,
  });

  factory InstallationRequest.fromJson(Map<String, dynamic> j) =>
      InstallationRequest(
        id:            int.tryParse(j['id'].toString()) ?? 0,
        requestNumber: j['request_number'] as String? ?? '',
        status: InstallationStatus.fromString(
            j['status']  as String? ?? 'pending'),
        houseNo:    j['house_no'] as String? ?? '',
        address:    j['address']  as String? ?? '',
        city:       j['city']     as String? ?? '',
        state:      j['state']    as String? ?? '',
        pinCode:    j['pin_code'] as String? ?? '',
        scheduledAt: j['scheduled_at'] != null
            ? DateTime.tryParse(j['scheduled_at'].toString())
            : null,
        completedAt: j['completed_at'] != null
            ? DateTime.tryParse(j['completed_at'].toString())
            : null,
        technician: j['technician'] != null
            ? InstallationTechnician.fromJson(
            j['technician'] as Map<String, dynamic>)
            : null,
        notes:     j['notes']      as String?,
        createdAt: DateTime.tryParse(j['created_at'].toString()) ??
            DateTime.now(),
      );

  String get fullAddress {
    final parts = <String>[];
    if (houseNo.isNotEmpty)  parts.add(houseNo);
    if (address.isNotEmpty)  parts.add(address);
    if (city.isNotEmpty)     parts.add(city);
    if (state.isNotEmpty)    parts.add(state);
    if (pinCode.isNotEmpty)  parts.add(pinCode);
    return parts.join(', ');
  }
}

class InstallationResult {
  final bool                success;
  final InstallationRequest? request;
  final String?             error;
  const InstallationResult({required this.success, this.request, this.error});
}

// ── Service ───────────────────────────────────────────────────────────────────

class InstallationService {
  static final InstallationService _i = InstallationService._();
  factory InstallationService() => _i;
  InstallationService._();

  final _api = ApiClient();

  /// POST /installations  — creates a new installation request
  Future<InstallationResult> createRequest({
    required String houseNo,
    required String address,
    required String city,
    required String state,
    required String pinCode,
    String? preferredDate,
    String? notes,
  }) async {
    try {
      final res = await _api.post('/installations', data: {
        'house_no': houseNo.trim(),
        'address':  address.trim(),
        'city':     city.trim(),
        'state':    state.trim(),
        'pin_code': pinCode.trim(),
        if (preferredDate != null) 'preferred_date': preferredDate,
        if (notes         != null) 'notes':          notes.trim(),
      });
      final data = res.data['data'] as Map<String, dynamic>?;
      if (data == null) {
        return const InstallationResult(
            success: false, error: 'Unexpected response from server.');
      }
      final req = InstallationRequest.fromJson(
          data['installation'] as Map<String, dynamic>? ?? data);
      return InstallationResult(success: true, request: req);
    } on DioException catch (e) {
      return InstallationResult(
          success: false, error: ApiException.fromDio(e).message);
    } catch (e) {
      return InstallationResult(success: false, error: e.toString());
    }
  }

  /// GET /installations/active  — latest pending/scheduled installation
  Future<InstallationRequest?> getActiveRequest() async {
    try {
      final res = await _api.get('/installations/active');
      final data = res.data['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      final raw = data['installation'] as Map<String, dynamic>?;
      return raw != null ? InstallationRequest.fromJson(raw) : null;
    } catch (_) {
      return null;
    }
  }

  /// GET /installations/:id
  Future<InstallationRequest?> getRequest(int id) async {
    try {
      final res = await _api.get('/installations/$id');
      final data = res.data['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return InstallationRequest.fromJson(
          data['installation'] as Map<String, dynamic>? ?? data);
    } catch (_) {
      return null;
    }
  }
}
