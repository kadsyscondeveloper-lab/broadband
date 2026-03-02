// lib/views/recharge/mobile_recharge_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/provider_avatar.dart';
import '../checkout/checkout_screen.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class MobileRechargeScreen extends StatefulWidget {
  final List<Map<String, dynamic>> providers; // each: {name, icon_data, icon_mime}

  const MobileRechargeScreen({
    super.key,
    this.providers = const <Map<String, dynamic>>[],
  });

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

  // Circles are static — these don't change
  final List<String> circles = [
    'ANDHRA PRADESH', 'ASSAM', 'BIHAR JHARKHAND', 'CHENNAI', 'DELHI NCR',
    'GUJARAT', 'HARYANA', 'HIMACHAL PRADESH', 'JAMMU KASHMIR', 'KARNATAKA',
    'KERALA', 'MADHYA PRADESH', 'MAHARASHTRA', 'MUMBAI', 'NORTH EAST',
    'ORISSA', 'PUNJAB', 'RAJASTHAN', 'TAMILNADU', 'UP EAST', 'UP WEST',
    'WEST BENGAL',
  ];

  final List<String> planFilters = ['Top up Plans', '4g Plans', 'Other Plans'];

  // Hardcoded plans — replace with live recharge API when available
  final List<Map<String, String>> plans = [
    {'amount': '10',  'data': 'N.A',   'validity': 'N.A',     'desc': 'Talktime INR7.47 – Validity NA'},
    {'amount': '500', 'data': 'N.A',   'validity': 'N.A',     'desc': 'Talktime INR423.73 – Validity NA'},
    {'amount': '429', 'data': '2.5GB', 'validity': '1 Month', 'desc': 'Data 2.5GB/day + Unlimited 5G – Calls Unlimited local STD and Roam'},
    {'amount': '120', 'data': '2.5GB', 'validity': 'N.A',     'desc': 'Talktime INR98.90 – Validity NA'},
    {'amount': '179', 'data': '1.5GB', 'validity': '28 Days', 'desc': 'Unlimited calls + 100 SMS/day'},
    {'amount': '239', 'data': '1.5GB', 'validity': '28 Days', 'desc': 'Unlimited calls + Disney+ Hotstar'},
    {'amount': '719', 'data': '2GB',   'validity': '84 Days', 'desc': 'Unlimited calls, 100 SMS/day + Data'},
  ];

  Future<void> _openContactPicker() async {
    final status = await Permission.contacts.request();

    if (!status.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contacts permission denied')),
      );
      return;
    }

    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
    );

    // Filter only contacts that have a phone number
    final withPhones = contacts
        .where((c) => c.phones.isNotEmpty)
        .toList();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ContactPickerSheet(
        contacts: withPhones,
        onSelect: (number) {
          // Strip spaces, dashes, country code etc.
          final cleaned = number.replaceAll(RegExp(r'[\s\-\(\)]'), '');
          final local = cleaned.startsWith('+91')
              ? cleaned.substring(3)
              : cleaned.startsWith('91') && cleaned.length == 12
              ? cleaned.substring(2)
              : cleaned;
          setState(() => _phoneController.text = local);
        },
      ),
    );
  }

  // ── Derived provider lists from backend ────────────────────────────────────
  // Providers whose name contains "postpaid" → postpaid tab, rest → prepaid tab.
  // Falls back to hardcoded list if backend returns nothing.

  List<Map<String, dynamic>> get _prepaidProviders {
    if (widget.providers.isEmpty) {
      return [
        {'name': 'Airtel',    'icon_data': null, 'icon_mime': null},
        {'name': 'BSNL',      'icon_data': null, 'icon_mime': null},
        {'name': 'Idea',      'icon_data': null, 'icon_mime': null},
        {'name': 'Jio',       'icon_data': null, 'icon_mime': null},
        {'name': 'MTNL',      'icon_data': null, 'icon_mime': null},
        {'name': 'MTS',       'icon_data': null, 'icon_mime': null},
        {'name': 'T24',       'icon_data': null, 'icon_mime': null},
        {'name': 'TATA Docomo','icon_data': null, 'icon_mime': null},
        {'name': 'Vodafone',  'icon_data': null, 'icon_mime': null},
      ];
    }
    return widget.providers
        .where((p) =>
    !(p['name'] as String).toLowerCase().contains('postpaid'))
        .toList();
  }

  List<Map<String, dynamic>> get _postpaidProviders {
    if (widget.providers.isEmpty) {
      return [
        {'name': 'Airtel Postpaid', 'icon_data': null, 'icon_mime': null},
        {'name': 'BSNL Postpaid',   'icon_data': null, 'icon_mime': null},
        {'name': 'Idea Postpaid',   'icon_data': null, 'icon_mime': null},
        {'name': 'Jio Postpaid',    'icon_data': null, 'icon_mime': null},
        {'name': 'MTNL Dolphin',    'icon_data': null, 'icon_mime': null},
      ];
    }
    return widget.providers
        .where((p) =>
        (p['name'] as String).toLowerCase().contains('postpaid'))
        .toList();
  }

  // Operator names only (for the dropdown picker)
  List<String> get _prepaidOperatorNames =>
      _prepaidProviders.map((p) => p['name'] as String).toList();

  List<String> get _postpaidOperatorNames =>
      _postpaidProviders.map((p) => p['name'] as String).toList();

  // ──────────────────────────────────────────────────────────────────────────

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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ProviderPickerSheet(
        title: 'Select your operator',
        providers: _prepaidProviders,
        onSelect: (name) => setState(() => _selectedOperator = name),
      ),
    );
  }

  void _showCirclePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SimplePickerSheet(
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
                      hintStyle: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 14,
                      ),
                      suffixIcon: Icon(
                        Icons.phone_outlined,
                        color: AppColors.textLight,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _openContactPicker,
                child: Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: const Icon(Icons.person_outline, color: AppColors.textGrey, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Operator + Circle row
          Row(
            children: [
              Expanded(
                child: _DropdownButton(
                  label: _selectedOperator ?? 'Select Operator',
                  onTap: _showOperatorPicker,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DropdownButton(
                  label: _selectedCircle ?? 'Select Circle',
                  onTap: _showCirclePicker,
                ),
              ),
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
                  hintStyle: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 14,
                  ),
                  suffixIcon:
                  Icon(Icons.search, color: AppColors.textLight),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.textDark
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: active
                              ? AppColors.textDark
                              : AppColors.borderColor,
                        ),
                      ),
                      child: Text(
                        planFilters[i],
                        style: TextStyle(
                          color:
                          active ? Colors.white : AppColors.textGrey,
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
            ...plans.map(
                  (p) => _PlanCard(
                plan: p,
                onSelect: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckoutScreen(
                      serviceType: 'Mobile Recharge',
                      providerName: _selectedOperator ?? '',
                      amount: double.parse(p['amount']!),
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 32),
            _EmptyState(
              message: 'No Recent Recharge',
              subtitle:
              "You'll see your transactions here\nafter they are processed",
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPostpaid() {
    final providers = _postpaidProviders;

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
                hintStyle: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 14,
                ),
                suffixIcon:
                Icon(Icons.search, color: AppColors.textLight),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: providers.isEmpty
                ? const Center(
              child: Text(
                'No postpaid providers available',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 14,
                ),
              ),
            )
                : ListView.separated(
              itemCount: providers.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: AppColors.borderColor,
                indent: 68,
              ),
              itemBuilder: (ctx, i) {
                final provider = providers[i];
                final name = provider['name'] as String;
                return ListTile(
                  leading: ProviderAvatar(
                    provider: provider,
                    size: 40,
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontSize: 14),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CheckoutScreen(
                        serviceType: 'Mobile Recharge Postpaid',
                        providerName: name,
                        amount: 0,
                      ),
                    ),
                  ),
                );
              },
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
                const Text(
                  'BHARAT BILL PAYMENT',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.4,
                    color: AppColors.textDark,
                  ),
                ),
                Image.asset('assets/images/bharat_connect.png', height: 28, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Row(children: [
                    Container(width: 18, height: 18, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text('Bharat\nConnect', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Color(0xFF1565C0))),
                  ]),
                ),
              ],
            ),
          ),

          // Segmented toggle
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
                          color: _tabController.index == 0
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(27),
                        ),
                        child: Center(
                          child: Text(
                            'Prepaid',
                            style: TextStyle(
                              color: _tabController.index == 0
                                  ? Colors.white
                                  : AppColors.textGrey,
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
                          color: _tabController.index == 1
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(27),
                        ),
                        child: Center(
                          child: Text(
                            'Postpaid',
                            style: TextStyle(
                              color: _tabController.index == 1
                                  ? Colors.white
                                  : AppColors.textGrey,
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

// ─────────────────────────────────────────────────────────────────────────────
// Provider picker bottom sheet (shows avatar + name)
// ─────────────────────────────────────────────────────────────────────────────

class _ProviderPickerSheet extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> providers;
  final Function(String) onSelect;

  const _ProviderPickerSheet({
    required this.title,
    required this.providers,
    required this.onSelect,
  });

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
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              itemCount: providers.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final provider = providers[i];
                final name     = provider['name'] as String;
                return ListTile(
                  leading: ProviderAvatar(provider: provider, size: 36),
                  title: Text(name, style: const TextStyle(fontSize: 15)),
                  onTap: () {
                    Navigator.pop(context);
                    onSelect(name);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Simple string picker bottom sheet (for circles)
// ─────────────────────────────────────────────────────────────────────────────

class _SimplePickerSheet extends StatelessWidget {
  final String title;
  final List<String> items;
  final Function(String) onSelect;

  const _SimplePickerSheet({
    required this.title,
    required this.items,
    required this.onSelect,
  });

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
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Dropdown trigger button
// ─────────────────────────────────────────────────────────────────────────────

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
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textGrey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Plan card
// ─────────────────────────────────────────────────────────────────────────────

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
                Text(
                  '₹${plan['amount']}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan['data']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const Text(
                              'Data',
                              style: TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan['validity']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const Text(
                              'Validity',
                              style: TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.primary,
                  size: 15,
                ),
              ],
            ),
            if ((plan['desc'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text(
                plan['desc']!,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;
  final String subtitle;

  const _EmptyState({required this.message, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.description_outlined,
                  size: 50,
                  color: Colors.grey.shade300,
                ),
              ),
              Positioned(
                child:
                Icon(Icons.search, size: 30, color: Colors.grey.shade400),
              ),
              Positioned(
                right: 18,
                bottom: 18,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textGrey,
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ContactPickerSheet extends StatefulWidget {
  final List<Contact> contacts;
  final Function(String) onSelect;

  const _ContactPickerSheet({
    required this.contacts,
    required this.onSelect,
  });

  @override
  State<_ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<_ContactPickerSheet> {
  String _search = '';

  List<Contact> get _filtered => widget.contacts
      .where((c) =>
  c.displayName.toLowerCase().contains(_search.toLowerCase()) ||
      c.phones.any((p) => p.number.contains(_search)))
      .toList();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select Contact',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _search = v),
                decoration: const InputDecoration(
                  hintText: 'Search name or number',
                  hintStyle: TextStyle(fontSize: 14, color: AppColors.textLight),
                  prefixIcon: Icon(Icons.search, color: AppColors.textLight, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
              child: Text(
                'No contacts found',
                style: TextStyle(color: AppColors.textLight),
              ),
            )
                : ListView.separated(
              controller: scrollController,
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final contact = _filtered[i];
                final number  = contact.phones.first.number;
                return ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        contact.displayName.isNotEmpty
                            ? contact.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    contact.displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    number,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onSelect(number);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
