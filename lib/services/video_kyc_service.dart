// lib/services/video_kyc_service.dart

import 'package:dio/dio.dart';
import '../core/api_client.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

enum VideoKycSlot { morning, afternoon, evening }

extension VideoKycSlotExt on VideoKycSlot {
  String get value {
    switch (this) {
      case VideoKycSlot.morning:   return 'morning';
      case VideoKycSlot.afternoon: return 'afternoon';
      case VideoKycSlot.evening:   return 'evening';
    }
  }

  String get label {
    switch (this) {
      case VideoKycSlot.morning:   return 'Morning (9 AM – 12 PM)';
      case VideoKycSlot.afternoon: return 'Afternoon (12 PM – 4 PM)';
      case VideoKycSlot.evening:   return 'Evening (4 PM – 7 PM)';
    }
  }

  String get icon {
    switch (this) {
      case VideoKycSlot.morning:   return '🌅';
      case VideoKycSlot.afternoon: return '☀️';
      case VideoKycSlot.evening:   return '🌆';
    }
  }

  static VideoKycSlot? fromString(String? s) {
    switch (s) {
      case 'morning':   return VideoKycSlot.morning;
      case 'afternoon': return VideoKycSlot.afternoon;
      case 'evening':   return VideoKycSlot.evening;
      default:          return null;
    }
  }
}

// ── Model ─────────────────────────────────────────────────────────────────────

class VideoKycRequest {
  final int         id;
  final String      referenceId;
  final String      status;    // scheduled | confirmed | completed | failed | cancelled
  final String      preferredDate;
  final VideoKycSlot preferredSlot;
  final String      callPhone;
  final String?     confirmedSlot;
  final String?     agentNotes;
  final String?     rejectionReason;
  final String      createdAt;

  const VideoKycRequest({
    required this.id,
    required this.referenceId,
    required this.status,
    required this.preferredDate,
    required this.preferredSlot,
    required this.callPhone,
    this.confirmedSlot,
    this.agentNotes,
    this.rejectionReason,
    required this.createdAt,
  });

  factory VideoKycRequest.fromJson(Map<String, dynamic> j) {
    return VideoKycRequest(
      id:              (j['id'] as num).toInt(),
      referenceId:     j['reference_id'] as String? ?? '',
      status:          j['status']       as String? ?? 'scheduled',
      preferredDate:   j['preferred_date'] as String? ?? '',
      preferredSlot:   VideoKycSlotExt.fromString(j['preferred_slot'] as String?) ?? VideoKycSlot.morning,
      callPhone:       j['call_phone']   as String? ?? '',
      confirmedSlot:   j['confirmed_slot'] as String?,
      agentNotes:      j['agent_notes']  as String?,
      rejectionReason: j['rejection_reason'] as String?,
      createdAt:       j['created_at']   as String? ?? '',
    );
  }

  bool get isScheduled  => status == 'scheduled';
  bool get isConfirmed  => status == 'confirmed';
  bool get isCompleted  => status == 'completed';
  bool get isFailed     => status == 'failed';
  bool get isCancelled  => status == 'cancelled';
  bool get isPending    => isScheduled || isConfirmed;
}

class VideoKycResult {
  final bool    success;
  final String? error;
  final VideoKycRequest? data;
  const VideoKycResult({required this.success, this.error, this.data});
}

// ── Service ───────────────────────────────────────────────────────────────────

class VideoKycService {
  static final VideoKycService _i = VideoKycService._();
  factory VideoKycService() => _i;
  VideoKycService._();

  final _api = ApiClient();

  Future<VideoKycRequest?> getStatus() async {
    try {
      final res  = await _api.get('/user/kyc/video');
      final data = res.data['data']?['video_kyc'];
      if (data == null) return null;
      return VideoKycRequest.fromJson(data as Map<String, dynamic>);
    } catch (_) { return null; }
  }

  Future<VideoKycResult> schedule({
    required DateTime      preferredDate,
    required VideoKycSlot  preferredSlot,
    required String        callPhone,
  }) async {
    try {
      final res = await _api.post('/user/kyc/video', data: {
        'preferred_date': preferredDate.toIso8601String().substring(0, 10),
        'preferred_slot': preferredSlot.value,
        'call_phone':     callPhone,
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
          ?? 'Failed to schedule video KYC';
      return VideoKycResult(success: false, error: msg);
    } catch (e) {
      return VideoKycResult(success: false, error: e.toString());
    }
  }

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
}