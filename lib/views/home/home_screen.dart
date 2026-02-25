// lib/views/home/home_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../services/kyc_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_icons.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_icon.dart';
import '../kyc/kyc_screen.dart';
import '../recharge/wifi_plans_screen.dart';
import '../refer/refer_earn_screen.dart';
import '../bills/bills_screens.dart';


class HomeScreen extends StatefulWidget {
  final HomeViewModel viewModel;
  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onNavigateToNewPlans;
  final VoidCallback? onNavigateToPay;
  final VoidCallback? onWalletTap;

  const HomeScreen({
    super.key,
    required this.viewModel,
    this.onNavigateToProfile,
    this.onNavigateToNewPlans,
    this.onNavigateToPay,
    this.onWalletTap,
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
          profileImageUrl: vm.profileImageUrl,   // ← avatar in drawer header
          onClose: () => _scaffoldKey.currentState?.closeDrawer(),
          onMenuItemTap: (item) {
            _scaffoldKey.currentState?.closeDrawer();
            switch (item) {
              case 'Profile':
                widget.onNavigateToProfile?.call();
                break;
              case 'New Plans':
                widget.onNavigateToNewPlans?.call();
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
              // TODO: Navigator.push to your chat/support screen
                break;
              case 'About Speedonet':
                showAboutDialog(
                  context: context,
                  applicationName: 'Speedonet',
                  applicationVersion: '1.0.0',
                );
                break;
              case 'Change Password':
              // TODO: Navigator.push to your change password screen
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
                        onPressed: () {
                          Navigator.pop(ctx);
                          // TODO: clear session and navigate to login
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
                  profileImageUrl: vm.profileImageUrl,   // ← avatar in header
                  onMenuTap: () =>
                      _scaffoldKey.currentState?.openDrawer(),
                  onNotificationTap: () {},
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

                      // 1. KYC status banner — only adds spacing when visible
                      if (vm.kycStatus != null && !vm.kycStatus!.isNotSubmitted && !vm.kycStatus!.isApproved) ...[
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

                      // 4. Promo Banner
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
    if (s == null || s.isNotSubmitted || s.isApproved) {
      return const SizedBox.shrink();
    }
    if (s.isPending)  return _PendingBanner(onCheckStatus: onTap);
    if (s.isRejected) return _RejectedBanner(onFix: onTap);
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

  dynamic _getIcon(String iconKey) {
    switch (iconKey) {
      case 'pay_bills':   return PhosphorIcons.creditCard();
      case 'new_plan':    return PhosphorIcons.wifiHigh();
      case 'kyc':         return PhosphorIcons.identificationCard();
      case 'outstanding': return PhosphorIcons.clockClockwise();
      case 'my_bills':    return PhosphorIcons.clipboardText();
      default:            return PhosphorIcons.plus();
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
        const Text('Manage Services',
            style: TextStyle(
                fontSize:   17,
                fontWeight: FontWeight.w700,
                color:      AppColors.textDark)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: services
              .take(4)
              .map((s) => _ServiceItem(
            icon:            _getIcon(s['icon']!),
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
              padding: const EdgeInsets.only(right: 16),
              child: _ServiceItem(
                icon:            _getIcon(s['icon']!),
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

class _ServiceItem extends StatelessWidget {
  final dynamic icon;
  final String    label;
  final BuildContext screenContext;
  final VoidCallback?  onNavigateToPay;
  final VoidCallback?  onKycTap;
  final HomeViewModel? homeViewModel;

  const _ServiceItem({
    required this.icon,
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
            builder: (_) =>
                WifiPlansScreen(homeViewModel: homeViewModel),
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
          width:  44,
          height: 44,
          decoration: BoxDecoration(
            color:  Colors.white,
            shape:  BoxShape.circle,
            border: Border.all(
                color: AppColors.borderColor, width: 1.5),
          ),
          child: PhosphorIcon(icon, color: AppColors.textDark, size: 20),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 64,
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
  List<dynamic> carousels = [];
  bool isLoading = true;
  late PageController _pageController;
  int _currentIndex = 0;
  late Timer _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Delay fetch until after build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCarousels();
      _startAutoScroll();
    });
  }

  Future<void> _fetchCarousels() async {
    if (widget.viewModel == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final response = await widget.viewModel!.getCarousels();
      if (mounted) {
        setState(() {
          carousels = response;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching carousels: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(Duration(seconds: 4), (_) {
      if (carousels.isNotEmpty && mounted) {
        final nextIndex = (_currentIndex + 1) % carousels.length;
        _pageController.animateToPage(
          nextIndex,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || carousels.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
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
      child: Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 160,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                widget.onPageChanged(index);
              },
              itemCount: carousels.length,
              itemBuilder: (context, index) {
                final carousel = carousels[index];
                final imageUrl = carousel['image_url'] ?? '';

                // Handle base64 data URLs
                if (imageUrl.startsWith('data:')) {
                  try {
                    final parts = imageUrl.split(',');
                    if (parts.length == 2) {
                      return Image.memory(
                        base64Decode(parts[1]),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    print('Error decoding base64: $e');
                  }
                }

                // Handle regular network URLs
                return Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              carousels.length,
                  (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width:  i == _currentIndex ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _currentIndex
                      ? AppColors.primary
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ]),
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
                  // TODO: navigate to support / chat screen
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
