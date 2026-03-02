// lib/views/recharge/provider_list_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/provider_avatar.dart';
import 'service_detail_screen.dart';
import 'wifi_plans_screen.dart';

class ProviderListScreen extends StatefulWidget {
  final String serviceType;
  final List<Map<String, dynamic>> providers; // each: {name, icon_data, icon_mime}

  const ProviderListScreen({
    super.key,
    required this.serviceType,
    required this.providers,
  });

  @override
  State<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends State<ProviderListScreen> {
  String _searchQuery = '';

  // Only these service types CAN potentially show WiFi plans
  static const _broadbandServiceTypes = {
    'Broadband Postpaid',
    'New Plan',
    'WiFi Plans',
  };

  // Only this provider name shows Speedonet's real plans
  static const _speedonetProviderName = 'Speedonet';

  List<Map<String, dynamic>> get _filtered => widget.providers
      .where((p) =>
      (p['name'] as String)
          .toLowerCase()
          .contains(_searchQuery.toLowerCase()))
      .toList();

  void _onProviderTap(Map<String, dynamic> provider) {
    final providerName = provider['name'] as String;

    // Only show Speedonet's plan screen if provider IS Speedonet
    if (_broadbandServiceTypes.contains(widget.serviceType) &&
        providerName.toLowerCase().contains(
            _speedonetProviderName.toLowerCase())) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WifiPlansScreen(providerName: providerName),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ServiceDetailScreen(
            serviceType: widget.serviceType,
            providerName: providerName,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(widget.serviceType),
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
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    fontSize: 13,
                    letterSpacing: 0.5,
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

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: const InputDecoration(
                  hintText: 'Search your provider name',
                  hintStyle: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 14,
                  ),
                  suffixIcon: Icon(Icons.search, color: AppColors.textLight),
                  border: InputBorder.none,
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Provider list
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _filtered.isEmpty
                  ? Center(
                child: Text(
                  _searchQuery.isEmpty
                      ? 'No providers available'
                      : 'No results for "$_searchQuery"',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 14,
                  ),
                ),
              )
                  : ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: AppColors.borderColor,
                  indent: 72,
                ),
                itemBuilder: (context, i) {
                  final provider     = _filtered[i];
                  final providerName = provider['name'] as String;
                  final isSpeedonet  = providerName
                      .toLowerCase()
                      .contains(_speedonetProviderName.toLowerCase());

                  return ListTile(
                    leading: ProviderAvatar(
                      provider: provider,
                      size: 40,
                      isHighlighted: isSpeedonet,
                    ),
                    title: Text(
                      providerName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                    subtitle: isSpeedonet
                        ? const Text(
                      'View Speedonet plans',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                      ),
                    )
                        : null,
                    onTap: () => _onProviderTap(provider),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}