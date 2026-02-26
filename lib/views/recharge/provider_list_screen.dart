import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'service_detail_screen.dart';
import 'wifi_plans_screen.dart';

class ProviderListScreen extends StatefulWidget {
  final String serviceType;
  final List<String> providers;

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

  List<String> get _filtered => widget.providers
      .where((p) => p.toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

  void _onProviderTap(String providerName) {
    // Only show Speedonet's plan screen if the provider IS Speedonet
    if (_broadbandServiceTypes.contains(widget.serviceType) &&
        providerName.toLowerCase().contains(_speedonetProviderName.toLowerCase())) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => WifiPlansScreen(providerName: providerName),
      ));
    } else {
      // All other providers — including other broadband ISPs — go to the
      // generic detail screen where the user enters amount + consumer ID.
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ServiceDetailScreen(
          serviceType: widget.serviceType,
          providerName: providerName,
        ),
      ));
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
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
                ),
                Row(
                  children: [
                    Container(
                      width: 22, height: 22,
                      decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    const Text('Bharat\nConnect',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF1565C0))),
                  ],
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
                  hintStyle: TextStyle(color: AppColors.textLight, fontSize: 14),
                  suffixIcon: Icon(Icons.search, color: AppColors.textLight),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1, color: AppColors.borderColor, indent: 72,
                ),
                itemBuilder: (context, i) {
                  final providerName = _filtered[i];
                  // Show a subtle "Speedonet" badge so users know which is native
                  final isSpeedonet = providerName.toLowerCase()
                      .contains(_speedonetProviderName.toLowerCase());

                  return ListTile(
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: isSpeedonet ? AppColors.primary : Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          providerName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      providerName,
                      style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                    ),
                    subtitle: isSpeedonet
                        ? const Text(
                      'View Speedonet plans',
                      style: TextStyle(fontSize: 11, color: AppColors.primary),
                    )
                        : null,
                    onTap: () => _onProviderTap(providerName),
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