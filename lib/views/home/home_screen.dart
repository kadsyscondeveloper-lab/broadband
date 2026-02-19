import 'package:flutter/material.dart';
import '../../services/kyc_service.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/dashboard_section.dart';
import '../kyc/kyc_screen.dart';
import '../recharge/wifi_plans_screen.dart';
import '../refer/refer_earn_screen.dart';
import '../bills/bills_screens.dart';

class HomeScreen extends StatefulWidget {
  final HomeViewModel viewModel;
  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onNavigateToNewPlans;
  final VoidCallback? onNavigateToPay;

  const HomeScreen({
    super.key,
    required this.viewModel,
    this.onNavigateToProfile,
    this.onNavigateToNewPlans,
    this.onNavigateToPay,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openKyc() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const KycScreen()));
    widget.viewModel.refreshKycStatus();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: ListenableBuilder(
        listenable: vm,
        builder: (context, _) => AppDrawer(
          userName: vm.userName,
          walletBalance: vm.walletBalance,
          onClose: () => _scaffoldKey.currentState?.closeDrawer(),
          onMenuItemTap: (item) {
            _scaffoldKey.currentState?.closeDrawer();
            switch (item) {
              case 'Profile':  widget.onNavigateToProfile?.call(); break;
              case 'KYC':      _openKyc(); break;
              case 'Refer & Earn':
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferEarnScreen()));
                break;
              case 'New Plans': widget.onNavigateToNewPlans?.call(); break;
            }
          },
        ),
      ),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: AppHeader(
                  userName: vm.userName,
                  walletBalance: vm.walletBalance,
                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                  onNotificationTap: () {},
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // 1. ── My Connection (no title) ─────────────────
                      DashboardSection(
                        data: vm.dashboardData,
                        onPayNow: widget.onNavigateToPay,
                      ),
                      const SizedBox(height: 16),

                      // 2. ── KYC Status Banner ─────────────────────────
                      _KycStatusBanner(kycStatus: vm.kycStatus, onTap: _openKyc),
                      const SizedBox(height: 16),

                      // 3. ── Manage Services ───────────────────────────
                      _ManageServicesCard(
                        services: vm.services,
                        onNavigateToPay: widget.onNavigateToPay,
                        onKycTap: _openKyc,
                      ),
                      const SizedBox(height: 16),

                      // 4. ── Speedo OTT Cards ──────────────────────────
                      _SpeedoCards(),
                      const SizedBox(height: 16),

                      // 5. ── Promo Banner ──────────────────────────────
                      _PromoBanner(
                        currentIndex: vm.promoBannerIndex,
                        onPageChanged: vm.onPromoBannerPageChanged,
                      ),
                      const SizedBox(height: 16),

                      // 6. ── Refer & Earn ──────────────────────────────
                      _FeaturesSection(
                        currentIndex: vm.featureBannerIndex,
                        onPageChanged: vm.onFeatureBannerPageChanged,
                      ),
                      const SizedBox(height: 24),
                      const _FooterText(),
                      const SizedBox(height: 20),
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
    if (s == null || s.isNotSubmitted) return const SizedBox.shrink();
    if (s.isApproved) return _ApprovedBanner();
    if (s.isPending)  return _PendingBanner(onCheckStatus: onTap);
    if (s.isRejected) return _RejectedBanner(onFix: onTap);
    return const SizedBox.shrink();
  }
}

class _ApprovedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.green.withOpacity(0.4)),
    ),
    child: const Row(children: [
      Icon(Icons.verified_rounded, color: Colors.green, size: 26),
      SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('KYC Verified ✓',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.green)),
        SizedBox(height: 4),
        Text('Your identity has been successfully verified.',
            style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32), height: 1.4)),
      ])),
    ]),
  );
}

class _PendingBanner extends StatelessWidget {
  final VoidCallback onCheckStatus;
  const _PendingBanner({required this.onCheckStatus});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.reviewBg, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.reviewBorder.withOpacity(0.4)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      const Icon(Icons.info, color: Color(0xFF8B6914), size: 22),
      const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('In Review',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textDark)),
        SizedBox(height: 4),
        Text("Your KYC documents are under review. We'll notify you once complete.",
            style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
      ])),
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
              style: TextStyle(color: Color(0xFFD4A017), fontWeight: FontWeight.w700, fontSize: 12)),
        ),
      ),
    ]),
  );
}

class _RejectedBanner extends StatelessWidget {
  final VoidCallback onFix;
  const _RejectedBanner({required this.onFix});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.red.shade50, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Row(children: [
      Icon(Icons.cancel_rounded, color: Colors.red.shade600, size: 26),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('KYC Rejected',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.red.shade600)),
        const SizedBox(height: 4),
        Text('Please re-submit your documents.',
            style: TextStyle(fontSize: 12, color: Colors.red.shade600, height: 1.4)),
      ])),
      const SizedBox(width: 12),
      GestureDetector(
        onTap: onFix,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.shade600, borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('Fix Now',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
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
  final VoidCallback? onNavigateToPay;
  final VoidCallback? onKycTap;

  const _ManageServicesCard({required this.services, this.onNavigateToPay, this.onKycTap});

  IconData _getIcon(String iconKey) {
    switch (iconKey) {
      case 'pay_bills':   return Icons.receipt_long_outlined;
      case 'new_plan':    return Icons.wifi_outlined;
      case 'kyc':         return Icons.badge_outlined;
      case 'outstanding': return Icons.access_time_outlined;
      case 'my_bills':    return Icons.description_outlined;
      default:            return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Manage Services',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: services.take(4).map((s) => _ServiceItem(
            icon: _getIcon(s['icon']!), label: s['label']!,
            screenContext: context, onNavigateToPay: onNavigateToPay, onKycTap: onKycTap,
          )).toList(),
        ),
        if (services.length > 4) ...[
          const SizedBox(height: 20),
          Row(
            children: services.skip(4).map((s) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _ServiceItem(
                icon: _getIcon(s['icon']!), label: s['label']!,
                screenContext: context, onNavigateToPay: onNavigateToPay, onKycTap: onKycTap,
              ),
            )).toList(),
          ),
        ],
      ]),
    );
  }
}

class _ServiceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final BuildContext screenContext;
  final VoidCallback? onNavigateToPay;
  final VoidCallback? onKycTap;

  const _ServiceItem({
    required this.icon, required this.label, required this.screenContext,
    this.onNavigateToPay, this.onKycTap,
  });

  void _onTap() {
    switch (label) {
      case 'Pay Bills':   onNavigateToPay?.call(); break;
      case 'KYC':         onKycTap?.call(); break;
      case 'Outstanding': Navigator.push(screenContext, MaterialPageRoute(builder: (_) => const PendingBillsScreen())); break;
      case 'My Bills':    Navigator.push(screenContext, MaterialPageRoute(builder: (_) => const MyBillsScreen())); break;
      case 'New Plan':    Navigator.push(screenContext, MaterialPageRoute(builder: (_) => const WifiPlansScreen())); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap, behavior: HitTestBehavior.opaque,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 58, height: 58,
          decoration: BoxDecoration(
            color: AppColors.background, shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderColor, width: 1.5),
          ),
          child: Icon(icon, color: AppColors.textDark, size: 24),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 64,
          child: Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.textDark,
                  fontWeight: FontWeight.w500, height: 1.3),
              maxLines: 2),
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
      Expanded(child: _SpeedoCard(
        title: 'SPEEDO', titleSuffix: 'prime', isTv: false,
        subtitle: 'Watch your favourite\nmovies on Speedo Prime',
      )),
      const SizedBox(width: 12),
      Expanded(child: _SpeedoCard(
        title: 'SPEEDO', titleSuffix: 'TV', isTv: true,
        subtitle: 'Watch all OTT content\nin one place',
      )),
    ]);
  }
}

class _SpeedoCard extends StatelessWidget {
  final String title, titleSuffix, subtitle;
  final bool isTv;
  const _SpeedoCard({
    required this.title, required this.titleSuffix,
    required this.isTv, required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        RichText(text: TextSpan(children: [
          TextSpan(text: title, style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1)),
          if (isTv)
            const WidgetSpan(child: Padding(
              padding: EdgeInsets.only(left: 2),
              child: Icon(Icons.tv, size: 16, color: Colors.black),
            ))
          else
            TextSpan(text: titleSuffix, style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ])),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
        const SizedBox(height: 12),
        const Row(children: [
          Text('Watch Now', style: TextStyle(
              color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
          SizedBox(width: 4),
          Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROMO BANNER
// ─────────────────────────────────────────────────────────────────────────────

class _PromoBanner extends StatelessWidget {
  final int currentIndex;
  final Function(int) onPageChanged;
  const _PromoBanner({required this.currentIndex, required this.onPageChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 160, width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF1A0A2E), Color(0xFF2D1060)]),
            ),
            child: Stack(alignment: Alignment.center, children: [
              Positioned(
                left: 16,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text('SPEEDO PRIME PRESENTS', style: TextStyle(
                        color: Colors.amber.shade300, fontSize: 10,
                        fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                    const SizedBox(height: 6),
                    const Text('MOVIE\nFESTIVAL', style: TextStyle(
                        color: Colors.white, fontSize: 28,
                        fontWeight: FontWeight.w900, height: 1.1)),
                    const SizedBox(height: 8),
                    const Text('MARCH 30, THURSDAY', style: TextStyle(
                        color: Colors.amber, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Positioned(
                right: 10,
                child: Icon(Icons.local_movies, size: 80, color: Colors.amber.withOpacity(0.6)),
              ),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == currentIndex - 1 ? 20 : 8, height: 8,
              decoration: BoxDecoration(
                color: i == currentIndex - 1 ? AppColors.primary : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            )),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FEATURES SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _FeaturesSection extends StatelessWidget {
  final int currentIndex;
  final Function(int) onPageChanged;
  const _FeaturesSection({required this.currentIndex, required this.onPageChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Features', style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          Row(children: List.generate(2, (i) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: i == 0 ? 20 : 8, height: 8,
            decoration: BoxDecoration(
              color: i == 0 ? AppColors.primary : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ))),
        ]),
        const SizedBox(height: 24),
        Center(child: Column(children: [
          Container(
            width: 130, height: 130,
            decoration: BoxDecoration(
              color: const Color(0xFFF5DEB3), borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(alignment: Alignment.center, children: [
              const Text('REFER\nFRIEND', textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black87)),
              Positioned(right: 8, top: 8, child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.more_horiz, color: Colors.white, size: 16),
              )),
            ]),
          ),
          const SizedBox(height: 16),
          const Text('More Refer More Rewards',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 6),
          const Text('Refer your friend and win exiting prizes!',
              style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Refer Now',
                style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          )),
        ])),
      ]),
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
      child: Text('With love,\nfrom Speedonet',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
              color: Color(0xFFCCCCDD), height: 1.2)),
    );
  }
}