// lib/views/refer/refer_earn_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/api_client.dart';
import '../../theme/app_theme.dart';

// ── Simple coupon model ───────────────────────────────────────────────────────
class _Coupon {
  final String  code;
  final String? description;
  final String  discountType;
  final double  discountValue;
  final double? maxDiscountAmount;
  final DateTime validTo;

  const _Coupon({
    required this.code,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.maxDiscountAmount,
    required this.validTo,
  });

  factory _Coupon.fromJson(Map<String, dynamic> j) => _Coupon(
    code:              j['code']               as String,
    description:       j['description']        as String?,
    discountType:      j['discount_type']      as String,
    discountValue:     (j['discount_value']    as num).toDouble(),
    maxDiscountAmount: j['max_discount_amount'] != null
        ? (j['max_discount_amount'] as num).toDouble()
        : null,
    validTo: DateTime.parse(j['valid_to'] as String),
  );

  String get discountLabel {
    if (discountType == 'percentage') {
      final cap = maxDiscountAmount != null
          ? ' (up to ₹${maxDiscountAmount!.toStringAsFixed(0)})'
          : '';
      return '${discountValue.toStringAsFixed(0)}% off$cap';
    }
    return '₹${discountValue.toStringAsFixed(0)} off';
  }

  int get daysLeft {
    final diff = validTo.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }
}

// ── FAQ data ──────────────────────────────────────────────────────────────────
const _faqs = [
  (
  q: 'How does the referral programme work?',
  a: 'Share your unique referral link or code with friends. '
      'When they sign up and purchase any Speedonet plan, '
      'you receive ₹50 credited to your Speedonet wallet and '
      'your friend gets a discount coupon for their first plan.',
  ),
  (
  q: 'How much do I earn per referral?',
  a: 'You earn ₹50 in Speedonet wallet credits for every friend '
      'who successfully signs up and activates a plan using your '
      'referral link. There is no cap — refer as many people as you like.',
  ),
  (
  q: 'What does my friend get?',
  a: 'Your friend receives a discount coupon at the time of signup. '
      'The coupon can be applied during plan purchase for an instant '
      'discount on their first Speedonet plan.',
  ),
  (
  q: 'When will the ₹50 be credited to my wallet?',
  a: 'The ₹50 reward is credited to your Speedonet wallet within '
      '24 hours of your referred friend activating their first plan. '
      'You will receive a notification once it is credited.',
  ),
  (
  q: 'Can I use my wallet credits to pay for plans?',
  a: 'Yes! Wallet credits can be used to purchase or renew any '
      'Speedonet plan directly from the app. Go to Plans → select '
      'a plan → choose Wallet as the payment method.',
  ),
  (
  q: 'Is there a limit on how many people I can refer?',
  a: 'No limit at all. You can refer as many friends, family members, '
      'or colleagues as you like. Every successful activation earns you ₹50.',
  ),
  (
  q: 'What counts as a "successful" referral?',
  a: 'A referral is counted as successful when the referred person '
      'signs up using your link, completes KYC verification, and '
      'purchases and activates their first Speedonet plan.',
  ),
  (
  q: 'My friend signed up but I did not get the reward. Why?',
  a: 'The reward is triggered only after your friend activates a paid plan. '
      'If your friend signed up but has not purchased a plan yet, '
      'the reward will be credited once they do. '
      'If the issue persists after 24 hours, please contact Support.',
  ),
  (
  q: 'Can I refer someone who already has a Speedonet account?',
  a: 'No. The referral reward applies only to new users who are '
      'signing up for the first time. Existing accounts are not eligible.',
  ),
  (
  q: 'Do wallet credits expire?',
  a: 'Wallet credits do not expire as long as your Speedonet account '
      'remains active. However, credits cannot be withdrawn as cash '
      'and can only be used for Speedonet services.',
  ),
];

// ── Terms data ────────────────────────────────────────────────────────────────
const _terms = [
  (
  heading: '1. Eligibility',
  body: 'The Speedonet Referral Programme is open to all active Speedonet '
      'subscribers with a verified account. You must be a registered '
      'customer in good standing to participate.',
  ),
  (
  heading: '2. Referral Reward',
  body: 'The referrer earns ₹50 in Speedonet wallet credits for each '
      'successful referral. A referral is deemed successful only when '
      'the referred person (a) creates a new account using the referral '
      'link or code, (b) completes KYC verification, and (c) activates '
      'a paid Speedonet plan.',
  ),
  (
  heading: '3. New-User Discount',
  body: 'A new user who signs up using a valid referral link or code '
      'receives a one-time discount coupon. The coupon is valid for '
      'a single plan purchase and cannot be combined with other offers '
      'unless explicitly stated.',
  ),
  (
  heading: '4. Wallet Credits',
  body: 'Referral rewards are credited as Speedonet wallet credits. '
      'Credits are non-transferable, non-refundable, and cannot be '
      'exchanged for cash. Credits can only be used to pay for '
      'Speedonet plans and services within the app.',
  ),
  (
  heading: '5. Credit Timeline',
  body: 'Wallet credits will be credited within 24 hours of the '
      'referred user activating their first plan. Speedonet reserves '
      'the right to withhold credits pending verification.',
  ),
  (
  heading: '6. Misuse & Fraud',
  body: 'Any attempt to manipulate or abuse the referral programme — '
      'including creating fake accounts, self-referrals, or using '
      'automated means — will result in immediate cancellation of '
      'all pending and existing rewards and may lead to account suspension.',
  ),
  (
  heading: '7. Programme Changes',
  body: 'Speedonet reserves the right to modify, suspend, or terminate '
      'the referral programme at any time without prior notice. '
      'Changes will be communicated through the app or official '
      'Speedonet channels.',
  ),
  (
  heading: '8. Disputes',
  body: 'All decisions made by Speedonet regarding referral eligibility '
      'and reward credits are final and binding. For queries, '
      'contact our support team through the Help section of the app.',
  ),
  (
  heading: '9. Governing Law',
  body: 'This programme is governed by the laws of India. '
      'Any disputes arising out of or in connection with the '
      'referral programme shall be subject to the exclusive '
      'jurisdiction of courts in the applicable city.',
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class ReferEarnScreen extends StatefulWidget {
  final String? referralCode;
  final String? referralUrl;

  const ReferEarnScreen({
    super.key,
    this.referralCode,
    this.referralUrl,
  });

  @override
  State<ReferEarnScreen> createState() => _ReferEarnScreenState();
}

class _ReferEarnScreenState extends State<ReferEarnScreen> {
  List<_Coupon> _coupons        = [];
  bool          _loadingCoupons = true;
  String?       _couponsError;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    try {
      final res = await ApiClient().get('/user/coupons');
      final List<dynamic> raw =
          (res.data['data']['coupons'] as List<dynamic>?) ?? [];
      setState(() {
        _coupons        = raw.map((e) => _Coupon.fromJson(e as Map<String, dynamic>)).toList();
        _loadingCoupons = false;
      });
    } catch (e) {
      setState(() {
        _couponsError   = 'Could not load coupons';
        _loadingCoupons = false;
      });
    }
  }

  String get _shareLink {
    if (widget.referralUrl != null && widget.referralUrl!.isNotEmpty) {
      return widget.referralUrl!;
    }
    if (widget.referralCode != null && widget.referralCode!.isNotEmpty) {
      return 'https://speedonet.in/refer?code=${widget.referralCode}';
    }
    return '';
  }

  // ── Bottom sheet helpers ──────────────────────────────────────────────────

  void _showFaq() {
    showModalBottomSheet(
      context:          context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FaqSheet(),
    );
  }

  void _showTerms() {
    showModalBottomSheet(
      context:          context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _TermsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final howItWorks = [
      {
        'icon': PhosphorIcons.shareNetwork(),
        'text': 'Invite your friends to experience any Speedonet Service.',
      },
      {
        'icon': PhosphorIcons.shoppingCart(),
        'text': 'Friend buys a new service using your referral link.',
      },
      {
        'icon': PhosphorIcons.tag(),
        'text': 'You both get discount coupons on Speedonet.',
      },
    ];

    final hasLink = _shareLink.isNotEmpty;

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

            // ── Reward highlight strip ────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.92),
                    AppColors.primary,
                  ],
                  begin: Alignment.centerLeft,
                  end:   Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  // Referrer reward
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:        Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.account_balance_wallet_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 8),
                        const Text('You Get',
                            style: TextStyle(
                                color:      Colors.white70,
                                fontSize:   11,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        const Text('₹50',
                            style: TextStyle(
                                color:      Colors.white,
                                fontSize:   22,
                                fontWeight: FontWeight.w900)),
                        const Text('Wallet Credits',
                            style: TextStyle(
                                color:   Colors.white70, fontSize: 10)),
                      ],
                    ),
                  ),
                  // Divider
                  Container(
                    width: 1, height: 70,
                    color: Colors.white.withOpacity(0.25),
                  ),
                  // Friend reward
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:  Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.local_offer_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 8),
                        const Text('Friend Gets',
                            style: TextStyle(
                                color:      Colors.white70,
                                fontSize:   11,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        const Text('Discount',
                            style: TextStyle(
                                color:      Colors.white,
                                fontSize:   22,
                                fontWeight: FontWeight.w900)),
                        const Text('On First Plan',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Hero banner ───────────────────────────────────────────────
            Container(
              width: double.infinity,
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.white,
                    Color(0xFFFF6B6B),
                    Color(0xFFFFA726),
                  ],
                  stops: [0.0, 0.4, 0.7, 1.0],
                  begin: Alignment.centerLeft,
                  end:   Alignment.centerRight,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
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
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.white.withOpacity(0.95),
                              Colors.white.withOpacity(0.0),
                            ],
                            stops: const [0.0, 0.28, 0.48],
                            begin: Alignment.centerLeft,
                            end:   Alignment.centerRight,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20, top: 0, bottom: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment:  MainAxisAlignment.center,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFFFF3B3B),
                                Color(0xFFFF8E53),
                                Color(0xFFFFA726),
                              ],
                              begin: Alignment.centerLeft,
                              end:   Alignment.centerRight,
                            ).createShader(bounds),
                            child: const Text(
                              'Refer & Earn',
                              style: TextStyle(
                                color:      Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize:   22,
                              ),
                            ),
                          ),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFFFF3B3B),
                                Color(0xFFFF8E53),
                                Color(0xFFFFA726),
                              ],
                              begin: Alignment.centerLeft,
                              end:   Alignment.centerRight,
                            ).createShader(bounds),
                            child: const Text(
                              'with Every Connection!',
                              style: TextStyle(
                                color:      Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize:   16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const SizedBox(
                            width: 165,
                            child: Text(
                              'Invite friends to join our broadband and get '
                                  'exciting rewards for every successful referral.',
                              style: TextStyle(
                                fontSize: 11,
                                color:    Colors.black54,
                                height:   1.5,
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

            // ── Referral code badge ───────────────────────────────────────
            if (widget.referralCode != null &&
                widget.referralCode!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color:        AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Referral Code',
                          style: TextStyle(
                            fontSize:   11,
                            color:      AppColors.textGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.referralCode!,
                          style: const TextStyle(
                            fontSize:      22,
                            fontWeight:    FontWeight.w900,
                            color:         AppColors.primary,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: widget.referralCode!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:  Text('Referral code copied!'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:        AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.copy_outlined,
                            size: 20, color: AppColors.textGrey),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Referral link box ─────────────────────────────────────────
            if (hasLink) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color:        Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border:       Border.all(color: AppColors.borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _shareLink,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textDark),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: _shareLink));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:  Text('Link copied!'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:        AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.copy_outlined,
                            size: 20, color: AppColors.textGrey),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color:        Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Referral link not available yet',
                    style: TextStyle(
                        color: AppColors.textGrey, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Share button ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: hasLink
                    ? () => Share.share(
                  'Join me on Speedonet! Use my referral link to sign up '
                      'and get a discount on your first plan: $_shareLink',
                  subject: 'Join Speedonet with my referral',
                )
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor:
                  AppColors.primary.withOpacity(0.4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'Share Link',
                  style: TextStyle(
                    color:      Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize:   16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── My Coupons ────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Coupons',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                if (!_loadingCoupons && _coupons.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:        AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_coupons.length} active',
                      style: const TextStyle(
                        fontSize:   11,
                        color:      AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (_loadingCoupons)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                    color:        Colors.white,
                    borderRadius: BorderRadius.circular(12)),
                child: const Center(
                  child: SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (_couponsError != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                    color:        Colors.white,
                    borderRadius: BorderRadius.circular(12)),
                child: Center(
                  child: Text(_couponsError!,
                      style: const TextStyle(
                          color: AppColors.textGrey, fontSize: 13)),
                ),
              )
            else if (_coupons.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                      color:        Colors.white,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Icon(PhosphorIcons.ticket(),
                          color: AppColors.textLight, size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'No coupons yet.\n'
                              'Referral coupons appear here after signup.',
                          style: TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 13,
                              height: 1.5),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _coupons.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _CouponCard(coupon: _coupons[i]),
                ),

            const SizedBox(height: 24),

            // ── How it works ──────────────────────────────────────────────
            const Text(
              'How it works?',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: howItWorks.length,
                separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color:  AppColors.borderColor,
                    indent: 72),
                itemBuilder: (_, i) {
                  final item = howItWorks[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.borderColor, width: 1.5),
                      ),
                      child: Center(
                        child: PhosphorIcon(
                          item['icon'] as PhosphorIconData,
                          color: AppColors.textDark,
                          size:  22,
                        ),
                      ),
                    ),
                    title: Text(
                      item['text'] as String,
                      style: const TextStyle(
                          fontSize: 13,
                          color:    AppColors.textGrey,
                          height:   1.4),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // ── FAQ & Terms — now open bottom sheets ──────────────────────
            Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    leading: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.borderColor, width: 1.5),
                      ),
                      child: Center(
                        child: PhosphorIcon(PhosphorIcons.question(),
                            color: AppColors.textDark, size: 22),
                      ),
                    ),
                    title: const Text('Frequently Asked Questions',
                        style: TextStyle(
                            fontSize:   14,
                            fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 14, color: AppColors.textLight),
                    onTap: _showFaq,   // ← opens FAQ sheet
                  ),
                  Divider(
                      height: 1,
                      color:  AppColors.borderColor,
                      indent: 72),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    leading: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.borderColor, width: 1.5),
                      ),
                      child: Center(
                        child: PhosphorIcon(PhosphorIcons.article(),
                            color: AppColors.textDark, size: 22),
                      ),
                    ),
                    title: const Text('Terms and Conditions',
                        style: TextStyle(
                            fontSize:   14,
                            fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 14, color: AppColors.textLight),
                    onTap: _showTerms,  // ← opens T&C sheet
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

// ── FAQ bottom sheet ──────────────────────────────────────────────────────────

class _FaqSheet extends StatelessWidget {
  const _FaqSheet();

  @override
  Widget build(BuildContext context) {
    return _BottomSheetWrapper(
      title: 'Frequently Asked Questions',
      child: ListView.separated(
        padding:     EdgeInsets.zero,
        shrinkWrap:  true,
        physics:     const NeverScrollableScrollPhysics(),
        itemCount:   _faqs.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey.shade200),
        itemBuilder: (_, i) => _FaqTile(item: _faqs[i]),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final ({String q, String a}) item;
  const _FaqTile({required this.item});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _open = !_open),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.item.q,
                    style: const TextStyle(
                      fontSize:   14,
                      fontWeight: FontWeight.w600,
                      color:      Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns:    _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 20, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild:  const SizedBox.shrink(),
          secondChild: Container(
            width: double.infinity,
            color: const Color(0xFFF8F8FC),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(
              widget.item.a,
              style: const TextStyle(
                fontSize: 13,
                color:    AppColors.textGrey,
                height:   1.6,
              ),
            ),
          ),
          crossFadeState: _open
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

// ── Terms bottom sheet ────────────────────────────────────────────────────────

class _TermsSheet extends StatelessWidget {
  const _TermsSheet();

  @override
  Widget build(BuildContext context) {
    return _BottomSheetWrapper(
      title: 'Terms & Conditions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Intro
          const Text(
            'By participating in the Speedonet Referral Programme, '
                'you agree to the following terms and conditions. '
                'Please read them carefully.',
            style: TextStyle(
              fontSize: 13,
              color:    AppColors.textGrey,
              height:   1.6,
            ),
          ),
          const SizedBox(height: 16),

          // Sections
          ..._terms.map(
                (t) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.heading,
                    style: const TextStyle(
                      fontSize:   14,
                      fontWeight: FontWeight.w700,
                      color:      Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.body,
                    style: const TextStyle(
                      fontSize: 13,
                      color:    AppColors.textGrey,
                      height:   1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Last updated
          const SizedBox(height: 4),
          Text(
            'Last updated: March 2026',
            style: TextStyle(
              fontSize: 11,
              color:    Colors.grey.shade400,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Shared bottom sheet wrapper ───────────────────────────────────────────────

class _BottomSheetWrapper extends StatelessWidget {
  final String title;
  final Widget child;

  const _BottomSheetWrapper({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle + header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color:        Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize:   17,
                        fontWeight: FontWeight.w800,
                        color:      Color(0xFF1A1A2E),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color:        Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 18, color: AppColors.textGrey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: Colors.grey.shade200),
              ],
            ),
          ),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Coupon card (unchanged) ───────────────────────────────────────────────────

class _CouponCard extends StatelessWidget {
  final _Coupon coupon;
  const _CouponCard({required this.coupon});

  @override
  Widget build(BuildContext context) {
    final daysLeft = coupon.daysLeft;
    final isUrgent = daysLeft <= 5;

    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUrgent
              ? Colors.orange.shade200
              : Colors.green.shade200,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: isUrgent
                    ? Colors.orange.shade400
                    : Colors.green.shade500,
                borderRadius: const BorderRadius.only(
                  topLeft:    Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            coupon.discountLabel,
                            style: TextStyle(
                              fontSize:   15,
                              fontWeight: FontWeight.w800,
                              color:      isUrgent
                                  ? Colors.orange.shade700
                                  : Colors.green.shade700,
                            ),
                          ),
                          if (coupon.description != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              coupon.description!,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color:    AppColors.textGrey),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isUrgent
                                  ? Colors.orange.shade50
                                  : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isUrgent
                                    ? Colors.orange.shade200
                                    : Colors.green.shade200,
                              ),
                            ),
                            child: Text(
                              coupon.code,
                              style: TextStyle(
                                fontSize:      13,
                                fontWeight:    FontWeight.w800,
                                letterSpacing: 1.5,
                                color: isUrgent
                                    ? Colors.orange.shade700
                                    : Colors.green.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(children: [
                            Icon(
                              Icons.access_time_rounded,
                              size:  12,
                              color: isUrgent
                                  ? Colors.orange.shade600
                                  : AppColors.textGrey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              daysLeft == 0
                                  ? 'Expires today!'
                                  : 'Expires in $daysLeft day${daysLeft == 1 ? '' : 's'}',
                              style: TextStyle(
                                fontSize:   11,
                                color:      isUrgent
                                    ? Colors.orange.shade600
                                    : AppColors.textGrey,
                                fontWeight: isUrgent
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: coupon.code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:  Text('${coupon.code} copied!'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:        AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.copy_rounded,
                                size:  18,
                                color: isUrgent
                                    ? Colors.orange.shade600
                                    : Colors.green.shade600),
                            const SizedBox(height: 2),
                            Text(
                              'Copy',
                              style: TextStyle(
                                fontSize:   9,
                                color:      isUrgent
                                    ? Colors.orange.shade600
                                    : Colors.green.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}