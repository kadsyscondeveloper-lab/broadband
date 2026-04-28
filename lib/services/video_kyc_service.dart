// lib/services/video_kyc_service.dart
//
// Submits the video as multipart/form-data (field name: "video").
// Base64 encoding has been removed — the backend (multer) handles the file directly.

import 'dart:io';
import 'package:dio/dio.dart';
import '../core/api_client.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

enum VideoKycStatus {
  notSubmitted,
  pending,       // submitted, under review
  underReview,   // admin is reviewing
  completed,     // approved
  rejected,      // admin rejected — user can resubmit
  failed,        // processing error
  cancelled;

  static VideoKycStatus fromString(String? s) {
    switch (s) {
      case 'pending':      return VideoKycStatus.pending;
      case 'under_review': return VideoKycStatus.underReview;
      case 'completed':    return VideoKycStatus.completed;
      case 'rejected':     return VideoKycStatus.rejected;
      case 'failed':       return VideoKycStatus.failed;
      case 'cancelled':    return VideoKycStatus.cancelled;
      default:             return VideoKycStatus.notSubmitted;
    }
  }
}

// ── Model ─────────────────────────────────────────────────────────────────────

class VideoKycRequest {
  final int            id;
  final String         referenceId;
  final VideoKycStatus status;
  final String?        rejectionReason;
  final String?        agentNotes;
  final String         createdAt;
  final String?        reviewedAt;

  const VideoKycRequest({
    required this.id,
    required this.referenceId,
    required this.status,
    this.rejectionReason,
    this.agentNotes,
    required this.createdAt,
    this.reviewedAt,
  });

  factory VideoKycRequest.fromJson(Map<String, dynamic> j) => VideoKycRequest(
    id:              (j['id'] as num).toInt(),
    referenceId:     j['reference_id']     as String? ?? '',
    status:          VideoKycStatus.fromString(j['status'] as String?),
    rejectionReason: j['rejection_reason'] as String?,
    agentNotes:      j['agent_notes']      as String?,
    createdAt:       j['created_at']       as String? ?? '',
    reviewedAt:      j['reviewed_at']      as String?,
  );

  bool get isPending    => status == VideoKycStatus.pending;
  bool get isUnderReview => status == VideoKycStatus.underReview;
  bool get isCompleted  => status == VideoKycStatus.completed;
  bool get isRejected   => status == VideoKycStatus.rejected;
  bool get isFailed     => status == VideoKycStatus.failed;
  bool get isCancelled  => status == VideoKycStatus.cancelled;

  /// True while waiting for any kind of review
  bool get isInReview   => isPending || isUnderReview;

  /// User can resubmit after rejection, failure, or cancellation
  bool get canResubmit  => isRejected || isFailed || isCancelled;
}

// ── Result wrappers ───────────────────────────────────────────────────────────

class VideoKycResult {
  final bool             success;
  final String?          error;
  final VideoKycRequest? data;
  const VideoKycResult({required this.success, this.error, this.data});
}

// ── Service ───────────────────────────────────────────────────────────────────

class VideoKycService {
  static final VideoKycService _i = VideoKycService._();
  factory VideoKycService() => _i;
  VideoKycService._();

  final _api = ApiClient();

  // ── GET /user/kyc/video ───────────────────────────────────────────────────

  Future<VideoKycRequest?> getStatus() async {
    try {
      final res  = await _api.get('/user/kyc/video');
      final data = res.data['data']?['video_kyc'];
      if (data == null) return null;
      return VideoKycRequest.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ── POST /user/kyc/video — multipart file upload ──────────────────────────
  //
  // Sends the video as multipart/form-data with field name "video".
  // The backend (multer) saves the file to disk and returns a reference ID.

  Future<VideoKycResult> submitVideo(File videoFile) async {
    try {
      final fileName = videoFile.path.split('/').last;
      final mimeType = _mimeType(videoFile.path);

      // Split mime into type/subtype for DioMediaType
      final mimeParts = mimeType.split('/');

      final formData = FormData.fromMap({
        'video': await MultipartFile.fromFile(
          videoFile.path,
          filename: fileName,
          contentType: DioMediaType(mimeParts[0], mimeParts[1]),
        ),
      });

      final res = await _api.post(
        '/user/kyc/video',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {
            // Remove Content-Type so Dio sets boundary automatically
            Headers.contentTypeHeader: null,
          },
        ),
      );

      final responseData = res.data['data'];
      return VideoKycResult(
        success: true,
        data: responseData != null
            ? VideoKycRequest.fromJson(responseData as Map<String, dynamic>)
            : null,
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?
          ?? 'Failed to submit video. Please try again.';
      return VideoKycResult(success: false, error: msg);
    } catch (e) {
      return VideoKycResult(success: false, error: e.toString());
    }
  }

  // ── DELETE /user/kyc/video ────────────────────────────────────────────────

  Future<VideoKycResult> cancel() async {
    try {
      await _api.delete('/user/kyc/video');
      return const VideoKycResult(success: true);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ?? 'Failed to cancel';
      return VideoKycResult(success: false, error: msg);
    } catch (e) {
      return VideoKycResult(success: false, error: e.toString());
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _mimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.mov'))  return 'video/quicktime';
    if (lower.endsWith('.webm')) return 'video/webm';
    if (lower.endsWith('.avi'))  return 'video/x-msvideo';
    if (lower.endsWith('.3gp'))  return 'video/3gpp';
    return 'video/mp4';
  }
}