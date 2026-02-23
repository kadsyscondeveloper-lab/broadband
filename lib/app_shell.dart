// lib/app_shell.dart
import 'package:flutter/material.dart';
import 'views/home/home_screen.dart';
import 'views/payments/payments_screen.dart';
import 'views/help/help_screen.dart';
import 'views/pay/pay_screen.dart';
import 'views/profile/profile_screen.dart';
import 'views/wallet/wallet_recharge_screen.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/payments_viewmodel.dart';
import 'viewmodels/help_viewmodel.dart';
import 'viewmodels/pay_viewmodel.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'theme/app_theme.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _homeVM.loadProfile();
      _payVM.loadBalance();
    });
  }

  // ── Navigation helpers ────────────────────────────────────────────────────

  void _onTabTapped(int index)  => setState(() => _currentIndex = index);
  void _navigateToHome()        => setState(() => _currentIndex = 0);
  void _navigateToProfile()     => setState(() => _currentIndex = 4);
  void _navigateToPay()         => setState(() => _currentIndex = 2);

  /// Opens the wallet recharge screen as a full push route.
  /// On success, refreshes the home header balance via [HomeViewModel.loadProfile].
  void _openWalletRecharge() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WalletRechargeScreen(
          initialBalance:   _homeVM.walletBalance,
          onRechargeSuccess: (double newBalance) {
            // Reload profile so the header balance updates immediately
            _homeVM.loadProfile();
            _payVM.loadBalance();
          },
        ),
      ),
    );
  }

  // ── Body builder ──────────────────────────────────────────────────────────

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return HomeScreen(
          viewModel:          _homeVM,
          onNavigateToProfile: _navigateToProfile,
          onNavigateToPay:     _navigateToPay,
          onWalletTap:         _openWalletRecharge, // ← wired here
        );
      case 1:
        return const PaymentsScreen();
      case 2:
        return PayScreen(viewModel: _payVM);
      case 3:
        return HelpScreen(viewModel: _helpVM);
      case 4:
        return ProfileScreen(
          viewModel:       _profileVM,
          onNavigateToHome: _navigateToHome,
        );
      default:
        return HomeScreen(viewModel: _homeVM);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body:              _buildBody(),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap:        _onTabTapped,
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

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM NAV  (unchanged from your original)
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  static const double _barHeight = 64;
  static const double _btnSize   = 60;
  static const double _liftAbove = 16;
  static const double _btnRadius = 20;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: _liftAbove + _barHeight + bottomPad,
      child: Stack(
        clipBehavior: Clip.none,
        alignment:    Alignment.bottomCenter,
        children: [

          // ── Bar ──────────────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: _barHeight + bottomPad,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft:  Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color:      Colors.black.withOpacity(0.10),
                    blurRadius: 20,
                    offset:     const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: _barHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _NavItem(
                        icon:       Icons.home_outlined,
                        activeIcon: Icons.home,
                        label:      'Home',
                        isActive:   currentIndex == 0,
                        onTap:      () => onTap(0),
                      ),
                      _NavItem(
                        icon:       Icons.receipt_long_outlined,
                        activeIcon: Icons.receipt_long,
                        label:      'Payments',
                        isActive:   currentIndex == 1,
                        onTap:      () => onTap(1),
                      ),

                      // Hollow centre — Pay label only
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Pay',
                              style: TextStyle(
                                color: currentIndex == 2
                                    ? AppColors.primary
                                    : AppColors.textLight,
                                fontSize:   10,
                                fontWeight: currentIndex == 2
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),

                      _NavItem(
                        icon:       Icons.headset_mic_outlined,
                        activeIcon: Icons.headset_mic,
                        label:      'Help',
                        isActive:   currentIndex == 3,
                        onTap:      () => onTap(3),
                      ),
                      _NavItem(
                        icon:       Icons.person_outline,
                        activeIcon: Icons.person,
                        label:      'Profile',
                        isActive:   currentIndex == 4,
                        onTap:      () => onTap(4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Floating Pay button ───────────────────────────────────────
          Positioned(
            bottom: _barHeight + bottomPad - _btnSize / 2 - _liftAbove + 18,
            child: GestureDetector(
              onTap: () => onTap(2),
              child: Container(
                width:  _btnSize,
                height: _btnSize,
                decoration: BoxDecoration(
                  color:         AppColors.primary,
                  borderRadius:  BorderRadius.circular(_btnRadius),
                  boxShadow: [
                    BoxShadow(
                      color:      AppColors.primary.withOpacity(0.40),
                      blurRadius: 12,
                      offset:     const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width:  38,
                    height: 38,
                    decoration: BoxDecoration(
                      color:        Colors.white,
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Center(
                      child: Container(
                        width:  26,
                        height: 26,
                        decoration: BoxDecoration(
                          color:  Colors.transparent,
                          shape:  BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.currency_rupee_rounded,
                          color: AppColors.primary,
                          size:  14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NAV ITEM
// ─────────────────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String   label;
  final bool     isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap:     onTap,
        behavior:  HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.textLight,
              size:  22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color:      isActive ? AppColors.primary : AppColors.textLight,
                fontSize:   10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}