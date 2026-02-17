import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../checkout/checkout_screen.dart';

class WifiPlansScreen extends StatefulWidget {
  final String providerName;

  const WifiPlansScreen({super.key,  this.providerName = "Speedonet Plans"});

  @override
  State<WifiPlansScreen> createState() => _WifiPlansScreenState();
}

class _WifiPlansScreenState extends State<WifiPlansScreen> {
  String _selectedFilter = 'All Plans';

  final List<String> _filters = ['All Plans', 'Monthly', 'Quarterly', 'Annual'];

  final List<Map<String, String>> _plans = [
    {'price': '300.00',  'speed': '400 Mbps',  'data': 'Unlimited',  'validity': '20 days'},
    {'price': '6.00',    'speed': '2 Mbps',    'data': '12 GB',      'validity': '30 days'},
    {'price': '6999.00', 'speed': '150 Mbps',  'data': 'Unlimited',  'validity': '365 days'},
    {'price': '2499.00', 'speed': '500 Mbps',  'data': '1000 GB',    'validity': '180 days'},
    {'price': '1299.00', 'speed': '200 Mbps',  'data': 'Unlimited',  'validity': '90 days'},
    {'price': '799.00',  'speed': '100 Mbps',  'data': '500 GB',     'validity': '30 days'},
    {'price': '499.00',  'speed': '50 Mbps',   'data': '200 GB',     'validity': '30 days'},
    {'price': '3999.00', 'speed': '300 Mbps',  'data': 'Unlimited',  'validity': '180 days'},
  ];

  List<Map<String, String>> get _filteredPlans {
    if (_selectedFilter == 'All Plans') return _plans;
    if (_selectedFilter == 'Monthly') {
      return _plans.where((p) => p['validity']!.contains('30') || p['validity']!.contains('20')).toList();
    }
    if (_selectedFilter == 'Quarterly') {
      return _plans.where((p) => p['validity']!.contains('90') || p['validity']!.contains('180')).toList();
    }
    if (_selectedFilter == 'Annual') {
      return _plans.where((p) => p['validity']!.contains('365')).toList();
    }
    return _plans;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(widget.providerName),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final active = _filters[i] == _selectedFilter;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = _filters[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: active ? AppColors.primary : AppColors.borderColor,
                        ),
                      ),
                      child: Text(
                        _filters[i],
                        style: TextStyle(
                          color: active ? Colors.white : AppColors.textGrey,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Plan count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text(
                  '${_filteredPlans.length} Plans Available',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Plans list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: _filteredPlans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final plan = _filteredPlans[index];
                return _WifiPlanCard(
                  plan: plan,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CheckoutScreen(
                        serviceType: 'WiFi Plan',
                        providerName: widget.providerName,
                        amount: double.parse(plan['price']!),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WifiPlanCard extends StatelessWidget {
  final Map<String, String> plan;
  final VoidCallback onTap;

  const _WifiPlanCard({required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top row — WiFi icon + price + arrow
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wifi,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    '₹${plan['price']}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.primary,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Divider(height: 1, color: Colors.grey.shade100),

            // Bottom row — Speed / Data / Validity
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  _PlanStat(
                    icon: Icons.speed_outlined,
                    label: 'Speed',
                    value: plan['speed']!,
                  ),
                  _VerticalDivider(),
                  _PlanStat(
                    icon: Icons.language_outlined,
                    label: 'Data',
                    value: plan['data']!,
                  ),
                  _VerticalDivider(),
                  _PlanStat(
                    icon: Icons.calendar_today_outlined,
                    label: 'Validity',
                    value: plan['validity']!,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PlanStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textGrey),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: Colors.grey.shade100,
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}
