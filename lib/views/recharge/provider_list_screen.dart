import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'service_detail_screen.dart';

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

  List<String> get _filtered => widget.providers
      .where((p) => p.toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

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
                decoration: InputDecoration(
                  hintText: 'Search your provider name',
                  hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
                  suffixIcon: const Icon(Icons.search, color: AppColors.textLight),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  return ListTile(
                    leading: Container(
                      width: 40, height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          'S',
                          style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      _filtered[i],
                      style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                    ),
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ServiceDetailScreen(
                        serviceType: widget.serviceType,
                        providerName: _filtered[i],
                      ),
                    )),
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
