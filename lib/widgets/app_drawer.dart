import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  final String userName;
  final double walletBalance;
  final Function(String) onMenuItemTap;
  final VoidCallback onClose;

  const AppDrawer({
    super.key,
    required this.userName,
    required this.walletBalance,
    required this.onMenuItemTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      {'icon': Icons.person_outline,    'label': 'Profile'},
      {'icon': Icons.wifi_outlined,      'label': 'New Plans'},
      {'icon': Icons.receipt_outlined,   'label': 'Pays'},
      {'icon': Icons.people_outline,     'label': 'Refer & Earn'},
      {'icon': Icons.badge_outlined,     'label': 'KYC'},
      {'icon': Icons.history_outlined,   'label': 'Transaction History'},
      {'icon': Icons.chat_bubble_outline,'label': 'Support/Chat'},
      {'icon': Icons.info_outline,       'label': 'About Speedonet'},
      {'icon': Icons.lock_outline,       'label': 'Change Password'},
      {'icon': Icons.logout,             'label': 'Logout'},
    ];

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20, right: 20, bottom: 24,
            ),
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 50, height: 50,
                    decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                    child: const Icon(Icons.tv, color: AppColors.primary, size: 24),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.walletBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      const Text('₹', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                      Text(' ${walletBalance.toStringAsFixed(2)}',
                          style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(width: 6),
                      Container(
                        width: 20, height: 14,
                        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(3)),
                        child: const Icon(Icons.credit_card, size: 11, color: AppColors.primary),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onClose,
                    child: const Icon(Icons.close, color: AppColors.white, size: 24),
                  ),
                ]),
                const SizedBox(height: 16),
                Text(
                  userName.isNotEmpty ? userName : 'Welcome',
                  style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),

          // ── Menu items ────────────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: menuItems.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: AppColors.borderColor, indent: 60),
              itemBuilder: (context, index) {
                final item     = menuItems[index];
                final isLogout = item['label'] == 'Logout';
                return ListTile(
                  leading: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: isLogout
                          ? AppColors.primary.withOpacity(0.08)
                          : AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item['icon'] as IconData, size: 20,
                        color: isLogout ? AppColors.primary : AppColors.textDark),
                  ),
                  title: Text(item['label'] as String,
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500,
                        color: isLogout ? AppColors.primary : AppColors.textDark,
                      )),
                  onTap: () => onMenuItemTap(item['label'] as String),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}