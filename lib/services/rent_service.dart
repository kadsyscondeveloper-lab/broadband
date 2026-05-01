// lib/services/rent_service.dart

import 'package:dio/dio.dart';
import '../core/api_client.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class RentStatus {
  final bool    hasActivePlan;
  final String? planName;
  final double  dailyRent;
  final double  pendingRent;
  final double  totalCollected;
  final bool    canCollect;
  final bool    collectedToday;
  final bool    inCollectionWindow;
  final String  windowLabel;
  final String? message;

  const RentStatus({
    required this.hasActivePlan,
    this.planName,
    this.dailyRent        = 0,
    this.pendingRent      = 0,
    this.totalCollected   = 0,
    this.canCollect       = false,
    this.collectedToday   = false,
    this.inCollectionWindow = false,
    this.windowLabel      = '',
    this.message,
  });

  factory RentStatus.fromJson(Map<String, dynamic> j) => RentStatus(
    hasActivePlan:      j['hasActivePlan']      as bool?  ?? false,
    planName:           j['planName']            as String?,
    dailyRent:          (j['dailyRent']          as num?)?.toDouble() ?? 0,
    pendingRent:        (j['pendingRent']         as num?)?.toDouble() ?? 0,
    totalCollected:     (j['totalCollected']      as num?)?.toDouble() ?? 0,
    canCollect:         j['canCollect']           as bool?  ?? false,
    collectedToday:     j['collectedToday']       as bool?  ?? false,
    inCollectionWindow: j['inCollectionWindow']   as bool?  ?? false,
    windowLabel:        j['windowLabel']          as String? ?? '',
    message:            j['message']              as String?,
  );

  factory RentStatus.empty() => const RentStatus(hasActivePlan: false);
}

class RentCollectResult {
  final bool    success;
  final double  amount;
  final double  balanceAfter;
  final String? planName;
  final String? error;

  const RentCollectResult({
    required this.success,
    this.amount      = 0,
    this.balanceAfter = 0,
    this.planName,
    this.error,
  });
}

// ── Service ───────────────────────────────────────────────────────────────────

class RentService {
  static final RentService _i = RentService._();
  factory RentService() => _i;
  RentService._();

  final _api = ApiClient();

  /// GET /rent/status
  Future<RentStatus> getStatus() async {
    try {
      final res = await _api.get('/rent/status');
      return RentStatus.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (_) {
      return RentStatus.empty();
    }
  }

  /// POST /rent/collect
  Future<RentCollectResult> collect() async {
    try {
      final res  = await _api.post('/rent/collect');
      final data = res.data['data'] as Map<String, dynamic>;
      return RentCollectResult(
        success:      true,
        amount:       (data['amount']      as num).toDouble(),
        balanceAfter: (data['balanceAfter'] as num).toDouble(),
        planName:     data['planName']     as String?,
      );
    } on DioException catch (e) {
      return RentCollectResult(
        success: false,
        error:   ApiException.fromDio(e).message,
      );
    } catch (e) {
      return RentCollectResult(success: false, error: e.toString());
    }
  }
}