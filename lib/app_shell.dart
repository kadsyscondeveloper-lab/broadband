// lib/app_shell.dart
import 'package:flutter/material.dart';
import 'package:speedonet/views/payment/payment_history_screen.dart';
import 'views/home/home_screen.dart';
import 'views/help/help_screen.dart';
import 'views/pay/pay_screen.dart';
import 'views/profile/profile_screen.dart';
import 'views/wallet/wallet_recharge_screen.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/payments_viewmodel.dart';
import 'viewmodels/help_viewmodel.dart';
import 'viewmodels/pay_viewmodel.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'services/notification_push_service.dart';

class AppShell extends StatefulWidget {
  final VoidCallback onLogout;
  const AppShell({super.key, required this.onLogout});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _currentIndex = 0;

  final _homeVM     = HomeViewModel();
  final _paymentsVM = PaymentsViewModel();
  final _helpVM     = HelpViewModel();
  final _payVM      = PayViewModel();
  final _profileVM  = ProfileViewModel();
  final _auth       = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _homeVM.loadProfile();
    });
    _profileVM.addListener(_onProfileVMChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _homeVM.loadProfile();
    }
  }

  void _onProfileVMChanged() {
    if (!_profileVM.imageUploading && _profileVM.imageError == null) {
      _homeVM.loadProfile();
    }
  }

  /// Shows a confirmation dialog, clears the FCM token, then calls logout.
  /// All screens receive this instead of [widget.onLogout] directly so the
  /// user always gets the confirmation step.
  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Logout',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await NotificationPushService().clearToken();
    await _auth.logout();
    widget.onLogout();
  }

  void _onTabTapped(int index)  => setState(() => _currentIndex = index);
  void _navigateToHome()        => setState(() => _currentIndex = 0);
  void _navigateToProfile()     => setState(() => _currentIndex = 4);
  void _navigateToPay()         => setState(() => _currentIndex = 2);

  void _openWalletRecharge() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WalletRechargeScreen(
          initialBalance:    _homeVM.walletBalance,
          onRechargeSuccess: (double newBalance) {
            _homeVM.loadProfile();
            _payVM.refresh();
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return HomeScreen(
          viewModel:           _homeVM,
          onNavigateToProfile: _navigateToProfile,
          onNavigateToPay:     _navigateToPay,
          onWalletTap:         _openWalletRecharge,
          onLogout:            _handleLogout,   // ← confirmation dialog
        );
      case 1:
        return const PaymentHistoryScreen();
      case 2:
        return PayScreen(viewModel: _payVM);
      case 3:
        return HelpScreen(viewModel: _helpVM);
      case 4:
        return ProfileScreen(
          viewModel:        _profileVM,
          onNavigateToHome: _navigateToHome,
          onLogout:         _handleLogout,     // ← confirmation dialog
        );
      default:
        return HomeScreen(viewModel: _homeVM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body:                _buildBody(),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap:        _onTabTapped,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _profileVM.removeListener(_onProfileVMChanged);
    _homeVM.dispose();
    _paymentsVM.dispose();
    _helpVM.dispose();
    _payVM.dispose();
    _profileVM.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM NAV
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

          // ── Bar ──────────────────────────────────────────────────────────
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
                      _PngNavItem(
                        pngOutline: 'assets/icons/bottom_navigation/house-blank.png',
                        pngFilled:  'assets/icons/bottom_navigation/house-blank_filled.png',
                        label:    'Home',
                        isActive: currentIndex == 0,
                        onTap:    () => onTap(0),
                      ),
                      _PngNavItem(
                        pngOutline: 'assets/icons/bottom_navigation/receipt.png',
                        pngFilled:  'assets/icons/bottom_navigation/receipt_filled.png',
                        label:    'Payments',
                        isActive: currentIndex == 1,
                        onTap:    () => onTap(1),
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

                      _PngNavItem(
                        pngOutline: 'assets/icons/bottom_navigation/support.png',
                        pngFilled:  'assets/icons/bottom_navigation/support_filled.png',
                        label:    'Help',
                        isActive: currentIndex == 3,
                        onTap:    () => onTap(3),
                      ),
                      _PngNavItem(
                        pngOutline: 'assets/icons/bottom_navigation/user.png',
                        pngFilled:  'assets/icons/bottom_navigation/user_filled.png',
                        label:    'Profile',
                        isActive: currentIndex == 4,
                        onTap:    () => onTap(4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Floating Pay button ───────────────────────────────────────────
          Positioned(
            bottom: _barHeight + bottomPad - _btnSize / 2 - _liftAbove + 18,
            child: GestureDetector(
              onTap: () => onTap(2),
              child: Container(
                width:  _btnSize,
                height: _btnSize,
                decoration: BoxDecoration(
                  color:        AppColors.primary,
                  borderRadius: BorderRadius.circular(_btnRadius),
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
// PNG NAV ITEM
// ─────────────────────────────────────────────────────────────────────────────

class _PngNavItem extends StatelessWidget {
  final String pngOutline;
  final String pngFilled;
  final String label;
  final bool   isActive;
  final VoidCallback onTap;

  const _PngNavItem({
    required this.pngOutline,
    required this.pngFilled,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap:    onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              isActive ? pngFilled : pngOutline,
              width:  22,
              height: 22,
              color:          isActive ? null : AppColors.textLight,
              colorBlendMode: isActive ? null : BlendMode.srcIn,
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