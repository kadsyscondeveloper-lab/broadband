// lib/services/availability_service.dart

import 'package:dio/dio.dart';
import '../core/api_client.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class InquiryResult {
  final bool    success;
  final String? referenceId;
  final String? error;

  const InquiryResult({
    required this.success,
    this.referenceId,
    this.error,
  });
}

class InquiryStatusResult {
  final String    status;       // pending / available / unavailable
  final String?   adminNotes;
  final String    pinCode;
  final DateTime? respondedAt;

  const InquiryStatusResult({
    required this.status,
    this.adminNotes,
    required this.pinCode,
    this.respondedAt,
  });

  factory InquiryStatusResult.fromJson(Map<String, dynamic> j) =>
      InquiryStatusResult(
        status:      j['status']      as String? ?? 'pending',
        adminNotes:  j['admin_notes'] as String?,
        pinCode:     j['pin_code']    as String? ?? '',
        respondedAt: j['responded_at'] != null
            ? DateTime.tryParse(j['responded_at'].toString())
            : null,
      );

  bool get isAvailable   => status == 'available';
  bool get isUnavailable => status == 'unavailable';
  bool get isPending     => status == 'pending';
}

// ── Service ───────────────────────────────────────────────────────────────────

class AvailabilityService {
  static final AvailabilityService _i = AvailabilityService._();
  factory AvailabilityService() => _i;
  AvailabilityService._();

  final _api = ApiClient();

  /// POST /availability/inquiry
  /// Submits a service availability inquiry for the support team to review.
  Future<InquiryResult> submitInquiry({
    required String name,
    required String phone,
    required String pinCode,
    String? address,
    String? email,
  }) async {
    try {
      final res = await _api.post('/availability/inquiry', data: {
        'name':     name.trim(),
        'phone':    phone.trim(),
        'pin_code': pinCode.trim(),
        if (address != null && address.isNotEmpty) 'address': address.trim(),
        if (email   != null && email.isNotEmpty)   'email':   email.trim(),
      });
      final data = res.data['data'] as Map<String, dynamic>? ?? {};
      return InquiryResult(
        success:     true,
        referenceId: data['reference_id'] as String?,
      );
    } on DioException catch (e) {
      return InquiryResult(
        success: false,
        error:   ApiException.fromDio(e).message,
      );
    } catch (e) {
      return InquiryResult(
        success: false,
        error:   'Something went wrong. Please try again.',
      );
    }
  }

  /// GET /availability/status?phone=XXXXXXXXXX
  /// Polls the status of a previously submitted inquiry by phone number.
  /// Returns null if no inquiry found.
  Future<InquiryStatusResult?> getInquiryStatus(String phone) async {
    try {
      final res = await _api.get(
        '/availability/status',
        params: {'phone': phone.trim()},
      );
      final data = res.data['data']?['inquiry'] as Map<String, dynamic>?;
      if (data == null) return null;
      return InquiryStatusResult.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}