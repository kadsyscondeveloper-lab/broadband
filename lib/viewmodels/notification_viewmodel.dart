import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationViewModel extends ChangeNotifier {
  final _service = NotificationService();

  List<AppNotification> _notifications = [];
  bool    _isLoading  = false;
  String? _error;
  int     _unread     = 0;
  int     _total      = 0;

  List<AppNotification> get notifications => _notifications;
  bool    get isLoading => _isLoading;
  String? get error     => _error;
  int     get unread    => _unread;
  int     get total     => _total;

  Future<void> load() async {
    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      final result    = await _service.getNotifications();
      _notifications  = result['notifications'] as List<AppNotification>;
      _unread         = result['unread'] as int;
      _total          = result['total']  as int;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    try {
      await _service.markRead(ids: null); // null = mark all
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      _unread = 0;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markOneRead(int id) async {
    try {
      await _service.markRead(ids: [id]);
      _notifications = _notifications.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
      _unread = (_unread - 1).clamp(0, 9999);
      notifyListeners();
    } catch (_) {}
  }
}