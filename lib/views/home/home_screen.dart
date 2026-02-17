import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_drawer.dart';
import '../kyc/kyc_upload_screen.dart';
import '../refer/refer_earn_screen.dart';
import '../bills/bills_screens.dart';
import '../recharge/provider_list_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: AppDrawer(
        user: vm.user,
        onClose: () => _scaffoldKey.currentState?.closeDrawer(),
        onMenuItemTap: (item) {
          _scaffoldKey.currentState?.closeDrawer();
          switch (item) {
            case 'Profile':
              widget.onNavigateToProfile?.call();
              break;
            case 'KYC':
              Navigator.push(context, MaterialPageRoute(builder: (_) => const KycUploadScreen()));
              break;
            case 'Refer & Earn':
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferEarnScreen()));
              break;
            case 'New Plans':
              widget.onNavigateToNewPlans?.call();
              break;
          }
        },
      ),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: AppHeader(
                  userName: vm.user.name,
                  walletBalance: vm.user.walletBalance,
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
                      // Manage Services Card
                      _ManageServicesCard(
                        services: vm.services,
                        onNavigateToPay: widget.onNavigateToPay,
                      ),
                      const SizedBox(height: 16),
                      // Speedo Cards
                      _SpeedoCards(),
                      const SizedBox(height: 16),
                      // KYC Banner
                      if (vm.isKycUnderReview) _KycReviewBanner(),
                      const SizedBox(height: 16),
                      // Promo Banner
                      _PromoBanner(
                        currentIndex: vm.promoBannerIndex,
                        onPageChanged: vm.onPromoBannerPageChanged,
                      ),
                      const SizedBox(height: 16),
                      // Features Section
                      _FeaturesSection(
                        currentIndex: vm.featureBannerIndex,
                        onPageChanged: vm.onFeatureBannerPageChanged,
                      ),
                      const SizedBox(height: 24),
                      // Footer text
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

class _ManageServicesCard extends StatelessWidget {
  final List<Map<String, String>> services;
  final VoidCallback? onNavigateToPay;

  const _ManageServicesCard({
    required this.services,
    this.onNavigateToPay,
  });

  IconData _getIcon(String iconKey) {
    switch (iconKey) {
      case 'pay_bills':
        return Icons.receipt_long_outlined;
      case 'new_plan':
        return Icons.wifi_outlined;
      case 'kyc':
        return Icons.badge_outlined;
      case 'outstanding':
        return Icons.access_time_outlined;
      case 'my_bills':
        return Icons.description_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manage Services',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 20),
          // Use Row + Expanded for even distribution across full width
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: services.take(4).map((s) => _ServiceItem(
              icon: _getIcon(s['icon']!),
              label: s['label']!,
              screenContext: context,
              onNavigateToPay: onNavigateToPay,
            )).toList(),
          ),
          if (services.length > 4) ...[
            const SizedBox(height: 20),
            Row(
              children: services.skip(4).map((s) => Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _ServiceItem(
                  icon: _getIcon(s['icon']!),
                  label: s['label']!,
                  screenContext: context,
                  onNavigateToPay: onNavigateToPay,
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ServiceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final BuildContext screenContext;
  final VoidCallback? onNavigateToPay;

  const _ServiceItem({
    required this.icon,
    required this.label,
    required this.screenContext,
    this.onNavigateToPay,
  });

  void _onTap() {
    switch (label) {
    // ✅ "Pay Bills" switches the bottom tab to the Pay screen (index 2)
    // This is the correct approach — it keeps the bottom nav in sync
    // instead of pushing a new route on top of HomeScreen.
      case 'Pay Bills':
        onNavigateToPay?.call();
        break;

      case 'KYC':
        Navigator.push(screenContext, MaterialPageRoute(builder: (_) => const KycUploadScreen()));
        break;
      case 'Outstanding':
        Navigator.push(screenContext, MaterialPageRoute(builder: (_) => const PendingBillsScreen()));
        break;
      case 'My Bills':
        Navigator.push(screenContext, MaterialPageRoute(builder: (_) => const MyBillsScreen()));
        break;

    // New Plan — shows broadband providers → wifi plan cards
      case 'New Plan':
        Navigator.push(screenContext, MaterialPageRoute(
          builder: (_) => ProviderListScreen(
            serviceType: 'Broadband Postpaid',
            providers: [
              'ACT Fibernet', 'AirJaldi - Rural Broadband', 'Airtel Broadband',
              'Alliance Broadband Services Pvt. Ltd.', 'Comway Broadband',
              'Connect Broadband', 'DEN Broadband', 'Hathway Broadband',
              'MTNL Broadband', 'YOU Broadband', 'Speedonet Broadband',
            ],
          ),
        ));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderColor, width: 1.5),
            ),
            child: Icon(icon, color: AppColors.textDark, size: 24),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 64,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textDark,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedoCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SpeedoCard(
            title: 'SPEEDO',
            titleSuffix: 'prime',
            isTv: false,
            subtitle: 'Watch your favourite\nmovies on Speedo Prime',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SpeedoCard(
            title: 'SPEEDO',
            titleSuffix: 'TV',
            isTv: true,
            subtitle: 'Watch all OTT content\nin one place',
          ),
        ),
      ],
    );
  }
}

class _SpeedoCard extends StatelessWidget {
  final String title;
  final String titleSuffix;
  final bool isTv;
  final String subtitle;

  const _SpeedoCard({
    required this.title,
    required this.titleSuffix,
    required this.isTv,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isTv ? Colors.black : Colors.black,
                    letterSpacing: 1,
                  ),
                ),
                if (isTv)
                  const WidgetSpan(
                    child: Padding(
                      padding: EdgeInsets.only(left: 2),
                      child: Icon(Icons.tv, size: 16, color: Colors.black),
                    ),
                  )
                else
                  TextSpan(
                    text: titleSuffix,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Text(
                'Watch Now',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }
}

class _KycReviewBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.reviewBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.reviewBorder.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.info, color: Color(0xFF8B6914), size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'In Review',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Your KYC documents have been submitted and are currently under review. We'll notify you once the verification is complete.",
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFFD4A017)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Check Status',
                style: TextStyle(
                  color: Color(0xFFD4A017),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  final int currentIndex;
  final Function(int) onPageChanged;

  const _PromoBanner({required this.currentIndex, required this.onPageChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A0A2E), Color(0xFF2D1060)],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 16,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          'SPEEDO PRIME PRESENTS',
                          style: TextStyle(
                            color: Colors.amber.shade300,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'MOVIE\nFESTIVAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'MARCH 30, THURSDAY',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 10,
                    child: Icon(Icons.local_movies, size: 80, color: Colors.amber.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (i) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == currentIndex - 1 ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == currentIndex - 1 ? AppColors.primary : Colors.grey.shade300,
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

class _FeaturesSection extends StatelessWidget {
  final int currentIndex;
  final Function(int) onPageChanged;

  const _FeaturesSection({required this.currentIndex, required this.onPageChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Features',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Row(
                children: List.generate(2, (i) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: i == 0 ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == 0 ? AppColors.primary : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5DEB3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Text(
                        'REFER\nFRIEND',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.more_horiz, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'More Refer More Rewards',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Refer your friend and win exiting prizes!',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Refer Now',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
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

class _FooterText extends StatelessWidget {
  const _FooterText();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'With love,\nfrom Speedonet',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: Color(0xFFCCCCDD),
          height: 1.2,
        ),
      ),
    );
  }
}
