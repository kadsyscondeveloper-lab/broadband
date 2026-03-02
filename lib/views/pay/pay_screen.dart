// lib/views/pay/pay_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/pay_viewmodel.dart';
import '../recharge/mobile_recharge_screen.dart';
import '../recharge/provider_list_screen.dart';
import '../recharge/service_detail_screen.dart';

class PayScreen extends StatelessWidget {
  final PayViewModel viewModel;

  const PayScreen({super.key, required this.viewModel});

  void _navigate(
      BuildContext context,
      String serviceLabel,
      List<Map<String, dynamic>> providers,
      ) {
    if (serviceLabel == 'Mobile\nRecharge' || serviceLabel == 'Mobile Recharge') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MobileRechargeScreen(providers: providers),
        ),
      );
      return;
    }

    final cleanType = serviceLabel.replaceAll('\n', ' ');

    if (providers.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProviderListScreen(
            serviceType: cleanType,
            providers: providers,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ServiceDetailScreen(
            serviceType: cleanType,
            providerName: cleanType,
          ),
        ),
      );
    }
  }

  IconData _getIcon(String iconKey) {
    switch (iconKey) {
      case 'mobile':
      case 'mobile_recharge':        return Icons.phone_android_outlined;
      case 'broadband':              return Icons.wifi_outlined;
      case 'datacard':               return Icons.usb_outlined;
      case 'dth':                    return Icons.satellite_alt_outlined;
      case 'fastag':                 return Icons.toll_outlined;
      case 'cable_tv':               return Icons.tv_outlined;
      case 'education':              return Icons.school_outlined;
      case 'electricity':            return Icons.bolt_outlined;
      case 'gas':
      case 'lpg_gas':                return Icons.local_gas_station_outlined;
      case 'landline':               return Icons.phone_outlined;
      case 'credit_card':            return Icons.credit_card_outlined;
      case 'water':                  return Icons.water_drop_outlined;
      case 'municipal_services':
      case 'municipal_taxes':        return Icons.account_balance_outlined;
      case 'loan':                   return Icons.handshake_outlined;
      case 'insurance':
      case 'health_insurance':
      case 'life_insurance':         return Icons.health_and_safety_outlined;
      case 'hospital':
      case 'hospital_pathology':     return Icons.local_hospital_outlined;
      case 'housing_society':        return Icons.apartment_outlined;
      case 'subscription':           return Icons.subscriptions_outlined;
      case 'nps':                    return Icons.savings_outlined;
      case 'rental':                 return Icons.home_work_outlined;
      case 'ncmc':                   return Icons.train_outlined;
      case 'meter':                  return Icons.speed_outlined;
      case 'donate':                 return Icons.volunteer_activism_outlined;
      default:                       return Icons.grid_view_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomNavHeight = 64 + 16 + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          return RefreshIndicator(
            onRefresh: viewModel.refresh,
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Header ─────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 16,
                      left: 20, right: 20, bottom: 32,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.only(
                        bottomLeft:  Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'BHARAT BILL PAYMENT',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Image.asset(
                                'assets/images/bharat_connect.png',
                                height: 32,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: const BoxDecoration(
                                        color: Colors.orange,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Bharat\nConnect',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1565C0),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Current Balance',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '₹${viewModel.currentBalance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Skeleton while loading ──────────────────────────────────
                if (viewModel.isLoading)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 20, 16, bottomNavHeight + 8),
                      child: const _ServicesSkeleton(),
                    ),
                  ),

                // ── Recharge section ────────────────────────────────────────
                if (!viewModel.isLoading && viewModel.rechargeServices.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: _ServiceSection(
                        title:    'Recharge',
                        services: viewModel.rechargeServices,
                        getIcon:  _getIcon,
                        onTap:    (label, providers) =>
                            _navigate(context, label, providers),
                      ),
                    ),
                  ),

                // ── Bill Payment section ────────────────────────────────────
                if (!viewModel.isLoading && viewModel.billPaymentServices.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomNavHeight + 8),
                      child: _ServiceSection(
                        title:    'Bill Payment',
                        services: viewModel.billPaymentServices,
                        getIcon:  _getIcon,
                        onTap:    (label, providers) =>
                            _navigate(context, label, providers),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SKELETON LOADER
// ─────────────────────────────────────────────────────────────────────────────

class _ServicesSkeleton extends StatefulWidget {
  const _ServicesSkeleton();
  @override
  State<_ServicesSkeleton> createState() => _ServicesSkeletonState();
}

class _ServicesSkeletonState extends State<_ServicesSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(_ctrl);
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
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Column(
          children: [
            _box(200),
            const SizedBox(height: 16),
            _box(380),
          ],
        ),
      ),
    );
  }

  Widget _box(double h) => Container(
    height: h,
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(16),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> services;
  final IconData Function(String) getIcon;
  final void Function(String label, List<Map<String, dynamic>> providers) onTap;

  const _ServiceSection({
    required this.title,
    required this.services,
    required this.getIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final itemWidth = (MediaQuery.of(context).size.width - 32 - 40) / 4;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing:    0,
            runSpacing: 16,
            children: services.map((s) {
              final label = s['label'] as String;
              final icon  = s['icon']  as String;

              // Providers are now List<Map<String, dynamic>>
              final providers = (s['providers'] as List<dynamic>? ?? [])
                  .map((p) {
                if (p is Map<String, dynamic>) return p;
                // Fallback: plain string from old API or cache
                return <String, dynamic>{
                  'name':      p.toString(),
                  'icon_data': null,
                  'icon_mime': null,
                };
              })
                  .toList();

              return SizedBox(
                width: itemWidth,
                child: GestureDetector(
                  onTap:    () => onTap(label, providers),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width:  50,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEEEEF5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          getIcon(icon),
                          color: const Color(0xFF3D4066),
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize:   10,
                          color:      AppColors.textDark,
                          fontWeight: FontWeight.w500,
                          height:     1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}