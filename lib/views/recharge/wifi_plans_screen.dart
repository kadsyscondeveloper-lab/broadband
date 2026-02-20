import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../plans/plans_screen.dart';

class WifiPlansScreen extends StatelessWidget {
  final String providerName;
  final HomeViewModel? homeViewModel; // ← Add this

  const WifiPlansScreen({
    super.key,
    this.providerName = "Speedonet Plans",
    this.homeViewModel, // ← Add this
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
      body: PlansScreen(homeViewModel: homeViewModel), // ← Pass it down
    );
  }
}