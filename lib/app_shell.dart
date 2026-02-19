import 'package:flutter/material.dart';
import 'views/home/home_screen.dart';
import 'views/payments/payments_screen.dart';
import 'views/help/help_screen.dart';
import 'views/pay/pay_screen.dart';
import 'views/profile/profile_screen.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/payments_viewmodel.dart';
import 'viewmodels/help_viewmodel.dart';
import 'viewmodels/pay_viewmodel.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'widgets/app_bottom_nav.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final _homeVM     = HomeViewModel();
  final _paymentsVM = PaymentsViewModel();
  final _helpVM     = HelpViewModel();
  final _payVM      = PayViewModel();
  final _profileVM  = ProfileViewModel();

  @override
  void initState() {
    super.initState();
    // Load real profile data as soon as the shell mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _homeVM.loadProfile();
    });
  }

  void _onTabTapped(int index) => setState(() => _currentIndex = index);
  void _navigateToHome()       => setState(() => _currentIndex = 0);
  void _navigateToProfile()    => setState(() => _currentIndex = 4);
  void _navigateToPay()        => setState(() => _currentIndex = 2);

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return HomeScreen(
          viewModel: _homeVM,
          onNavigateToProfile: _navigateToProfile,
          onNavigateToPay: _navigateToPay,
        );
      case 1:
        return PaymentsScreen(viewModel: _paymentsVM);
      case 2:
        return PayScreen(viewModel: _payVM);
      case 3:
        return HelpScreen(viewModel: _helpVM);
      case 4:
        return ProfileScreen(
          viewModel: _profileVM,
          onNavigateToHome: _navigateToHome,
        );
      default:
        return HomeScreen(viewModel: _homeVM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  @override
  void dispose() {
    _homeVM.dispose();
    _paymentsVM.dispose();
    _helpVM.dispose();
    _payVM.dispose();
    _profileVM.dispose();
    super.dispose();
  }
}