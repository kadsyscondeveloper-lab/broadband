// lib/views/notifications/notifications_screen.dart

import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../viewmodels/help_viewmodel.dart';
import '../../viewmodels/kyc_viewmodel.dart';
import '../kyc/kyc_screen.dart';
import '../help/help_screen.dart';
import '../plans/plans_screen.dart';

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

  // ── Navigate based on notification type ───────────────────────────────────

  void _handleNotificationTap(AppNotification notification) async {
    // Mark as read first
    if (!notification.isRead) {
      await _vm.markOneRead(notification.id);
    }

    if (!mounted) return;

    // Try deep_link first (e.g. "ticket:123")
    final deepLink = notification.deepLink;
    if (deepLink != null && deepLink.isNotEmpty) {
      _handleDeepLink(deepLink, notification);
      return;
    }

    // Fall back to type-based routing
    _navigateByType(notification.type, notification);
  }

  void _handleDeepLink(String deepLink, AppNotification notification) {
    // Expected formats: "ticket:123", "kyc", "plan", "wallet"
    if (deepLink.startsWith('ticket:')) {
      final ticketId = int.tryParse(deepLink.split(':').last);
      _openHelpScreen(ticketId: ticketId);
    } else {
      _navigateByType(notification.type, notification);
    }
  }

  void _navigateByType(String type, AppNotification notification) {
    switch (type) {
      case 'kyc':
      case 'kyc_status':
        _openKycScreen();
        break;

      case 'support_ticket':
      // Try to extract ticket ID from body text if deep_link is missing
        final ticketId = _extractTicketId(notification.body);
        _openHelpScreen(ticketId: ticketId);
        break;

      case 'plan_activated':
        _openPlansScreen();
        break;

      case 'wallet_recharge':
      // Navigate back and let the caller handle — wallet is usually a tab
        Navigator.pop(context, 'wallet');
        break;

      case 'referral_rewarded':
      case 'referral':
        Navigator.pop(context, 'refer');
        break;

      default:
      // No navigation for general/unknown types
        break;
    }
  }

  // Try to pull a ticket ID from notification body text
  // e.g. "Your ticket SPT-20241201-AB12CD has been..."
  // We don't have the numeric ID here, so just open the list
  int? _extractTicketId(String body) => null;

  void _openKycScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const KycScreen()),
    );
  }

  void _openHelpScreen({int? ticketId}) {
    final helpVm = HelpViewModel();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HelpScreen(viewModel: helpVm),
      ),
    ).then((_) {
      // If a specific ticket was linked, load its detail after the screen opens
      // (HelpScreen handles this via loadTickets on init)
    });
  }

  void _openPlansScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlansScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          ListenableBuilder(
            listenable: _vm,
            builder: (_, __) {
              if (_vm.unread == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: _vm.markAllRead,
                child: const Text(
                  'Mark all read',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      size: 48, color: AppColors.textLight),
                  const SizedBox(height: 12),
                  Text(_vm.error!,
                      style: const TextStyle(color: AppColors.textGrey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _vm.load,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary),
                    child: const Text('Retry',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          if (_vm.notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded,
                      size: 64, color: AppColors.textLight),
                  SizedBox(height: 12),
                  Text(
                    'No notifications yet',
                    style:
                    TextStyle(color: AppColors.textGrey, fontSize: 15),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: _vm.notifications.length,
            separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 72),
            itemBuilder: (_, i) {
              final n = _vm.notifications[i];
              return _NotificationTile(
                notification: n,
                onTap: () => _handleNotificationTap(n),
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFICATION TILE
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback    onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  // Strip emojis / non-ASCII from backend strings
  String _clean(String text) =>
      text.replaceAll(RegExp(r'[^\x00-\x7F]'), '').trim();

  Color _colorForType(String type) {
    switch (type) {
      case 'plan_activated':    return const Color(0xFF16A34A);
      case 'wallet_recharge':   return const Color(0xFF2563EB);
      case 'support_ticket':    return const Color(0xFFEA580C);
      case 'kyc':
      case 'kyc_status':        return const Color(0xFF9333EA);
      case 'payment':           return const Color(0xFF0D9488);
      case 'offer':             return const Color(0xFFDB2777);
      case 'referral_rewarded':
      case 'referral':          return const Color(0xFFF59E0B);
      default:                  return AppColors.primary;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'plan_activated':    return Icons.wifi_rounded;
      case 'wallet_recharge':   return Icons.account_balance_wallet_rounded;
      case 'support_ticket':    return Icons.headset_mic_rounded;
      case 'kyc':
      case 'kyc_status':        return Icons.verified_user_rounded;
      case 'payment':           return Icons.credit_card_rounded;
      case 'offer':             return Icons.local_offer_rounded;
      case 'referral_rewarded':
      case 'referral':          return Icons.card_giftcard_rounded;
      default:                  return Icons.notifications_rounded;
    }
  }

  /// Whether this notification type has a destination screen to navigate to
  bool _isTappable(String type) {
    const tappableTypes = {
      'kyc',
      'kyc_status',
      'support_ticket',
      'plan_activated',
      'wallet_recharge',
      'referral_rewarded',
      'referral',
    };
    return tappableTypes.contains(type);
  }

  /// Short label shown as a "Go to →" hint for tappable notifications
  String? _destinationLabel(String type) {
    switch (type) {
      case 'kyc':
      case 'kyc_status':        return 'View KYC';
      case 'support_ticket':    return 'View Ticket';
      case 'plan_activated':    return 'View Plans';
      case 'wallet_recharge':   return 'View Wallet';
      case 'referral_rewarded':
      case 'referral':          return 'View Referrals';
      default:                  return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color    = _colorForType(notification.type);
    final isRead   = notification.isRead;
    final tappable = _isTappable(notification.type);
    final destLabel = _destinationLabel(notification.type);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isRead ? Colors.transparent : color.withOpacity(0.04),
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Icon circle ──────────────────────────────────────────────
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_iconForType(notification.type),
                  color: color, size: 22),
            ),
            const SizedBox(width: 14),

            // ── Content ──────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row + unread dot
                  Row(children: [
                    Expanded(
                      child: Text(
                        _clean(notification.title),
                        style: TextStyle(
                          fontWeight:
                          isRead ? FontWeight.w500 : FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle),
                      ),
                  ]),
                  const SizedBox(height: 4),

                  // Body
                  Text(
                    _clean(notification.body),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textGrey,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Time + optional CTA chip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _timeAgo(notification.createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textLight),
                      ),
                      if (tappable && destLabel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                destLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(Icons.arrow_forward_rounded,
                                  size: 10, color: color),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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