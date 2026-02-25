import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/notification_viewmodel.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = NotificationViewModel();
    _vm.load();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          ListenableBuilder(
            listenable: _vm,
            builder: (_, __) {
              if (_vm.unread == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: _vm.markAllRead,
                child: const Text('Mark all read',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          if (_vm.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (_vm.error != null) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.wifi_off_outlined, size: 48, color: AppColors.textLight),
                const SizedBox(height: 12),
                Text(_vm.error!, style: const TextStyle(color: AppColors.textGrey)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _vm.load,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Retry', style: TextStyle(color: Colors.white)),
                ),
              ]),
            );
          }

          if (_vm.notifications.isEmpty) {
            return const Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.notifications_none_rounded, size: 64, color: AppColors.textLight),
                SizedBox(height: 12),
                Text('No notifications yet',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 15)),
              ]),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: _vm.notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (_, i) {
              final n = _vm.notifications[i];
              return _NotificationTile(
                notification: n,
                onTap: () => _vm.markOneRead(n.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback    onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  Color _colorForType(String type) {
    switch (type) {
      case 'plan_activated':  return Colors.green;
      case 'wallet_recharge': return Colors.blue;
      case 'support_ticket':  return Colors.orange;
      case 'kyc':             return Colors.purple;
      default:                return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color  = _colorForType(notification.type);
    final isRead = notification.isRead;

    return InkWell(
      onTap: isRead ? null : onTap,
      child: Container(
        color: isRead ? Colors.transparent : color.withOpacity(0.04),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Icon
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color:        color.withOpacity(0.12),
              shape:        BoxShape.circle,
            ),
            child: Icon(AppNotification.iconForType(notification.type),
                color: color, size: 22),
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(notification.title,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textDark,
                    )),
              ),
              if (!isRead)
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
            ]),
            const SizedBox(height: 4),
            Text(notification.body,
                style: const TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.4)),
            const SizedBox(height: 6),
            Text(
              _timeAgo(notification.createdAt),
              style: const TextStyle(fontSize: 11, color: AppColors.textLight),
            ),
          ])),
        ]),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    if (diff.inDays    < 7)  return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}