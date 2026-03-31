// lib/widgets/app_drawer.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  final String  userName;
  final double  walletBalance;
  final String? profileImageUrl;
  final Function(String) onMenuItemTap;
  final VoidCallback onClose;

  const AppDrawer({
    super.key,
    required this.userName,
    required this.walletBalance,
    this.profileImageUrl,
    required this.onMenuItemTap,
    required this.onClose,
  });

  Widget _buildAvatar() {
    Widget content;
    final url = profileImageUrl;

    if (url != null && url.isNotEmpty) {
      if (url.startsWith('data:')) {
        final base64Part = url.contains(',') ? url.split(',').last : url;
        try {
          content = Image.memory(
            base64Decode(base64Part),
            fit: BoxFit.cover,
            gaplessPlayback: true,
          );
        } catch (_) {
          content = _fallback();
        }
      } else {
        content = Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        );
      }
    } else {
      content = _fallback();
    }

    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }

  Widget _fallback() =>
      const Icon(Icons.tv, color: AppColors.primary, size: 26);

  @override
  Widget build(BuildContext context) {
    // Bottom nav bar (64px) + device safe area + a little breathing room.
    // This ensures Logout scrolls fully above the nav bar on every device.
    final bottomPadding = 64.0 + MediaQuery.of(context).padding.bottom + 16.0;

    final menuItems = [
      {'asset': 'assets/images/profile.png',                'label': 'Profile'},
      {'asset': 'assets/images/new_plan.png',               'label': 'New Plans'},
      {'asset': 'assets/images/pays.png',                   'label': 'Pays'},
      {'asset': 'assets/images/refer&earn.png',             'label': 'Refer & Earn'},
      {'asset': 'assets/images/KYC_icon.png',               'label': 'KYC'},
      {'asset': 'assets/images/transaction_history.png',    'label': 'Transaction History'},
      {'asset': 'assets/images/supportandchat.png',         'label': 'Support/Chat'},
      {'asset': 'assets/images/change_password.png',        'label': 'Change Password'},
      {'asset': 'assets/images/about.png',                  'label': 'About Speedonet'},
      {'asset': 'assets/images/new_plan.png',               'label': 'Installation Status'},
      {'asset': 'assets/images/logout.png',                 'label': 'Logout'},
    ];

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top:    MediaQuery.of(context).padding.top + 16,
              left:   20,
              right:  20,
              bottom: 24,
            ),
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildAvatar(),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.walletBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        const Text('₹',
                            style: TextStyle(
                                color:      AppColors.white,
                                fontWeight: FontWeight.bold)),
                        Text(
                          ' ${walletBalance.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color:      AppColors.white,
                              fontWeight: FontWeight.w700,
                              fontSize:   15),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 20, height: 14,
                          decoration: BoxDecoration(
                              color:        AppColors.white,
                              borderRadius: BorderRadius.circular(3)),
                          child: const Icon(Icons.credit_card,
                              size: 11, color: AppColors.primary),
                        ),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: onClose,
                      child: const Icon(Icons.close,
                          color: AppColors.white, size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  userName.isNotEmpty ? userName : 'Welcome',
                  style: const TextStyle(
                      color:      AppColors.white,
                      fontSize:   20,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),

          // ── Menu items ───────────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              // ✅ FIX: bottom padding = nav bar height + safe area inset.
              // The list content now ends well above the bottom nav so
              // Logout is always fully visible and tappable when scrolled.
              padding: EdgeInsets.only(bottom: bottomPadding),
              physics: const BouncingScrollPhysics(),
              itemCount: menuItems.length,
              separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color:  AppColors.borderColor,
                  indent: 64),
              itemBuilder: (context, index) {
                final item     = menuItems[index];
                final isLogout = item['label'] == 'Logout';

                return ListTile(
                  leading: SizedBox(
                    width:  38,
                    height: 38,
                    child: Image.asset(
                      item['asset']!,
                      fit: BoxFit.contain,
                      color: isLogout ? AppColors.primary : null,
                    ),
                  ),
                  title: Text(
                    item['label']!,
                    style: TextStyle(
                      fontSize:   15,
                      fontWeight: FontWeight.w500,
                      color: isLogout ? AppColors.primary : AppColors.textDark,
                    ),
                  ),
                  onTap: () => onMenuItemTap(item['label']!),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 2),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}