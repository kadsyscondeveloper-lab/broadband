import '../core/api_client.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final _api = ApiClient();

  /// GET /user/notifications
  Future<Map<String, dynamic>> getNotifications({int page = 1, int limit = 20}) async {
    final res  = await _api.get('/user/notifications', params: {'page': page, 'limit': limit});
    final data = res.data['data'] as Map<String, dynamic>;
    final meta = res.data['meta'] as Map<String, dynamic>? ?? {};

    final list = (data['notifications'] as List<dynamic>)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();

    return {
      'notifications': list,
      'total':         meta['total'] ?? 0,
      'unread':        meta['unread'] ?? 0,
    };
  }

  /// PATCH /user/notifications/read
  /// Pass null [ids] to mark all as read
  Future<void> markRead({List<int>? ids}) async {
    await _api.patch('/user/notifications/read', data: {'ids': ids});
  }
}