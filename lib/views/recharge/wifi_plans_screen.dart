import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../plans/plans_screen.dart';

class WifiPlansScreen extends StatelessWidget {
  final String providerName;

  const WifiPlansScreen({
    super.key,
    this.providerName = "Speedonet Plans",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(providerName),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const PlansScreen(),
    );
  }
}