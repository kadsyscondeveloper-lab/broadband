import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

class ReferEarnScreen extends StatelessWidget {
  const ReferEarnScreen({super.key});

  final String referralLink = 'https://www.io.pixelsoftwares.com/speedonet/refer?code=PT1234';

  @override
  Widget build(BuildContext context) {
    final howItWorks = [
      {'icon': Icons.share_outlined, 'text': 'Invite your friends to experience any Speedonet Service.'},
      {'icon': Icons.shopping_cart_outlined, 'text': 'Friend buys a new service using your referral link.'},
      {'icon': Icons.local_offer_outlined, 'text': 'You both get discount coupons on Speedonet.'},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Refer and Earn'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero banner
            Container(
              width: double.infinity,
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53), Color(0xFFFFC94A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 20, top: 20, bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Refer & Earn', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 22)),
                        const Text('with Every Connection!', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 8),
                        const SizedBox(
                          width: 200,
                          child: Text(
                            'Invite friends to join our broadband\nand get exciting rewards for every\nsuccessful referral.',
                            style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 0, top: 0, bottom: 0,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16)),
                      child: Container(
                        width: 140,
                        color: Colors.white.withOpacity(0.1),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 80, color: Colors.white54),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Referral link box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      referralLink,
                      style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: referralLink));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied!'), duration: Duration(seconds: 1)),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.copy_outlined, size: 20, color: AppColors.textGrey),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Share button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Share Link', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),

            // How it works
            const Text('How it works?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: howItWorks.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.borderColor, indent: 72),
                itemBuilder: (_, i) {
                  final item = howItWorks[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
                      child: Icon(item['icon'] as IconData, color: AppColors.textDark, size: 22),
                    ),
                    title: Text(item['text'] as String, style: const TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.4)),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // FAQ & Terms
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 44, height: 44,
                      decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
                      child: const Icon(Icons.help_outline, color: AppColors.textDark, size: 22),
                    ),
                    title: const Text('Frequently Asked Questions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textLight),
                    onTap: () {},
                  ),
                  Divider(height: 1, color: AppColors.borderColor, indent: 72),
                  ListTile(
                    leading: Container(
                      width: 44, height: 44,
                      decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
                      child: const Icon(Icons.article_outlined, color: AppColors.textDark, size: 22),
                    ),
                    title: const Text('Terms and Conditions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textLight),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
