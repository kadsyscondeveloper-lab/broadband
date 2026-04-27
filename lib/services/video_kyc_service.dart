// lib/services/video_kyc_service.dart
//
// Revised flow: user records a short selfie video saying the required phrase,
// submits it as base64, and the backend runs AI verification (speech-to-text
// + content match).  Live-call / Agora logic has been removed.

import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../core/api_client.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

/// Status values returned by the backend after submission.
enum VideoKycStatus {
  notSubmitted,
  pending,       // submitted, AI verification in progress
  aiVerified,    // AI passed; may still need human sign-off
  completed,     // fully verified
  failed,        // AI rejected (wrong phrase / face mismatch / etc.)
  cancelled;

  static VideoKycStatus fromString(String? s) {
    switch (s) {
      case 'pending':       return VideoKycStatus.pending;
      case 'ai_verified':   return VideoKycStatus.aiVerified;
      case 'completed':     return VideoKycStatus.completed;
      case 'failed':        return VideoKycStatus.failed;
      case 'cancelled':     return VideoKycStatus.cancelled;
      default:              return VideoKycStatus.notSubmitted;
    }
  }
}

// ── Model ─────────────────────────────────────────────────────────────────────

class VideoKycRequest {
  final int           id;
  final String        referenceId;
  final VideoKycStatus status;
  final String?       rejectionReason;
  final String?       agentNotes;
  final String        createdAt;
  final String?       verifiedAt;

  /// The phrase the user was asked to say (returned by backend on submission).
  final String?       requiredPhrase;

  /// Transcript extracted by AI (useful to show user what was heard).
  final String?       aiTranscript;

  /// Confidence score 0–100 from the AI model.
  final int?          aiConfidence;

  const VideoKycRequest({
    required this.id,
    required this.referenceId,
    required this.status,
    this.rejectionReason,
    this.agentNotes,
    required this.createdAt,
    this.verifiedAt,
    this.requiredPhrase,
    this.aiTranscript,
    this.aiConfidence,
  });

  factory VideoKycRequest.fromJson(Map<String, dynamic> j) => VideoKycRequest(
    id:              (j['id'] as num).toInt(),
    referenceId:     j['reference_id']    as String? ?? '',
    status:          VideoKycStatus.fromString(j['status'] as String?),
    rejectionReason: j['rejection_reason'] as String?,
    agentNotes:      j['agent_notes']     as String?,
    createdAt:       j['created_at']      as String? ?? '',
    verifiedAt:      j['verified_at']     as String?,
    requiredPhrase:  j['required_phrase'] as String?,
    aiTranscript:    j['ai_transcript']   as String?,
    aiConfidence:    j['ai_confidence'] != null
        ? (j['ai_confidence'] as num).toInt()
        : null,
  );

  bool get isPending    => status == VideoKycStatus.pending;
  bool get isAiVerified => status == VideoKycStatus.aiVerified;
  bool get isCompleted  => status == VideoKycStatus.completed;
  bool get isFailed     => status == VideoKycStatus.failed;
  bool get isCancelled  => status == VideoKycStatus.cancelled;
  bool get isInReview   => isPending || isAiVerified;
}

// ── Result wrappers ───────────────────────────────────────────────────────────

class VideoKycResult {
  final bool             success;
  final String?          error;
  final VideoKycRequest? data;
  const VideoKycResult({required this.success, this.error, this.data});
}

/// Returned before recording so the UI knows what phrase to show the user.
class VideoKycScript {
  /// e.g. "Hello, I am Rahul Sharma and this is my Aadhar Card."
  final String phrase;

  /// Name extracted from the user's profile.
  final String userName;

  /// Document type from the user's submitted KYC (e.g. "Aadhar Card").
  final String docType;

  const VideoKycScript({
    required this.phrase,
    required this.userName,
    required this.docType,
  });

  factory VideoKycScript.fromJson(Map<String, dynamic> j) => VideoKycScript(
    phrase:   j['phrase']    as String? ?? '',
    userName: j['user_name'] as String? ?? '',
    docType:  j['doc_type']  as String? ?? '',
  );

  /// Fallback constructor if the backend doesn't have a /script endpoint yet.
  factory VideoKycScript.fallback({
    required String userName,
    required String docType,
  }) {
    final phrase =
        'Hello, I am $userName and this is my $docType.';
    return VideoKycScript(phrase: phrase, userName: userName, docType: docType);
  }
}

// ── Service ───────────────────────────────────────────────────────────────────

class VideoKycService {
  static final VideoKycService _i = VideoKycService._();
  factory VideoKycService() => _i;
  VideoKycService._();

  final _api = ApiClient();

  // ── GET /user/kyc/video — fetch current status ────────────────────────────

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

  // ── GET /user/kyc/video/script — get required phrase ─────────────────────
  //
  // The backend builds the phrase using the user's profile name + the doc type
  // already on file from the document KYC step.
  // If the endpoint doesn't exist yet, call VideoKycScript.fallback(...).

  Future<VideoKycScript?> getScript() async {
    try {
      final res  = await _api.get('/user/kyc/video/script');
      final data = res.data['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return VideoKycScript.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  // ── POST /user/kyc/video — submit recorded video ──────────────────────────
  //
  // Request body:
  // {
  //   "video_data": "<base64-encoded MP4>",
  //   "video_mime": "video/mp4",           // or video/quicktime for iOS .mov
  //   "duration_seconds": 8               // optional, helps backend reject blanks
  // }
  //
  // Response:
  // { success: true, data: { video_kyc: { ...VideoKycRequest fields... } } }

  Future<VideoKycResult> submitVideo(File videoFile) async {
    try {
      final bytes    = await videoFile.readAsBytes();
      final b64      = base64Encode(bytes);
      final mime     = _mimeType(videoFile.path);

      final res = await _api.post('/user/kyc/video', data: {
        'video_data': b64,
        'video_mime': mime,
      });

      final data = res.data['data']?['video_kyc'];
      return VideoKycResult(
        success: true,
        data: data != null
            ? VideoKycRequest.fromJson(data as Map<String, dynamic>)
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

  // ── DELETE /user/kyc/video — cancel / request re-submission ──────────────

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
    return 'video/mp4';
  }
}