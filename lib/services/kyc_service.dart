// lib/services/kyc_service.dart
//
// Single source of truth for all KYC API calls.
// video_kyc_service.dart has been removed — everything lives here.
//
// Changes vs original:
//  1. VideoKycStatus model enriched with agent_notes, isInReview, canResubmit
//     (absorbed from the now-deleted video_kyc_service.dart).
//  2. submitVideoKyc — upload-only, no scheduling fields.
//  3. addressProofUrl / idProofUrl added to KycStatus for doc preview.

import 'dart:io';
import 'package:dio/dio.dart';
import '../core/api_client.dart';

// ── Models — Document KYC ─────────────────────────────────────────────────────

class KycStatus {
  final String  status; // not_submitted | pending | under_review | approved | rejected
  final String? addressProofType;
  final String? idProofType;
  final String? addressProofUrl;
  final String? idProofUrl;
  final String? submittedAt;
  final String? rejectionReason;

  const KycStatus({
    required this.status,
    this.addressProofType,
    this.idProofType,
    this.addressProofUrl,
    this.idProofUrl,
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
      addressProofUrl:  kyc['address_proof_url']  as String?,
      idProofUrl:       kyc['id_proof_url']       as String?,
      submittedAt:      kyc['submitted_at']       as String?,
      rejectionReason:  kyc['rejection_reason']   as String?,
    );
  }

  bool get isApproved     => status == 'approved';
  bool get isRejected     => status == 'rejected';
  bool get isPending      => status == 'pending' || status == 'under_review';
  bool get isNotSubmitted => status == 'not_submitted';
}

// ── Models — Video KYC ───────────────────────────────────────────────────────

class VideoKycStatus {
  final String  status; // not_submitted | pending | scheduled | completed | cancelled | rejected | failed
  final String? referenceId;
  final String? callPhone;
  final String? videoPath;
  final String? rejectionReason;
  final String? agentNotes;
  final String? createdAt;
  final String? reviewedAt;

  const VideoKycStatus({
    required this.status,
    this.referenceId,
    this.callPhone,
    this.videoPath,
    this.rejectionReason,
    this.agentNotes,
    this.createdAt,
    this.reviewedAt,
  });

  factory VideoKycStatus.notSubmitted() =>
      const VideoKycStatus(status: 'not_submitted');

  factory VideoKycStatus.fromJson(Map<String, dynamic> j) {
    final v = j['kyc'] as Map<String, dynamic>? ?? j;
    return VideoKycStatus(
      status:          v['status']           as String? ?? 'not_submitted',
      referenceId:     v['reference_id']     as String?,
      callPhone:       v['call_phone']       as String?,
      videoPath:       v['video_path']       as String?,
      rejectionReason: v['rejection_reason'] as String?,
      agentNotes:      v['agent_notes']      as String?,
      createdAt:       v['created_at']       as String?,
      reviewedAt:      v['reviewed_at']      as String?,
    );
  }

  bool get isNotSubmitted => status == 'not_submitted';
  bool get isPending      => status == 'pending' || status == 'scheduled';
  bool get isCompleted    => status == 'completed';
  bool get isCancelled    => status == 'cancelled';
  bool get isRejected     => status == 'rejected';
  bool get isFailed       => status == 'failed';

  /// True while staff review is in progress
  bool get isInReview     => isPending;

  /// User can resubmit after rejection, failure, or cancellation
  bool get canResubmit    => isRejected || isFailed || isCancelled;
}

// ── Result wrappers ───────────────────────────────────────────────────────────

class KycResult {
  final bool       success;
  final String?    error;
  final KycStatus? kycStatus;
  const KycResult({required this.success, this.error, this.kycStatus});
}

class VideoKycResult {
  final bool             success;
  final String?          error;
  final VideoKycStatus?  videoKycStatus;
  const VideoKycResult({required this.success, this.error, this.videoKycStatus});
}

// ── Service ───────────────────────────────────────────────────────────────────

class KycService {
  static final KycService _i = KycService._();
  factory KycService() => _i;
  KycService._();

  final _api = ApiClient();

  // ── Document KYC ──────────────────────────────────────────────────────────

  /// GET /user/kyc
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

  /// POST /user/kyc — multipart: address_proof + id_proof files + type fields
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

      final res  = await _api.post('/user/kyc', data: formData);
      final data = res.data['data'] as Map<String, dynamic>?;
      return KycResult(
        success:   true,
        kycStatus: data != null ? KycStatus.fromJson(data) : null,
      );
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

  /// GET /user/kyc/video
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

  /// POST /user/kyc/video
  ///
  Future<VideoKycResult> submitVideoKyc({
    required String callPhone,
    File?   videoFile,
  }) async {
    try {
      final Map<String, dynamic> fields = {
        'call_phone': callPhone,
      };

      if (videoFile != null) {
        fields['video'] = await MultipartFile.fromFile(
          videoFile.path,
          filename: videoFile.path.split('/').last,
          contentType: _dioMediaType(videoFile.path),
        );
      }

      final res  = await _api.post('/user/kyc/video', data: FormData.fromMap(fields));
      final data = res.data['data'] as Map<String, dynamic>?;
      return VideoKycResult(
        success:        true,
        videoKycStatus: data != null ? VideoKycStatus.fromJson(data) : null,
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?
          ?? e.message
          ?? 'Video KYC submission failed';
      return VideoKycResult(success: false, error: msg);
    } catch (e) {
      return VideoKycResult(success: false, error: e.toString());
    }
  }

  /// DELETE /user/kyc/video
  Future<bool> cancelVideoKyc() async {
    try {
      await _api.delete('/user/kyc/video');
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  DioMediaType _dioMediaType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.mov'))  return DioMediaType('video', 'quicktime');
    if (lower.endsWith('.webm')) return DioMediaType('video', 'webm');
    if (lower.endsWith('.avi'))  return DioMediaType('video', 'x-msvideo');
    if (lower.endsWith('.3gp'))  return DioMediaType('video', '3gpp');
    return DioMediaType('video', 'mp4');
  }
}