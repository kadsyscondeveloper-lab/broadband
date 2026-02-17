import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class CheckoutScreen extends StatefulWidget {
  final String serviceType;
  final String providerName;
  final double amount;

  const CheckoutScreen({
    super.key,
    required this.serviceType,
    required this.providerName,
    required this.amount,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedMethod = 'UPI';

  final List<Map<String, dynamic>> _payMethods = [
    {'id': 'net_banking', 'title': 'Net Banking', 'subtitle': 'Choose your bank to complete payment', 'icon': Icons.account_balance_outlined},
    {'id': 'card', 'title': 'Card', 'subtitle': 'Visa, Mastercard, Rupay & more', 'icon': Icons.credit_card_outlined},
    {'id': 'UPI', 'title': 'UPI', 'subtitle': 'PhonePe, Gpay, Paytm, BHIM & more', 'icon': Icons.send_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    final double gst = 0;
    final double total = widget.amount + gst;

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
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Paying to banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: const BoxDecoration(color: Color(0xFF2A1B8A)),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Paying to', style: TextStyle(color: Colors.white60, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              widget.providerName.isEmpty ? 'Service Provider' : widget.providerName,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          width: 36, height: 36,
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.more_horiz, color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                  ),

                  // How to pay section
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
                    child: Text('How would you like to pay?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),

                  // Payment methods
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: _payMethods.map((m) {
                        final isSelected = _selectedMethod == m['id'];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedMethod = m['id'] as String),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF7B2FFF) : AppColors.borderColor,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF7B2FFF) : AppColors.textLight,
                                      width: 2,
                                    ),
                                    color: isSelected ? const Color(0xFF7B2FFF) : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.borderColor),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(m['icon'] as IconData, size: 20, color: AppColors.textDark),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(m['title'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                      Text(m['subtitle'] as String, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Amount payable
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Amount Payable', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 12),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Base Price', style: TextStyle(color: AppColors.textGrey)),
                          Text('₹${widget.amount.toStringAsFixed(0)}'),
                        ]),
                        const SizedBox(height: 8),
                        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('GST', style: TextStyle(color: AppColors.textGrey)),
                          Text('₹0'),
                        ]),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      Text('₹${total.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1565C0))),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Secured by
                  Center(
                    child: Row(mainAxisSize: MainAxisSize.min, children: const [
                      Text('Secured by ', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
                      Text('OMNIWARE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF7B2FFF))),
                    ]),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Pay button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -3))],
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showPaymentSuccess(context, total),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Pay ₹${total.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Security badges row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _BadgeChip('3D Secure'),
                    _BadgeChip('Verified VISA'),
                    _BadgeChip('MasterCard'),
                    _BadgeChip('RuPay'),
                    _BadgeChip('PCI DSS'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentSuccess(BuildContext ctx, double total) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 60),
        const SizedBox(height: 16),
        const Text('Payment Successful!', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 8),
        Text('₹${total.toStringAsFixed(0)} paid to ${widget.providerName}',
            textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textGrey)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () { Navigator.popUntil(ctx, (r) => r.isFirst); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Go Home', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ]),
    ));
  }
}

class _BadgeChip extends StatelessWidget {
  final String label;
  const _BadgeChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w600, color: AppColors.textGrey)),
    );
  }
}
