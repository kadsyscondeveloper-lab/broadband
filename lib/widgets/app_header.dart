// lib/widgets/app_header.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppHeader extends StatelessWidget {
  final String  userName;
  final double  walletBalance;
  final String? profileImageUrl;       // data URI or HTTPS URL — null = show logo
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMenuTap;
  final VoidCallback? onWalletTap;     // opens recharge screen

  const AppHeader({
    super.key,
    required this.userName,
    required this.walletBalance,
    this.profileImageUrl,
    this.onNotificationTap,
    this.onMenuTap,
    this.onWalletTap,
  });

  // ── Avatar builder ────────────────────────────────────────────────────────

  Widget _buildAvatar() {
    Widget content;

    final url = profileImageUrl;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('data:')) {
        // base64 data URI  →  decode the part after the comma
        final base64Part = url.contains(',') ? url.split(',').last : url;
        try {
          content = Image.memory(
            base64Decode(base64Part),
            fit: BoxFit.cover,
            gaplessPlayback: true,
          );
        } catch (_) {
          content = _fallbackIcon();
        }
      } else {
        // Regular HTTPS URL
        content = Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackIcon(),
        );
      }
    } else {
      content = _fallbackIcon();
    }

    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }

  Widget _fallbackIcon() =>
      const Icon(Icons.tv, color: AppColors.primary, size: 22);

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top:    MediaQuery.of(context).padding.top + 8,
        left:   16,
        right:  16,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // ── Avatar / hamburger ─────────────────────────────────────────
          GestureDetector(
            onTap: onMenuTap,
            child: _buildAvatar(),
          ),
          const SizedBox(width: 12),

          // ── Greeting ───────────────────────────────────────────────────
          Expanded(
            child: Text(
              userName.isNotEmpty ? 'Hi, $userName 👋' : 'Welcome',
              style: const TextStyle(
                color:      AppColors.white,
                fontSize:   17,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // ── Wallet balance chip ────────────────────────────────────────
          GestureDetector(
            onTap: onWalletTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color:        AppColors.walletBg,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color:      Colors.black.withOpacity(0.18),
                    blurRadius: 6,
                    offset:     const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '₹',
                    style: TextStyle(
                      color:      AppColors.white,
                      fontWeight: FontWeight.w800,
                      fontSize:   15,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    walletBalance.toStringAsFixed(2),
                    style: const TextStyle(
                      color:      AppColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize:   15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // "+" hint
                  Container(
                    width:  20,
                    height: 20,
                    decoration: BoxDecoration(
                      color:        Colors.white.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Icon(
                      Icons.add,
                      size:  14,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ── Notifications ──────────────────────────────────────────────
          GestureDetector(
            onTap: onNotificationTap,
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.white,
              size:  26,
            ),
          ),
        ],
      ),
    );
  }
}