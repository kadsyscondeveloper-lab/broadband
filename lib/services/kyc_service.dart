// lib/services/kyc_service.dart

import 'dart:io';
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

  bool get isApproved     => status == 'approved';
  bool get isRejected     => status == 'rejected';
  bool get isPending      => status == 'pending' || status == 'under_review';
  bool get isNotSubmitted => status == 'not_submitted';
}

class VideoKycStatus {
  final String  status; // not_submitted | pending | scheduled | completed | cancelled
  final String? referenceId;
  final String? preferredDate;
  final String? preferredSlot;
  final String? callPhone;
  final String? rejectionReason;
  final String? createdAt;

  const VideoKycStatus({
    required this.status,
    this.referenceId,
    this.preferredDate,
    this.preferredSlot,
    this.callPhone,
    this.rejectionReason,
    this.createdAt,
  });

  factory VideoKycStatus.notSubmitted() =>
      const VideoKycStatus(status: 'not_submitted');

  factory VideoKycStatus.fromJson(Map<String, dynamic> j) {
    final v = j['kyc'] as Map<String, dynamic>? ?? j;
    return VideoKycStatus(
      status:          v['status']           as String? ?? 'not_submitted',
      referenceId:     v['reference_id']     as String?,
      preferredDate:   v['preferred_date']   as String?,
      preferredSlot:   v['preferred_slot']   as String?,
      callPhone:       v['call_phone']       as String?,
      rejectionReason: v['rejection_reason'] as String?,
      createdAt:       v['created_at']       as String?,
    );
  }

  bool get isNotSubmitted => status == 'not_submitted';
  bool get isPending      => status == 'pending' || status == 'scheduled';
  bool get isCompleted    => status == 'completed';
  bool get isCancelled    => status == 'cancelled';
}

class KycResult {
  final bool       success;
  final String?    error;
  final KycStatus? kycStatus;
  const KycResult({required this.success, this.error, this.kycStatus});
}

class VideoKycResult {
  final bool            success;
  final String?         error;
  final VideoKycStatus? videoKycStatus;
  const VideoKycResult({required this.success, this.error, this.videoKycStatus});
}

// ── Service ───────────────────────────────────────────────────────────────────

class KycService {
  static final KycService _i = KycService._();
  factory KycService() => _i;
  KycService._();

  final _api = ApiClient();

  // ── Document KYC ──────────────────────────────────────────────────────────

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

  /// POST /user/kyc  — upload address proof + ID proof via multipart/form-data
  Future<KycResult> submitKyc({
    required String addressProofType,
    required File   addressProofFile,
    required String idProofType,
    required File   idProofFile,
  }) async {
    try {
      final formData = FormData.fromMap({
        'address_proof_type': addressProofType,
        'id_proof_type':      idProofType,
        'address_proof': await MultipartFile.fromFile(
          addressProofFile.path,
          filename: addressProofFile.path.split('/').last,
        ),
        'id_proof': await MultipartFile.fromFile(
          idProofFile.path,
          filename: idProofFile.path.split('/').last,
        ),
      });

      final res = await _api.post('/user/kyc', data: formData);

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

  // ── Video KYC ─────────────────────────────────────────────────────────────

  /// GET /user/kyc/video  — fetch current video KYC status
  Future<VideoKycStatus> getVideoStatus() async {
    try {
      final res  = await _api.get('/user/kyc/video');
      final data = res.data['data'] as Map<String, dynamic>?;
      if (data == null) return VideoKycStatus.notSubmitted();
      return VideoKycStatus.fromJson(data);
    } catch (_) {
      return VideoKycStatus.notSubmitted();
    }
  }

  /// POST /user/kyc/video  — submit video KYC request with optional video file
  Future<VideoKycResult> submitVideoKyc({
    required String preferredDate,
    required String preferredSlot,
    required String callPhone,
    File?           videoFile,
  }) async {
    try {
      final Map<String, dynamic> fields = {
        'preferred_date': preferredDate,
        'preferred_slot': preferredSlot,
        'call_phone':     callPhone,
      };

      if (videoFile != null) {
        fields['video'] = await MultipartFile.fromFile(
          videoFile.path,
          filename: videoFile.path.split('/').last,
        );
      }

      final res = await _api.post(
        '/user/kyc/video',
        data: FormData.fromMap(fields),
      );

      final data = res.data['data'] as Map<String, dynamic>?;
      final status = data != null ? VideoKycStatus.fromJson(data) : null;

      return VideoKycResult(success: true, videoKycStatus: status);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?
          ?? e.message
          ?? 'Video KYC submission failed';
      return VideoKycResult(success: false, error: msg);
    } catch (e) {
      return VideoKycResult(success: false, error: e.toString());
    }
  }

  /// DELETE /user/kyc/video  — cancel pending video KYC
  Future<bool> cancelVideoKyc() async {
    try {
      await _api.delete('/user/kyc/video');
      return true;
    } catch (_) {
      return false;
    }
  }
}