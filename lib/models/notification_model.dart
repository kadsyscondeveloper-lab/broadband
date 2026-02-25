import 'package:flutter/material.dart';

class AppNotification {
  final int     id;
  final String  type;
  final String  title;
  final String  body;
  final bool    isRead;
  final String? deepLink;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    this.deepLink,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id:        int.tryParse(j['id'].toString()) ?? 0,
    type:      j['type']      as String? ?? '',
    title:     j['title']     as String? ?? '',
    body:      j['body']      as String? ?? '',
    isRead:    j['is_read']   == true || j['is_read'] == 1,
    deepLink:  j['deep_link'] as String?,
    createdAt: DateTime.tryParse(j['created_at'].toString()) ?? DateTime.now(),
  );

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id:        id,
    type:      type,
    title:     title,
    body:      body,
    isRead:    isRead ?? this.isRead,
    deepLink:  deepLink,
    createdAt: createdAt,
  );

  // Icon and color per notification type
  static IconData iconForType(String type) {
    switch (type) {
      case 'plan_activated':  return Icons.wifi_rounded;
      case 'wallet_recharge': return Icons.account_balance_wallet_rounded;
      case 'support_ticket':  return Icons.support_agent_rounded;
      case 'kyc':             return Icons.badge_rounded;
      default:                return Icons.notifications_rounded;
    }
  }
}