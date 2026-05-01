// lib/views/home/home_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/kyc_service.dart';
import '../../services/tutorial_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_icons.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/home_tutorial.dart';
import '../bills/bills_screens.dart' hide MyBillsScreen;
import '../about/about_screen.dart';
import '../kyc/kyc_screen.dart';
import '../../widgets/installation_status_card.dart';
import '../availability/service_availability_screen.dart';
import '../installation/installation_tracker_screen.dart';
import '../refer/refer_earn_screen.dart';
import '../bills/my_bills_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/change_password_screen.dart';
import '../../services/rent_service.dart';
import '../help/help_screen.dart';
import '../../viewmodels/help_viewmodel.dart';
import '../plans/plans_screen.dart';
import 'package:url_launcher/url_launcher.dart';


class HomeScreen extends StatefulWidget {
  final HomeViewModel viewModel;
  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onNavigateToNewPlans;
  final VoidCallback? onNavigateToPay;
  final VoidCallback? onWalletTap;
  final VoidCallback? onLogout;

  const HomeScreen({
    super.key,
    required this.viewModel,
    this.onNavigateToProfile,
    this.onNavigateToNewPlans,
    this.onNavigateToPay,
    this.onWalletTap,
    this.onLogout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final HomeTutorialKeys _tutorialKeys = HomeTutorialKeys();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.loadProfile().then((_) => _maybeLaunchTutorial());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Tutorial ──────────────────────────────────────────────────────────────

  Future<void> _maybeLaunchTutorial() async {
    final should = await TutorialService().shouldShowHomeTutorial();
    if (!should || !mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      HomeTutorial(
        context: context,
        keys: _tutorialKeys,
        scrollController: _scrollController,
      ).show(
        onFinish: TutorialService().markHomeTutorialSeen,
        onSkip: TutorialService().markHomeTutorialSeen,
      );
    });
  }

  void _openInstallationTracker() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const InstallationTrackerScreen()),
    );
  }

  // ── Profile completeness check ────────────────────────────────────────────

  bool _isProfileComplete() {
    final profile = widget.viewModel.profile;
    if (profile == null) return false;
    final addr = profile.address;
    return profile.name.isNotEmpty &&
        addr.address.isNotEmpty &&
        addr.city.isNotEmpty &&
        addr.state.isNotEmpty &&
        addr.pinCode.isNotEmpty;
  }

  void _showProfileRequiredSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileRequiredSheet(
        onGoToProfile: () {
          Navigator.pop(context);
          widget.onNavigateToProfile?.call();
        },
      ),
    );
  }

  // ── Navigation helpers ────────────────────────────────────────────────────

  void _openKyc() async {
    if (!widget.viewModel.isAvailabilityConfirmed) {
      _showAvailabilityRequiredSheet();
      return;
    }
    if (!_isProfileComplete()) {
      _showProfileRequiredSheet();
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const KycScreen()),
    );
    widget.viewModel.refreshKycStatus();
  }

  void _openReferEarn() {
    final vm = widget.viewModel;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReferEarnScreen(
          referralCode: vm.referralCode,
          referralUrl: vm.referralUrl,
        ),
      ),
    );
  }

  void _openAvailabilityCheck() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ServiceAvailabilityScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = topPadding + 68.0;
    final bottomNavHeight = 64 + 16 + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: ListenableBuilder(
        listenable: vm,
        builder: (context, _) => AppDrawer(
          userName: vm.userName,
          walletBalance: vm.walletBalance,
          profileImageUrl: vm.profileImageUrl,
          onClose: () => _scaffoldKey.currentState?.closeDrawer(),
          onMenuItemTap: (item) {
            _scaffoldKey.currentState?.closeDrawer();
            switch (item) {
              case 'Profile':
                widget.onNavigateToProfile?.call();
                break;
              case 'New Plans':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlansScreen(homeViewModel: vm),
                  ),
                );
                break;
              case 'Check Availability':
                _openAvailabilityCheck();
                break;
              case 'Installation Status':
                _openInstallationTracker();
                break;
              case 'Pays':
                widget.onNavigateToPay?.call();
                break;
              case 'Refer & Earn':
                _openReferEarn();
                break;
              case 'KYC':
                _openKyc();
                break;
              case 'Transaction History':
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MyBillsScreen()));
                break;
              case 'Support/Chat':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HelpScreen(viewModel: HelpViewModel()),
                  ),
                );
                break;
              case 'About Speedonet':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                );
                break;
              case 'Change Password':
                Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen()));
                break;
              /* case 'Logout':
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          _scaffoldKey.currentState?.closeDrawer();
                          widget.onLogout?.call();
                        },
                        child: const Text('Logout',
                            style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
                ); */
              case 'Logout':
                _scaffoldKey.currentState?.closeDrawer();
                widget.onLogout?.call();   // AppShell handles dialog + FCM + logout
                break;

            }
          },
        ),
      ),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          return CustomScrollView(
            controller: _scrollController,
            slivers: [

              // ── Sticky header ────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                automaticallyImplyLeading: false,
                toolbarHeight: headerHeight,
                expandedHeight: headerHeight,
                collapsedHeight: headerHeight,
                elevation: 0,
                backgroundColor: Colors.transparent,
                flexibleSpace: AppHeader(
                  userName: vm.userName,
                  walletBalance: vm.walletBalance,
                  profileImageUrl: vm.profileImageUrl,
                  unreadNotifications: vm.unreadNotifications,
                  menuKey: _tutorialKeys.menu,
                  notificationKey: _tutorialKeys.notifications,
                  walletKey: _tutorialKeys.wallet,
                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                  onNotificationTap: () async {
                    final result = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationsScreen()),
                    );
                    vm.refreshUnreadCount();
                    if (!mounted) return;
                    if (result == 'wallet') widget.onWalletTap?.call();
                    if (result == 'refer') _openReferEarn();
                  },
                  onWalletTap: widget.onWalletTap,
                ),
              ),

              // ── Body ─────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, bottomNavHeight + 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // 1. KYC status banner
                      if (vm.kycStatus != null && !vm.kycStatus!.isApproved) ...[
                        _KycStatusBanner(
                            kycStatus: vm.kycStatus, onTap: _openKyc),
                        const SizedBox(height: 8),
                      ],

                      const InstallationStatusCard(),
                      const SizedBox(height: 12),

                      // 2. Manage Services — 2-column rectangular grid
                      _ServicesGrid(
                        services: vm.services,
                        onNavigateToPay: widget.onNavigateToPay,
                        onKycTap: _openKyc,
                        homeViewModel: vm,
                        cardKey: _tutorialKeys.manageServices,
                        payBillsKey: _tutorialKeys.payBills,
                        newPlanKey: _tutorialKeys.newPlan,
                        kycKey: _tutorialKeys.kyc,
                        onAvailabilityRequired: _showAvailabilityRequiredSheet,
                      ),
                      const SizedBox(height: 16),

                      // 3. Promo Banner
                      _PromoBanner(
                        currentIndex: vm.promoBannerIndex,
                        onPageChanged: vm.onPromoBannerPageChanged,
                        viewModel: vm,
                      ),
                      const SizedBox(height: 30),

                      // 4. Features / Refer & Earn
                      _FeaturesSection(
                        currentIndex: vm.featureBannerIndex,
                        onPageChanged: vm.onFeatureBannerPageChanged,
                        onReferTap: _openReferEarn,
                        sectionKey: _tutorialKeys.referEarn,
                      ),
                      const SizedBox(height: 24),

                      const _FooterText(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAvailabilityRequiredSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          24, 12, 24,
          24 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Check Availability First',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const Text(
              'Please check availability before proceeding.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _openAvailabilityCheck();
              },
              child: const Text('Check Availability'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KYC STATUS BANNER
// ─────────────────────────────────────────────────────────────────────────────

class _KycStatusBanner extends StatelessWidget {
  final KycStatus? kycStatus;
  final VoidCallback onTap;
  const _KycStatusBanner({required this.kycStatus, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = kycStatus;
    if (s == null || s.isApproved) return const SizedBox.shrink();
    if (s.isNotSubmitted) return _NotSubmittedBanner(onTap: onTap);
    if (s.isPending)      return _PendingBanner(onCheckStatus: onTap);
    if (s.isRejected)     return _RejectedBanner(onFix: onTap);
    return const SizedBox.shrink();
  }
}

class _PendingBanner extends StatelessWidget {
  final VoidCallback onCheckStatus;
  const _PendingBanner({required this.onCheckStatus});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.reviewBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.reviewBorder.withOpacity(0.4)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const AppIcon(AppIcons.info, color: Color(0xFF8B6914), size: 10),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('In Review',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
                    color: AppColors.textDark)),
            SizedBox(height: 4),
            Text("Your KYC documents are under review. We'll notify you once complete.",
                style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
          ]),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onCheckStatus,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD4A017)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Check Status',
                style: TextStyle(color: Color(0xFFD4A017),
                    fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ),
      ],
    ),
  );
}

class _RejectedBanner extends StatelessWidget {
  final VoidCallback onFix;
  const _RejectedBanner({required this.onFix});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Row(children: [
      AppIcon(AppIcons.cancelCircle, color: Colors.red.shade600, size: 26),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('KYC Rejected',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15,
                  color: Colors.red.shade600)),
          const SizedBox(height: 4),
          Text('Please re-submit your documents.',
              style: TextStyle(fontSize: 12, color: Colors.red.shade600,
                  height: 1.4)),
        ]),
      ),
      const SizedBox(width: 12),
      GestureDetector(
        onTap: onFix,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: Colors.red.shade600,
              borderRadius: BorderRadius.circular(8)),
          child: const Text('Fix Now',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w700, fontSize: 12)),
        ),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MANAGE SERVICES — 2-column rectangular grid
// ─────────────────────────────────────────────────────────────────────────────

class _ServicesGrid extends StatelessWidget {
  final List<Map<String, String>> services;
  final VoidCallback?  onNavigateToPay;
  final VoidCallback?  onKycTap;
  final HomeViewModel? homeViewModel;
  final GlobalKey?     cardKey;
  final GlobalKey?     payBillsKey;
  final GlobalKey?     newPlanKey;
  final GlobalKey?     kycKey;
  final VoidCallback?  onAvailabilityRequired;

  const _ServicesGrid({
    required this.services,
    this.onNavigateToPay,
    this.onKycTap,
    this.homeViewModel,
    this.cardKey,
    this.payBillsKey,
    this.newPlanKey,
    this.kycKey,
    this.onAvailabilityRequired,
  });

  String _assetFor(String iconKey) {
    switch (iconKey) {
      case 'pay_bills':   return 'assets/images/pay_bills.png';
      case 'new_plan':    return 'assets/images/wifi-signal_2888720.png';
      case 'kyc':         return 'assets/images/kyc.png';
      case 'outstanding': return 'assets/images/document_17246597.png';
      case 'my_bills':    return 'assets/images/bills.png';
      case 'collect':     return 'assets/images/collect.png'; // ← your icon
      default:            return 'assets/images/pay_bills.png';
    }
  }

  GlobalKey? _keyFor(String label) {
    switch (label) {
      case 'Pay Bills': return payBillsKey;
      case 'New Plan':  return newPlanKey;
      case 'KYC':       return kycKey;
      default:          return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = <List<Map<String, String>>>[];
    for (var i = 0; i < services.length; i += 2) {
      rows.add(services.sublist(i, (i + 2).clamp(0, services.length)));
    }

    final rentStatus  = homeViewModel?.rentStatus  ?? RentStatus.empty();
    final isCollecting = homeViewModel?.isCollecting ?? false;

    return Column(
      key: cardKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Manage Services',
          style: TextStyle(
            fontSize:   17,
            fontWeight: FontWeight.w700,
            color:      AppColors.textDark,
          ),
        ),
        const SizedBox(height: 14),
        ...rows.map((pair) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: _ServiceRect(
                  imageAsset:             _assetFor(pair[0]['icon']!),
                  label:                  pair[0]['label']!,
                  screenContext:          context,
                  onNavigateToPay:        onNavigateToPay,
                  onKycTap:               onKycTap,
                  homeViewModel:          homeViewModel,
                  tutorialKey:            _keyFor(pair[0]['label']!),
                  onAvailabilityRequired: onAvailabilityRequired,
                  rentStatus:             rentStatus,
                  isCollecting:           isCollecting,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: pair.length > 1
                    ? _ServiceRect(
                  imageAsset:             _assetFor(pair[1]['icon']!),
                  label:                  pair[1]['label']!,
                  screenContext:          context,
                  onNavigateToPay:        onNavigateToPay,
                  onKycTap:               onKycTap,
                  homeViewModel:          homeViewModel,
                  tutorialKey:            _keyFor(pair[1]['label']!),
                  onAvailabilityRequired: onAvailabilityRequired,
                  rentStatus:             rentStatus,
                  isCollecting:           isCollecting,
                )
                    : const SizedBox(),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RECTANGULAR SERVICE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceRect extends StatefulWidget {
  final String        imageAsset;
  final String        label;
  final BuildContext  screenContext;
  final VoidCallback?  onNavigateToPay;
  final VoidCallback?  onKycTap;
  final HomeViewModel? homeViewModel;
  final GlobalKey?     tutorialKey;
  final VoidCallback?  onAvailabilityRequired;
  final RentStatus     rentStatus;
  final bool           isCollecting;

  const _ServiceRect({
    required this.imageAsset,
    required this.label,
    required this.screenContext,
    this.onNavigateToPay,
    this.onKycTap,
    this.homeViewModel,
    this.tutorialKey,
    this.onAvailabilityRequired,
    this.rentStatus       = const RentStatus(hasActivePlan: false),
    this.isCollecting     = false,
  });

  @override
  State<_ServiceRect> createState() => _ServiceRectState();
}

class _ServiceRectState extends State<_ServiceRect>
    with TickerProviderStateMixin {
  // Tap-scale animation (all tiles)
  late final AnimationController _scaleCtrl;
  late final Animation<double>   _scale;

  // Shimmer animation (collect tile only, when active)
  late final AnimationController _shimmerCtrl;
  late final Animation<double>   _shimmerAnim;

  // Pulse animation for icon glow (collect tile only, when active)
  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulse;

  bool get _isCollect    => widget.label == 'Collect';
  bool get _canCollect   => _isCollect && widget.rentStatus.canCollect && !widget.isCollecting;
  bool get _doneToday    => _isCollect && widget.rentStatus.collectedToday;

  @override
  void initState() {
    super.initState();

    // Tap scale
    _scaleCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 110),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut),
    );

    // Shimmer sweep
    _shimmerCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1400),
    );
    _shimmerAnim = Tween<double>(begin: -1.5, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );

    // Icon pulse
    _pulseCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 900),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _syncCollectAnimations();
  }

  @override
  void didUpdateWidget(_ServiceRect old) {
    super.didUpdateWidget(old);
    if (old.rentStatus.canCollect  != widget.rentStatus.canCollect ||
        old.rentStatus.collectedToday != widget.rentStatus.collectedToday) {
      _syncCollectAnimations();
    }
  }

  void _syncCollectAnimations() {
    if (_canCollect) {
      _shimmerCtrl.repeat();
      _pulseCtrl.repeat(reverse: true);
    } else {
      _shimmerCtrl
        ..stop()
        ..reset();
      _pulseCtrl
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _shimmerCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Tap handler ────────────────────────────────────────────────────────────

  Future<void> _onTap() async {
    final ctx = widget.screenContext;

    if (_isCollect) {
      _handleCollectTap(ctx);
      return;
    }

    switch (widget.label) {
      case 'Pay Bills':
        widget.onNavigateToPay?.call();
        break;
      case 'KYC':
        widget.onKycTap?.call();
        break;
      case 'Outstanding':
        Navigator.push(ctx,
            MaterialPageRoute(builder: (_) => const PendingBillsScreen()));
        break;
      case 'My Bills':
        Navigator.push(ctx,
            MaterialPageRoute(builder: (_) => const MyBillsScreen()));
        break;
      case 'New Plan':
        if (!(widget.homeViewModel?.isAvailabilityConfirmed ?? false)) {
          widget.onAvailabilityRequired?.call();
          return;
        }
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => PlansScreen(homeViewModel: widget.homeViewModel),
          ),
        );
        break;
    }
  }

  void _handleCollectTap(BuildContext ctx) async {
    final rent = widget.rentStatus;

    // Already collected today
    if (rent.collectedToday) {
      _showToast(ctx, 'Already collected today. Come back tomorrow! 😊',
          color: const Color(0xFF2E7D32));
      return;
    }

    // No active plan
    if (!rent.hasActivePlan) {
      _showToast(ctx, 'Purchase a plan to start earning daily rent.',
          color: Colors.blueGrey.shade700);
      return;
    }

    // Outside collection window
    if (!rent.inCollectionWindow) {
      _showToast(
        ctx,
        'Rent collection opens at ${rent.windowLabel} ⏰',
        color: Colors.orange.shade700,
      );
      return;
    }

    // Pending collect (should trigger animation already)
    if (rent.pendingRent <= 0) {
      _showToast(ctx, 'No rent accumulated yet. Check back after a day.',
          color: Colors.blueGrey.shade700);
      return;
    }

    // Do collect
    final error = await widget.homeViewModel?.collectRent();
    if (error != null && ctx.mounted) {
      _showToast(ctx, error, color: Colors.red.shade700);
    } else if (ctx.mounted) {
      _showSuccessToast(ctx, rent.pendingRent);
    }
  }

  void _showToast(BuildContext ctx, String msg, {required Color color}) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content:         Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: color,
        behavior:        SnackBarBehavior.floating,
        shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin:          const EdgeInsets.all(16),
        duration:        const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessToast(BuildContext ctx, double amount) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              '₹${amount.toStringAsFixed(2)} added to your wallet!',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        behavior:        SnackBarBehavior.floating,
        shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin:          const EdgeInsets.all(16),
        duration:        const Duration(seconds: 4),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key:         widget.tutorialKey,
      onTapDown:   (_) => _scaleCtrl.forward(),
      onTapUp:     (_) { _scaleCtrl.reverse(); _onTap(); },
      onTapCancel: ()  => _scaleCtrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: _isCollect ? _buildCollectCard() : _buildRegularCard(),
      ),
    );
  }

  // ── Regular tile (all non-collect) ────────────────────────────────────────

  Widget _buildRegularCard() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color:        AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.055),
            blurRadius: 8,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize:   13.5,
                fontWeight: FontWeight.w600,
                color:      AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width:  64,
            height: 64,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(widget.imageAsset, fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }

  // ── Collect tile (three states) ───────────────────────────────────────────

  Widget _buildCollectCard() {
    if (_doneToday) return _buildCollectDone();
    if (_canCollect) return _buildCollectActive();
    return _buildCollectIdle();
  }

  // State 1: Outside window / no plan — looks like a normal card but muted
  Widget _buildCollectIdle() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color:        AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.055),
            blurRadius: 8,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Collect',
                  style: TextStyle(
                    fontSize:   13.5,
                    fontWeight: FontWeight.w600,
                    color:      AppColors.textDark,
                  ),
                ),
                if (widget.rentStatus.hasActivePlan)
                  Text(
                    widget.rentStatus.windowLabel,
                    style: TextStyle(
                      fontSize: 10,
                      color:    Colors.orange.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width:  64,
            height: 64,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:        Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(widget.imageAsset, fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }

  // State 2: Collection window is open — shimmer + pulse
  Widget _buildCollectActive() {
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (context, child) {
        return Container(
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            // Base dark background
            color: const Color(0xFF1A1A2E),
            boxShadow: [
              BoxShadow(
                color:      Colors.amber.withOpacity(0.35),
                blurRadius: 14,
                offset:     const Offset(0, 4),
              ),
              BoxShadow(
                color:      const Color(0xFF1A1A2E).withOpacity(0.3),
                blurRadius: 8,
                offset:     const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                // Sweeping shimmer overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(_shimmerAnim.value - 1, -0.5),
                        end:   Alignment(_shimmerAnim.value,      0.5),
                        colors: const [
                          Colors.transparent,
                          Color(0x33F5A623), // amber glow mid
                          Color(0x55F5A623),
                          Color(0x33F5A623),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
                // Card content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Collect',
                              style: TextStyle(
                                fontSize:   13.5,
                                fontWeight: FontWeight.w700,
                                color:      Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.isCollecting
                                  ? 'Collecting…'
                                  : '₹${widget.rentStatus.pendingRent.toStringAsFixed(2)} ready',
                              style: TextStyle(
                                fontSize:   11,
                                fontWeight: FontWeight.w600,
                                color:      Colors.amber.shade300,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Pulsing icon container
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, __) => Transform.scale(
                          scale: _pulse.value,
                          child: Container(
                            width:  60,
                            height: 60,
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end:   Alignment.bottomRight,
                                colors: [
                                  Colors.amber.shade400,
                                  Colors.amber.shade700,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:      Colors.amber.withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: widget.isCollecting
                                ? const Center(
                              child: SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:       Colors.white,
                                ),
                              ),
                            )
                                : Image.asset(
                              widget.imageAsset,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // State 3: Already collected today — green / done
  Widget _buildCollectDone() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color:        const Color(0xFFEDF7EE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Collected',
                  style: TextStyle(
                    fontSize:   13.5,
                    fontWeight: FontWeight.w700,
                    color:      Color(0xFF2E7D32),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Come back tomorrow',
                  style: TextStyle(
                    fontSize: 10,
                    color:    Color(0xFF4CAF50),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width:  64,
            height: 64,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:        const Color(0xFF4CAF50).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Center(child: Image.asset(widget.imageAsset, fit: BoxFit.contain)),
                // Green checkmark badge
                Positioned(
                  right: 0, top: 0,
                  child: Container(
                    width:  16, height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 10, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROMO BANNER
// ─────────────────────────────────────────────────────────────────────────────

class _PromoBanner extends StatefulWidget {
  final int currentIndex;
  final Function(int) onPageChanged;
  final HomeViewModel? viewModel;

  const _PromoBanner({
    required this.currentIndex,
    required this.onPageChanged,
    this.viewModel,
  });

  @override
  State<_PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<_PromoBanner> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  late final PageController _pageController;
  int _currentIndex = 0;
  Timer? _autoScrollTimer;

  static const double _bannerHeight = 220.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAndDecode());
  }

  Future<void> _fetchAndDecode() async {
    if (widget.viewModel == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final raw = await widget.viewModel!.getCarousels();
      final items = <Map<String, dynamic>>[];

      for (final c in raw) {
        final url = (c['image_url'] as String?) ?? '';
        Uint8List? bytes;
        if (url.startsWith('data:')) {
          try {
            final comma = url.indexOf(',');
            if (comma != -1) bytes = base64Decode(url.substring(comma + 1));
          } catch (_) {}
        }
        if (bytes != null) {
          items.add({
            'title':     c['title']    ?? '',
            'subtitle':  c['subtitle'] ?? '',
            'bytes':     bytes,
            'id':        c['id'],
            'click_url': c['click_url'],
          });
        }
      }

      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
        if (_items.length > 1) _startAutoScroll();
      }
    } catch (e) {
      debugPrint('PromoBanner fetch error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _items.isEmpty) return;
      final next = (_currentIndex + 1) % _items.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onBannerTap(Map<String, dynamic> item) async {
    final clickUrl = item['click_url'] as String?;
    final id       = item['id'];

    if (id != null) {
      final int parsedId = id is int ? id : int.tryParse(id.toString()) ?? 0;
      if (parsedId > 0) widget.viewModel?.trackCarouselClick(parsedId);
    }

    if (clickUrl != null && clickUrl.isNotEmpty) {
      final uri = Uri.tryParse(clickUrl);
      if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: _bannerHeight + 40,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05),
                blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: const _BannerShimmer(),
        ),
      );
    }

    if (_items.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(16),
              bottom: _items.length <= 1
                  ? const Radius.circular(16)
                  : Radius.zero,
            ),
            child: SizedBox(
              height: _bannerHeight,
              child: PageView.builder(
                controller: _pageController,
                itemCount:  _items.length,
                onPageChanged: (i) {
                  setState(() => _currentIndex = i);
                  widget.onPageChanged(i);
                },
                itemBuilder: (_, i) {
                  final item  = _items[i];
                  final bytes = item['bytes'] as Uint8List;
                  final hasLink = (item['click_url'] as String?) != null &&
                      (item['click_url'] as String).isNotEmpty;

                  return GestureDetector(
                    onTap: () => _onBannerTap(item),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(
                          color: Colors.black,
                          child: Image.memory(
                            bytes,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: _bannerHeight,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(Icons.broken_image,
                                    color: Colors.grey, size: 32),
                              ),
                            ),
                          ),
                        ),
                        if (hasLink)
                          Positioned(
                            right: 10, bottom: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.open_in_new,
                                      color: Colors.white, size: 11),
                                  SizedBox(width: 4),
                                  Text('Tap to open',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 10)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          if (_items.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_items.length, (i) {
                  final active = i == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width:  active ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Shimmer ────────────────────────────────────────────────────────────────

class _BannerShimmer extends StatefulWidget {
  const _BannerShimmer();
  @override
  State<_BannerShimmer> createState() => _BannerShimmerState();
}

class _BannerShimmerState extends State<_BannerShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _anim = Tween<double>(begin: -1.5, end: 1.5).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Container(
      height: 260,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(_anim.value - 1, 0),
          end:   Alignment(_anim.value,      0),
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade100,
            Colors.grey.shade200,
          ],
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// FEATURES SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _FeaturesSection extends StatefulWidget {
  final int           currentIndex;
  final Function(int) onPageChanged;
  final VoidCallback  onReferTap;
  final GlobalKey?    sectionKey;

  const _FeaturesSection({
    required this.currentIndex,
    required this.onPageChanged,
    required this.onReferTap,
    this.sectionKey,
  });

  @override
  State<_FeaturesSection> createState() => _FeaturesSectionState();
}

class _FeaturesSectionState extends State<_FeaturesSection> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() { super.initState(); _pageController = PageController(); }

  @override
  void dispose() { _pageController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      key:     widget.sectionKey,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Features',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
          Row(children: List.generate(2, (i) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width:  i == _currentIndex ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == _currentIndex
                  ? AppColors.primary
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ))),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 340,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              widget.onPageChanged(index);
            },
            children: [
              _FeatureSlide(
                imagePath:   'assets/images/refer_friend.png',
                title:       'More Refer More Rewards',
                subtitle:    'Refer your friend and win exciting prizes!',
                buttonLabel: 'Refer Now',
                onTap:       widget.onReferTap,
              ),
              _FeatureSlide(
                imagePath:   'assets/images/support.png',
                title:       'Do You Have a Question?',
                subtitle:    'Get 24x7 resolutions to your queries',
                buttonLabel: 'Chat Now',
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => HelpScreen(viewModel: HelpViewModel()))),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _FeatureSlide extends StatelessWidget {
  final String imagePath, title, subtitle, buttonLabel;
  final VoidCallback onTap;

  const _FeatureSlide({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Image.asset(imagePath, height: 170, fit: BoxFit.contain),
      const SizedBox(height: 16),
      Text(title, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
              color: AppColors.textDark)),
      const SizedBox(height: 6),
      Text(subtitle, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(buttonLabel,
            style: const TextStyle(color: AppColors.white,
                fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FOOTER
// ─────────────────────────────────────────────────────────────────────────────

class _FooterText extends StatelessWidget {
  const _FooterText();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Text('With love,\nfrom Speedonet',
        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800,
            color: Color(0xFFCCCCDD), height: 1.2)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// KYC NOT SUBMITTED BANNER
// ─────────────────────────────────────────────────────────────────────────────

class _NotSubmittedBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _NotSubmittedBanner({required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.blue.shade200),
    ),
    child: Row(children: [
      Icon(Icons.verified_user_outlined, color: Colors.blue.shade600, size: 26),
      const SizedBox(width: 12),
      const Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Complete Your KYC',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          SizedBox(height: 4),
          Text('Verify your identity to unlock all features.',
              style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
        ]),
      ),
      const SizedBox(width: 12),
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: BorderRadius.circular(8)),
          child: const Text('Start KYC',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w700, fontSize: 12)),
        ),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE REQUIRED SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileRequiredSheet extends StatelessWidget {
  final VoidCallback onGoToProfile;
  const _ProfileRequiredSheet({required this.onGoToProfile});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 12, 24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withOpacity(0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline_rounded,
                size: 36, color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Complete Your Profile First',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Before submitting KYC documents, please fill in your '
                'name and address details in your profile. This helps us '
                'verify your identity accurately.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: Color(0xFF666680), height: 1.6),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Required fields:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: Color(0xFF888899)),
                ),
                const SizedBox(height: 10),
                ...['Full name', 'House / flat number', 'Street address',
                  'City', 'State', 'PIN code'].map(
                      (field) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          size: 16, color: Color(0xFF1A1A2E)),
                      const SizedBox(width: 8),
                      Text(field,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF1A1A2E))),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onGoToProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A2E),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text(
                'Complete Profile',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later',
                style: TextStyle(color: Color(0xFF999999), fontSize: 13)),
          ),
        ],
      ),
    );
  }
}