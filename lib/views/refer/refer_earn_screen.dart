import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../theme/app_theme.dart';

class ReferEarnScreen extends StatelessWidget {
  const ReferEarnScreen({super.key});

  final String referralLink = 'https://www.io.pixelsoftwares.com/speedonet/refer?code=PT1234';

  @override
  Widget build(BuildContext context) {
    final howItWorks = [
      {'icon': PhosphorIcons.shareNetwork(), 'text': 'Invite your friends to experience any Speedonet Service.'},
      {'icon': PhosphorIcons.shoppingCart(), 'text': 'Friend buys a new service using your referral link.'},
      {'icon': PhosphorIcons.tag(), 'text': 'You both get discount coupons on Speedonet.'},
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
            // Hero banner
            // Hero banner
            // Hero banner
            Container(
              width: double.infinity,
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Colors.white, Colors.white, Color(0xFFFF6B6B), Color(0xFFFFA726)],
                  stops: [0.0, 0.4, 0.7, 1.0],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // ── People image takes the full right 60% ─────────────
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.62,
                        height: 190,
                        child: Image.asset(
                          'assets/images/refer_banner.png',
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                    ),

                    //white fade
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.white.withValues(alpha: 0.95),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.28, 0.48],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ),

                    // ── Text on the left ───────────────────────────────────
                    Positioned(
                      left: 20, top: 0, bottom: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFFFF3B3B), Color(0xFFFF8E53), Color(0xFFFFA726)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ).createShader(bounds),
                            child: const Text(
                              'Refer & Earn',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                              ),
                            ),
                          ),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFFFF3B3B), Color(0xFFFF8E53), Color(0xFFFFA726)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ).createShader(bounds),
                            child: const Text(
                              'with Every Connection!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const SizedBox(
                            width: 165,
                            child: Text(
                              'Invite friends to join our broadband and get exciting rewards for every successful referral.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderColor, width: 1.5),
                      ),
                      child: Center(
                        child: PhosphorIcon(item['icon'] as PhosphorIconData, color: AppColors.textDark, size: 22),
                      ),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // ← was 8
                    leading: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderColor, width: 1.5),
                      ),
                      child: Center(
                        child: PhosphorIcon(PhosphorIcons.question(), color: AppColors.textDark, size: 22),
                      ),
                    ),
                    title: const Text('Frequently Asked Questions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textLight),
                    onTap: () {},
                  ),
                  Divider(height: 1, color: AppColors.borderColor, indent: 72),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // ← was 8
                    leading: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderColor, width: 1.5),
                      ),
                      child: Center(
                        child: PhosphorIcon(PhosphorIcons.article(), color: AppColors.textDark, size: 22),
                      ),
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
