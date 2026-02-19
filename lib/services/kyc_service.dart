// lib/services/kyc_service.dart

import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../core/api_client.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class KycStatus {
  final String  status; // not_submitted | pending | under_review | approved | rejected
  final String? addressProofType;
  final String? idProofType;
  final String? submittedAt;
  final String? rejectionReason;

  const KycStatus({
    required this.status,
    this.addressProofType,
    this.idProofType,
    this.submittedAt,
    this.rejectionReason,
  });

  factory KycStatus.notSubmitted() => const KycStatus(status: 'not_submitted');

  factory KycStatus.fromJson(Map<String, dynamic> j) {
    final kyc = j['kyc'] as Map<String, dynamic>? ?? j;
    return KycStatus(
      status:           kyc['status']             as String? ?? 'not_submitted',
      addressProofType: kyc['address_proof_type'] as String?,
      idProofType:      kyc['id_proof_type']      as String?,
      submittedAt:      kyc['submitted_at']       as String?,
      rejectionReason:  kyc['rejection_reason']   as String?,
    );
  }

  bool get isApproved    => status == 'approved';
  bool get isRejected    => status == 'rejected';
  bool get isPending     => status == 'pending' || status == 'under_review';
  bool get isNotSubmitted => status == 'not_submitted';
}

class KycResult {
  final bool    success;
  final String? error;
  final KycStatus? kycStatus;
  const KycResult({required this.success, this.error, this.kycStatus});
}

// ── Service ───────────────────────────────────────────────────────────────────

class KycService {
  static final KycService _i = KycService._();
  factory KycService() => _i;
  KycService._();

  final _api = ApiClient();

  /// GET /user/kyc  — fetch current KYC status
  Future<KycStatus> getStatus() async {
    try {
      final res  = await _api.get('/user/kyc');
      final data = res.data['data'] as Map<String, dynamic>?;
      if (data == null) return KycStatus.notSubmitted();
      return KycStatus.fromJson(data);
    } catch (_) {
      return KycStatus.notSubmitted();
    }
  }

  /// POST /user/kyc  — submit KYC with base64 doc strings
  ///
  /// Backend receives:
  /// {
  ///   "address_proof_type": "Rent Agreement",
  ///   "address_proof_data": "<base64 string>",
  ///   "address_proof_mime": "image/jpeg",       // or "application/pdf"
  ///   "id_proof_type":      "Aadhar Card",
  ///   "id_proof_data":      "<base64 string>",
  ///   "id_proof_mime":      "image/png"
  /// }
  Future<KycResult> submitKyc({
    required String addressProofType,
    required File   addressProofFile,
    required String idProofType,
    required File   idProofFile,
  }) async {
    try {
      // Convert both files to base64 in parallel
      final results = await Future.wait([
        _fileToBase64(addressProofFile),
        _fileToBase64(idProofFile),
      ]);

      final addrData = results[0];
      final idData   = results[1];

      final res = await _api.post('/user/kyc', data: {
        'address_proof_type': addressProofType,
        'address_proof_data': addrData.base64,
        'address_proof_mime': addrData.mimeType,
        'id_proof_type':      idProofType,
        'id_proof_data':      idData.base64,
        'id_proof_mime':      idData.mimeType,
      });

      final data = res.data['data'] as Map<String, dynamic>?;
      final status = data != null ? KycStatus.fromJson(data) : null;

      return KycResult(success: true, kycStatus: status);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?
          ?? e.message
          ?? 'Submission failed';
      return KycResult(success: false, error: msg);
    } catch (e) {
      return KycResult(success: false, error: e.toString());
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<_Base64File> _fileToBase64(File file) async {
    final bytes    = await file.readAsBytes();
    final base64   = base64Encode(bytes);
    final mimeType = _getMimeType(file.path);
    return _Base64File(base64: base64, mimeType: mimeType);
  }

  String _getMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.pdf'))  return 'application/pdf';
    if (lower.endsWith('.png'))  return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return 'application/octet-stream';
  }
}

class _Base64File {
  final String base64;
  final String mimeType;
  const _Base64File({required this.base64, required this.mimeType});
}