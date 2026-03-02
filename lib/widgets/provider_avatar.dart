import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProviderAvatar extends StatelessWidget {
  final Map<String, dynamic> provider;
  final double size;
  final bool isHighlighted;

  const ProviderAvatar({
    super.key,
    required this.provider,
    this.size = 40,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = provider['icon_data'] as String?;
    final iconMime = provider['icon_mime'] as String?;
    final name     = provider['name'] as String? ?? '?';

    if (iconData != null && iconData.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.memory(
          base64Decode(iconData),
          width: size, height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _letterAvatar(name),
        ),
      );
    }

    return _letterAvatar(name);
  }

  Widget _letterAvatar(String name) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: isHighlighted ? AppColors.primary : Colors.grey.shade400,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Center(
        child: Text(
          name[0].toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.35,
          ),
        ),
      ),
    );
  }
}