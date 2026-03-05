// lib/views/refer/refer_earn_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/api_client.dart';
import '../../theme/app_theme.dart';

// ── Simple coupon model (matches GET /api/v1/user/coupons response) ───────────
class _Coupon {
  final String  code;
  final String? description;
  final String  discountType;   // 'percentage' | 'flat'
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
  List<_Coupon> _coupons     = [];
  bool          _loadingCoupons = true;
  String?       _couponsError;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    try {
      // Calls GET /api/v1/user/coupons via your existing ApiClient
      final res = await ApiClient().get('/user/coupons');
      final List<dynamic> raw =
          (res.data['data']['coupons'] as List<dynamic>?) ?? [];
      setState(() {
        _coupons       = raw.map((e) => _Coupon.fromJson(e as Map<String, dynamic>)).toList();
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
                  end: Alignment.centerRight,
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
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20, top: 0, bottom: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                const LinearGradient(
                                  colors: [
                                    Color(0xFFFF3B3B),
                                    Color(0xFFFF8E53),
                                    Color(0xFFFFA726),
                                  ],
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
                            shaderCallback: (bounds) =>
                                const LinearGradient(
                                  colors: [
                                    Color(0xFFFF3B3B),
                                    Color(0xFFFF8E53),
                                    Color(0xFFFFA726),
                                  ],
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
                              'Invite friends to join our broadband and get '
                                  'exciting rewards for every successful referral.',
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

            // ── Referral code badge ───────────────────────────────────────
            if (widget.referralCode != null && widget.referralCode!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
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
                        Clipboard.setData(ClipboardData(text: widget.referralCode!));
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                        style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _shareLink));
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
                    style: TextStyle(color: AppColors.textGrey, fontSize: 13),
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
                  backgroundColor:         AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
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

            // ── MY COUPONS SECTION ────────────────────────────────────────
            // Shows active referral coupons the user received on signup.
            // Fetched from GET /api/v1/user/coupons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Coupons',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                if (!_loadingCoupons && _coupons.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                  borderRadius: BorderRadius.circular(12),
                ),
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _couponsError!,
                    style: const TextStyle(
                        color: AppColors.textGrey, fontSize: 13),
                  ),
                ),
              )
            else if (_coupons.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color:        Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(PhosphorIcons.ticket(),
                          color: AppColors.textLight, size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'No coupons yet.\nReferral coupons appear here after signup.',
                          style: TextStyle(
                              color: AppColors.textGrey, fontSize: 13, height: 1.5),
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
                  itemBuilder: (_, i) => _CouponCard(coupon: _coupons[i]),
                ),
            // ─────────────────────────────────────────────────────────────

            const SizedBox(height: 24),

            // ── How it works ──────────────────────────────────────────────
            const Text(
              'How it works?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: howItWorks.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: AppColors.borderColor, indent: 72),
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
                          fontSize: 13, color: AppColors.textGrey, height: 1.4),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // ── FAQ & Terms ───────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
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
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 14, color: AppColors.textLight),
                    onTap: () {},
                  ),
                  Divider(
                      height: 1, color: AppColors.borderColor, indent: 72),
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
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 14, color: AppColors.textLight),
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

// ── Coupon card ───────────────────────────────────────────────────────────────

class _CouponCard extends StatelessWidget {
  final _Coupon coupon;
  const _CouponCard({required this.coupon});

  @override
  Widget build(BuildContext context) {
    final daysLeft  = coupon.daysLeft;
    final isUrgent  = daysLeft <= 5;

    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(
          color: isUrgent
              ? Colors.orange.shade200
              : Colors.green.shade200,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left coloured strip
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

            // Content
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
                          // Discount headline
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
                                  fontSize: 11, color: AppColors.textGrey),
                            ),
                          ],
                          const SizedBox(height: 8),
                          // Code chip
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
                          // Expiry
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

                    // Copy button
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
                            Icon(
                              Icons.copy_rounded,
                              size:  18,
                              color: isUrgent
                                  ? Colors.orange.shade600
                                  : Colors.green.shade600,
                            ),
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