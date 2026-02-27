// lib/views/home/home_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/kyc_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_icons.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_icon.dart';
import '../bills/bills_screens.dart' hide MyBillsScreen;
import '../kyc/kyc_screen.dart';
import '../recharge/wifi_plans_screen.dart';
import '../refer/refer_earn_screen.dart';
import '../bills/my_bills_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/change_password_screen.dart';
import '../help/help_screen.dart';
import '../../viewmodels/help_viewmodel.dart';
import '../plans/plans_screen.dart';


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

  void _openKyc() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const KycScreen()));
    widget.viewModel.refreshKycStatus();
  }

  @override
  Widget build(BuildContext context) {
    final vm           = widget.viewModel;
    final topPadding   = MediaQuery.of(context).padding.top;
    final headerHeight = topPadding + 68.0;
    final bottomNavHeight =
        64 + 16 + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: ListenableBuilder(
        listenable: vm,
        builder: (context, _) => AppDrawer(
          userName:        vm.userName,
          walletBalance:   vm.walletBalance,
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
              case 'Pays':
                widget.onNavigateToPay?.call();
                break;
              case 'Refer & Earn':
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ReferEarnScreen()));
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
                showAboutDialog(
                  context: context,
                  applicationName: 'Speedonet',
                  applicationVersion: '1.0.0',
                );
                break;
              case 'Change Password':
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
                break;
              case 'Logout':
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
                          await AuthService().logout();
                          widget.onLogout?.call();
                        },
                        child: const Text('Logout',
                            style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
                );
                break;
            }
          },
        ),
      ),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          return CustomScrollView(
            slivers: [

              // ── Sticky header ──────────────────────────────────────────
              SliverAppBar(
                pinned:                    true,
                automaticallyImplyLeading: false,
                toolbarHeight:   headerHeight,
                expandedHeight:  headerHeight,
                collapsedHeight: headerHeight,
                elevation:           0,
                backgroundColor: Colors.transparent,
                flexibleSpace: AppHeader(
                  userName:        vm.userName,
                  walletBalance:   vm.walletBalance,
                  profileImageUrl: vm.profileImageUrl,
                  unreadNotifications:   vm.unreadNotifications,
                  onMenuTap: () =>
                      _scaffoldKey.currentState?.openDrawer(),
                  onNotificationTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    );
                    vm.refreshUnreadCount();
                  },
                  onWalletTap: widget.onWalletTap,
                ),
              ),

              // ── Body ───────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      16, 16, 16, bottomNavHeight + 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // 1. KYC status banner
                      if (vm.kycStatus != null && !vm.kycStatus!.isApproved) ...[
                        _KycStatusBanner(kycStatus: vm.kycStatus, onTap: _openKyc),
                        const SizedBox(height: 8),
                      ],

                      // 2. Manage Services
                      _ManageServicesCard(
                        services:       vm.services,
                        onNavigateToPay: widget.onNavigateToPay,
                        onKycTap:        _openKyc,
                        homeViewModel:   vm,
                      ),
                      const SizedBox(height: 16),

                      // 3. Speedo OTT Cards
                      _SpeedoCards(),
                      const SizedBox(height: 16),

                      // 4. Promo Banner (carousel from backend)
                      _PromoBanner(
                        currentIndex: vm.promoBannerIndex,
                        onPageChanged: vm.onPromoBannerPageChanged,
                        viewModel: vm,
                      ),
                      const SizedBox(height: 16),

                      // 5. Features / Refer & Earn
                      _FeaturesSection(
                        currentIndex: vm.featureBannerIndex,
                        onPageChanged: vm.onFeatureBannerPageChanged,
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
      color:        AppColors.reviewBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
          color: AppColors.reviewBorder.withOpacity(0.4)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const AppIcon(AppIcons.info,
            color: Color(0xFF8B6914), size: 10),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('In Review',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize:   15,
                      color:      AppColors.textDark)),
              SizedBox(height: 4),
              Text(
                  "Your KYC documents are under review. We'll notify you once complete.",
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textGrey)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onCheckStatus,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              border:       Border.all(color: const Color(0xFFD4A017)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Check Status',
                style: TextStyle(
                    color:      Color(0xFFD4A017),
                    fontWeight: FontWeight.w700,
                    fontSize:   12)),
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
      color:        Colors.red.shade50,
      borderRadius: BorderRadius.circular(16),
      border:       Border.all(color: Colors.red.shade200),
    ),
    child: Row(children: [
      AppIcon(AppIcons.cancelCircle,
          color: Colors.red.shade600, size: 26),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('KYC Rejected',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize:   15,
                      color:      Colors.red.shade600)),
              const SizedBox(height: 4),
              Text('Please re-submit your documents.',
                  style: TextStyle(
                      fontSize: 12,
                      color:    Colors.red.shade600,
                      height:   1.4)),
            ]),
      ),
      const SizedBox(width: 12),
      GestureDetector(
        onTap: onFix,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color:        Colors.red.shade600,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('Fix Now',
              style: TextStyle(
                  color:      Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize:   12)),
        ),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MANAGE SERVICES
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// MANAGE SERVICES  — replace the existing _ManageServicesCard & _ServiceItem
// ─────────────────────────────────────────────────────────────────────────────

class _ManageServicesCard extends StatelessWidget {
  final List<Map<String, String>> services;
  final VoidCallback?  onNavigateToPay;
  final VoidCallback?  onKycTap;
  final HomeViewModel? homeViewModel;

  const _ManageServicesCard({
    required this.services,
    this.onNavigateToPay,
    this.onKycTap,
    this.homeViewModel,
  });

  String _getImageAsset(String iconKey) {
    switch (iconKey) {
      case 'pay_bills':   return 'assets/images/pay_bills.png';
      case 'new_plan':    return 'assets/images/new_plan.png';
      case 'kyc':         return 'assets/images/KYC_icon.png';
      case 'outstanding': return 'assets/images/outstanding_icon.png';
      case 'my_bills':    return 'assets/images/my_bills.png';
      default:            return 'assets/images/pay_bills.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset:     const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(
          'Manage Services',
          style: TextStyle(
              fontSize:   17,
              fontWeight: FontWeight.w700,
              color:      AppColors.textDark),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: services
              .take(4)
              .map((s) => _ServiceItem(
            imageAsset:      _getImageAsset(s['icon']!),
            label:           s['label']!,
            screenContext:   context,
            onNavigateToPay: onNavigateToPay,
            onKycTap:        onKycTap,
            homeViewModel:   homeViewModel,
          ))
              .toList(),
        ),
        if (services.length > 4) ...[
          const SizedBox(height: 20),
          Row(
            children: services
                .skip(4)
                .map((s) => Padding(
              padding: const EdgeInsets.only(right: 24),
              child: _ServiceItem(
                imageAsset:      _getImageAsset(s['icon']!),
                label:           s['label']!,
                screenContext:   context,
                onNavigateToPay: onNavigateToPay,
                onKycTap:        onKycTap,
                homeViewModel:   homeViewModel,
              ),
            ))
                .toList(),
          ),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ServiceItem extends StatelessWidget {
  final String        imageAsset;
  final String        label;
  final BuildContext  screenContext;
  final VoidCallback?  onNavigateToPay;
  final VoidCallback?  onKycTap;
  final HomeViewModel? homeViewModel;

  const _ServiceItem({
    required this.imageAsset,
    required this.label,
    required this.screenContext,
    this.onNavigateToPay,
    this.onKycTap,
    this.homeViewModel,
  });

  void _onTap() {
    switch (label) {
      case 'Pay Bills':
        onNavigateToPay?.call();
        break;
      case 'KYC':
        onKycTap?.call();
        break;
      case 'Outstanding':
        Navigator.push(screenContext,
            MaterialPageRoute(builder: (_) => const PendingBillsScreen()));
        break;
      case 'My Bills':
        Navigator.push(screenContext,
            MaterialPageRoute(builder: (_) => const MyBillsScreen()));
        break;
      case 'New Plan':
        Navigator.push(
          screenContext,
          MaterialPageRoute(
            builder: (_) => PlansScreen(homeViewModel: homeViewModel),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:    _onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width:  55,
          height: 55,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(4),
          child: Image.asset(
            imageAsset,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 72,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize:   11,
              color:      AppColors.textDark,
              fontWeight: FontWeight.w500,
              height:     1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.visible,
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SPEEDO CARDS
// ─────────────────────────────────────────────────────────────────────────────

class _SpeedoCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
          child: _SpeedoCard(
            title:       'SPEEDO',
            titleSuffix: 'prime',
            isTv:        false,
            subtitle:    'Watch your favourite\nmovies on Speedo Prime',
          )),
      const SizedBox(width: 12),
      Expanded(
          child: _SpeedoCard(
            title:       'SPEEDO',
            titleSuffix: 'TV',
            isTv:        true,
            subtitle:    'Watch all OTT content\nin one place',
          )),
    ]);
  }
}

class _SpeedoCard extends StatelessWidget {
  final String title, titleSuffix, subtitle;
  final bool isTv;
  const _SpeedoCard({
    required this.title,
    required this.titleSuffix,
    required this.isTv,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      constraints: const BoxConstraints(minHeight: 180),
      decoration: BoxDecoration(
        color:        AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset:     const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            isTv ? 'assets/images/speedo_tv.png' : 'assets/images/speedo_prime.png',
            width: 140,
            height: 50,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 8),
          Text(subtitle,
              maxLines: 2,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textGrey, height: 1.4)),
          const SizedBox(height: 8),
          Row(children: [
            const Text('Watch Now',
                style: TextStyle(
                    color:      AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize:   13)),
            const SizedBox(width: 4),
            AppIcon(AppIcons.arrowRight, size: 14, color: AppColors.primary),
          ]),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROMO BANNER (Auto-Scrolling Carousel from Backend)
// Fixes:
//   - Backend Buffer → base64 conversion (done in carousels.js)
//   - Pre-decodes base64 → Uint8List once so PageView never stalls
//   - Shows shimmer while loading instead of disappearing
//   - Auto-scroll timer only starts after images are ready
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
  /// Each entry holds pre-decoded image bytes + metadata
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  late final PageController _pageController;
  int _currentIndex = 0;
  Timer? _autoScrollTimer;

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

      // Decode base64 → Uint8List up front so Image.memory never stalls
      final items = <Map<String, dynamic>>[];
      for (final c in raw) {
        final url = (c['image_url'] as String?) ?? '';
        Uint8List? bytes;
        if (url.startsWith('data:')) {
          try {
            final comma = url.indexOf(',');
            if (comma != -1) {
              bytes = base64Decode(url.substring(comma + 1));
            }
          } catch (_) {
            // corrupt data — skip this banner
          }
        }
        if (bytes != null) {
          items.add({
            'title':    c['title']    ?? '',
            'subtitle': c['subtitle'] ?? '',
            'bytes':    bytes,
          });
        }
      }

      if (mounted) {
        setState(() {
          _items   = items;
          _loading = false;
        });
        // Only start auto-scroll once we have more than one image
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

  @override
  Widget build(BuildContext context) {
    // ── Shimmer placeholder while fetching ───────────────────────────────
    if (_loading) {
      return Container(
        height: 176,
        decoration: BoxDecoration(
          color:        AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color:      Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset:     const Offset(0, 2)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: const _BannerShimmer(),
        ),
      );
    }

    // ── No banners returned / all images corrupt ──────────────────────────
    if (_items.isEmpty) return const SizedBox.shrink();

    // ── Carousel ─────────────────────────────────────────────────────────
    return Container(
      decoration: BoxDecoration(
        color:        AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset:     const Offset(0, 2)),
        ],
      ),
      child: Column(children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: SizedBox(
            height: 160,
            child: PageView.builder(
              controller: _pageController,
              itemCount:  _items.length,
              onPageChanged: (i) {
                setState(() => _currentIndex = i);
                widget.onPageChanged(i);
              },
              itemBuilder: (_, i) {
                final bytes = _items[i]['bytes'] as Uint8List;
                return Image.memory(
                  bytes,
                  fit:   BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.broken_image,
                          color: Colors.grey, size: 32),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Dot indicators — only shown when more than one banner
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
                    color: active
                        ? AppColors.primary
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer placeholder for the banner while images load
// ─────────────────────────────────────────────────────────────────────────────
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
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: 176,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// FEATURES SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _FeaturesSection extends StatefulWidget {
  final int currentIndex;
  final Function(int) onPageChanged;
  const _FeaturesSection(
      {required this.currentIndex, required this.onPageChanged});

  @override
  State<_FeaturesSection> createState() => _FeaturesSectionState();
}

class _FeaturesSectionState extends State<_FeaturesSection> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset:     const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Features',
              style: TextStyle(
                  fontSize:   17,
                  fontWeight: FontWeight.w700,
                  color:      AppColors.textDark)),
          Row(
            children: List.generate(2, (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width:  i == _currentIndex ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == _currentIndex
                    ? AppColors.primary
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            )),
          ),
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
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReferEarnScreen()),
                ),
              ),
              _FeatureSlide(
                imagePath:   'assets/images/support.png',
                title:       'Do You Have a Question?',
                subtitle:    'Get 24x7 resolutions to your queries',
                buttonLabel: 'Chat Now',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HelpScreen(viewModel: HelpViewModel()),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _FeatureSlide extends StatelessWidget {
  final String       imagePath;
  final String       title;
  final String       subtitle;
  final String       buttonLabel;
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          imagePath,
          height: 170,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 16),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize:   16,
                fontWeight: FontWeight.w800,
                color:      AppColors.textDark)),
        const SizedBox(height: 6),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textGrey)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(buttonLabel,
              style: const TextStyle(
                  color:      AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize:   15)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FOOTER
// ─────────────────────────────────────────────────────────────────────────────

class _FooterText extends StatelessWidget {
  const _FooterText();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'With love,\nfrom Speedonet',
        style: TextStyle(
            fontSize:   32,
            fontWeight: FontWeight.w800,
            color:      Color(0xFFCCCCDD),
            height:     1.2),
      ),
    );
  }
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
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('Start KYC',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
        ),
      ),
    ]),
  );
}