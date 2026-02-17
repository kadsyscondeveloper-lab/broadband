import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../checkout/checkout_screen.dart';

class MobileRechargeScreen extends StatefulWidget {
  const MobileRechargeScreen({super.key});

  @override
  State<MobileRechargeScreen> createState() => _MobileRechargeScreenState();
}

class _MobileRechargeScreenState extends State<MobileRechargeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _phoneController = TextEditingController();
  String? _selectedOperator;
  String? _selectedCircle;
  String _planFilter = 'Top up Plans';

  final List<String> operators = ['Airtel', 'BSNL', 'Idea', 'Jio', 'MTNL', 'MTS', 'T24', 'TATA Docomo', 'Vodafone'];
  final List<String> circles = ['ANDHRA PRADESH', 'ASSAM', 'BIHAR JHARKHAND', 'CHENNAI', 'DELHI NCR', 'GUJARAT', 'HARYANA', 'HIMACHAL PRADESH', 'JAMMU KASHMIR', 'KARNATAKA', 'KERALA', 'MADHYA PRADESH', 'MAHARASHTRA', 'MUMBAI', 'NORTH EAST', 'ORISSA', 'PUNJAB', 'RAJASTHAN', 'TAMILNADU', 'UP EAST', 'UP WEST', 'WEST BENGAL'];
  final List<String> planFilters = ['Top up Plans', '4g Plans', 'Other Plans'];

  final List<Map<String, String>> plans = [
    {'amount': '10', 'data': 'N.A', 'validity': 'N.A', 'desc': 'Talktime INR7.47 – Validity NA'},
    {'amount': '500', 'data': 'N.A', 'validity': 'N.A', 'desc': 'Talktime INR423.73 – Validity NA'},
    {'amount': '429', 'data': '2.5GB', 'validity': '1 Month', 'desc': 'Data 2.5GB/day + Unlimited 5G – Calls Unlimited local STD and Roam'},
    {'amount': '120', 'data': '2.5GB', 'validity': 'N.A', 'desc': 'Talktime INR98.90 – Validity NA'},
    {'amount': '179', 'data': '1.5GB', 'validity': '28 Days', 'desc': 'Unlimited calls + 100 SMS/day'},
    {'amount': '239', 'data': '1.5GB', 'validity': '28 Days', 'desc': 'Unlimited calls + Disney+ Hotstar'},
    {'amount': '719', 'data': '2GB', 'validity': '84 Days', 'desc': 'Unlimited calls, 100 SMS/day + Data'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showOperatorPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _BottomSheet(
        title: 'Select your operator',
        items: operators,
        onSelect: (v) => setState(() => _selectedOperator = v),
      ),
    );
  }

  void _showCirclePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _BottomSheet(
        title: 'Select your Circle',
        items: circles,
        onSelect: (v) => setState(() => _selectedCircle = v),
      ),
    );
  }

  Widget _buildPrepaid() {
    final showPlans = _selectedOperator != null && _selectedCircle != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        children: [
          // Phone input row
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 15),
                    decoration: const InputDecoration(
                      hintText: 'Mobile Number',
                      hintStyle: TextStyle(color: AppColors.textLight, fontSize: 14),
                      suffixIcon: Icon(Icons.phone_outlined, color: AppColors.textLight, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: const Icon(Icons.person_outline, color: AppColors.textGrey, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Operator + Circle row
          Row(
            children: [
              Expanded(child: _DropdownButton(
                label: _selectedOperator ?? 'Select Operator',
                onTap: _showOperatorPicker,
              )),
              const SizedBox(width: 10),
              Expanded(child: _DropdownButton(
                label: _selectedCircle ?? 'Select Circle',
                onTap: _showCirclePicker,
              )),
            ],
          ),

          if (showPlans) ...[
            const SizedBox(height: 12),
            // Search plan
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search for a plan',
                  hintStyle: TextStyle(color: AppColors.textLight, fontSize: 14),
                  suffixIcon: Icon(Icons.search, color: AppColors.textLight),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Plan filter chips
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: planFilters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final active = planFilters[i] == _planFilter;
                  return GestureDetector(
                    onTap: () => setState(() => _planFilter = planFilters[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? AppColors.textDark : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: active ? AppColors.textDark : AppColors.borderColor),
                      ),
                      child: Text(
                        planFilters[i],
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
            const SizedBox(height: 12),
            // Plans
            ...plans.map((p) => _PlanCard(
              plan: p,
              onSelect: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => CheckoutScreen(
                  serviceType: 'Mobile Recharge',
                  providerName: _selectedOperator ?? '',
                  amount: double.parse(p['amount']!),
                ),
              )),
            )).toList(),
          ] else ...[
            const SizedBox(height: 32),
            _EmptyState(
              message: 'No Recent Recharge',
              subtitle: "You'll see your transactions here\nafter they are processed",
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPostpaid() {
    final postpaidProviders = [
      'Airtel Postpaid', 'Airtel Postpaid', 'BSNL Mobile Postpaid',
      'Idea Postpaid', 'Jio Postpaid', 'Jio Postpaid', 'MTNL Dolphin', 'OTME', 'OTNS',
    ];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Search your provider name',
                hintStyle: TextStyle(color: AppColors.textLight, fontSize: 14),
                suffixIcon: Icon(Icons.search, color: AppColors.textLight),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: ListView.separated(
              itemCount: postpaidProviders.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.borderColor, indent: 68),
              itemBuilder: (ctx, i) => ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Center(child: Text('S', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
                ),
                title: Text(postpaidProviders[i], style: const TextStyle(fontSize: 14)),
                onTap: () {},
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Mobile Recharge'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Bharat Bill Payment banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('BHARAT BILL PAYMENT',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.4, color: AppColors.textDark)),
                Row(children: [
                  Container(width: 18, height: 18, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('Bharat\nConnect', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Color(0xFF1565C0))),
                ]),
              ],
            ),
          ),

          // ✅ Proper segmented toggle — clean pill design, no AppBar clipping issues
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              height: 46,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _tabController.animateTo(0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: _tabController.index == 0 ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(27),
                        ),
                        child: Center(
                          child: Text(
                            'Prepaid',
                            style: TextStyle(
                              color: _tabController.index == 0 ? Colors.white : AppColors.textGrey,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _tabController.animateTo(1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: _tabController.index == 1 ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(27),
                        ),
                        child: Center(
                          child: Text(
                            'Postpaid',
                            style: TextStyle(
                              color: _tabController.index == 1 ? Colors.white : AppColors.textGrey,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildPrepaid(), _buildPostpaid()],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable Dropdown trigger button ──────────────────────────────────────────
class _DropdownButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DropdownButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.textGrey, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Plan card ─────────────────────────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final Map<String, String> plan;
  final VoidCallback onSelect;

  const _PlanCard({required this.plan, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('₹${plan['amount']}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(width: 20),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(plan['data']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const Text('Data', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
                      ])),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(plan['validity']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const Text('Validity', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
                      ])),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: AppColors.primary, size: 15),
              ],
            ),
            if ((plan['desc'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text(
                plan['desc']!,
                style: const TextStyle(color: AppColors.primary, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Bottom sheet picker ────────────────────────────────────────────────────────
class _BottomSheet extends StatelessWidget {
  final String title;
  final List<String> items;
  final Function(String) onSelect;

  const _BottomSheet({required this.title, required this.items, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => ListTile(
                title: Text(items[i], style: const TextStyle(fontSize: 15)),
                onTap: () {
                  Navigator.pop(context);
                  onSelect(items[i]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String message;
  final String subtitle;

  const _EmptyState({required this.message, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(alignment: Alignment.center, children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
              child: Icon(Icons.description_outlined, size: 50, color: Colors.grey.shade300),
            ),
            Positioned(
              child: Icon(Icons.search, size: 30, color: Colors.grey.shade400),
            ),
            Positioned(
              right: 18, bottom: 18,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          Text(message,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(subtitle,
              style: const TextStyle(color: AppColors.textGrey, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
