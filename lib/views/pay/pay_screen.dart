import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/pay_viewmodel.dart';
import '../recharge/mobile_recharge_screen.dart';
import '../recharge/provider_list_screen.dart';
import '../recharge/service_detail_screen.dart';

class PayScreen extends StatelessWidget {
  final PayViewModel viewModel;

  const PayScreen({super.key, required this.viewModel});

  static final Map<String, List<String>> _providerData = {
    // ← Speedonet first so it appears at the top of the list
    'Broadband\nPostpaid': ['Speedonet', 'ACT Fibernet', 'AirJaldi - Rural Broadband', 'Airtel Broadband', 'Alliance Broadband Services Pvt. Ltd.', 'Comway Broadband', 'Connect Broadband', 'DEN Broadband', 'Hathway Broadband', 'MTNL Broadband', 'YOU Broadband'],
    'Fastag': ['Axis Bank FASTag', 'Bank of Baroda - Fastag', 'Equitas FASTag Recharge', 'Federal Bank - FASTag', 'HDFC  Bank - Fastag', 'ICICI Bank Fastag', 'IDFC FIRST Bank - FasTag', 'Indian Highways Management Company Ltd FASTag', 'IndusInd Bank FASTag'],
    'Cable TV': ['Airtel Digital TV', 'Dish TV', 'Reliance Digital TV', 'Sun Direct', 'Tata Sky', 'Videocon d2h'],
    'Education\nFees': ['5Th Centenary School', '7I World School Shivpuri Link Road Gwalior', 'A A M Childrens Academy', 'A B C Alma Mater', 'A B M Public School', 'A B S International School', 'A E S Public School', 'A I International School, Uppal Jagir, Nurmahal Nakodar Road'],
    'Electricity': ['Adani Electricity Mumbai Limited', 'Ajmer Vidyut Vitran Nigam Limited (AVVNL)', 'Assam Power Distribution Company Ltd (NON-RAPDR)', 'B.E.S.T Mumbai', 'Bangalore Electricity Supply Co. Ltd (BESCOM)', 'Bhartpur Electricity Services Ltd. (BESL)', 'Bikaner Electricity Supply Limited (BkESL)'],
    'Gas': ['Aavantika Gas Ltd.', 'Adani Total Gas Limited', 'Assam Gas Company Limited', 'Bhagyanagar Gas Limited', 'Central U.P. Gas Limited', 'Charotar Gas Sahakari Mandali Ltd', 'GAIL Gas Limited', 'Gail India Limited', 'Green Gas Limited(GGL)'],
    'LPG Gas': ['Bharat Gas (BPCL)', 'HP Gas (HPCL)', 'Indane Gas (IOCL)'],
    'Landline\nPostpaid': ['Airtel Landline', 'BSNL Landline', 'MTNL Delhi', 'MTNL Mumbai', 'Reliance Landline'],
    'Credit Card': ['Axis Bank Credit Card', 'HDFC Credit Card', 'ICICI Credit Card', 'Kotak Credit Card', 'SBI Credit Card'],
    'Water': ['Bangalore Water Supply (BWSSB)', 'Delhi Jal Board', 'Mumbai Water Dept.', 'Pune Municipal Corporation'],
    'Municipal\nServices': ['Ahmedabad Municipal Corporation', 'BBMP Bengaluru', 'Brihanmumbai Municipal Corporation (BMC)', 'Delhi Municipal Corporation'],
    'Municipal\nTaxes': ['Ahmedabad Municipal Corporation', 'Pune Municipal Corporation', 'BBMP Bengaluru'],
    'Loan\nRepayment': ['Axis Bank Loan', 'Bajaj Finance', 'HDFC Bank Loan', 'ICICI Bank Loan', 'LIC Housing Finance', 'Muthoot Finance'],
    'Insurance': ['Bajaj Allianz', 'Bharti AXA', 'HDFC Ergo', 'ICICI Lombard', 'New India Assurance', 'Star Health'],
    'Life\nInsurance': ['Bajaj Allianz Life', 'HDFC Life', 'ICICI Prudential Life', 'LIC', 'Max Life Insurance', 'SBI Life Insurance'],
    'Health\nInsurance': ['Bajaj Allianz Health', 'Care Health Insurance', 'HDFC Ergo Health', 'Niva Bupa Health Insurance', 'Star Health Insurance'],
    'Hospital': ['Apollo Hospitals', 'Fortis Healthcare', 'Max Healthcare', 'Medanta'],
    'Housing\nSociety': ['Apna Complex', 'MyGate Housing Society', 'NoBrokerHood'],
    'Subscription': ['Amazon Prime', 'Disney+ Hotstar', 'Netflix', 'Sony LIV', 'ZEE5'],
    'NPS': ['NPS - Central Record Keeping Agency (NSDL)', 'NPS - Karvy'],
    'Rental': ['NestAway Rent', 'NoBroker Rent', 'Rentomojo'],
    'NCMC': ['NCMC - Delhi Metro', 'NCMC - Mumbai Metro', 'NCMC - Rupay'],
    'Meter': ['Smart Meter - BSES', 'Smart Meter - TATA Power'],
    'Donate': ['CRY', 'HelpAge India', 'PM CARES Fund', 'UNICEF India'],
    'DataCard': ['Airtel Dongle', 'BSNL DataCard', 'Idea DataCard', 'Jio DataCard', 'Vodafone DataCard'],
    'Hospital &\nPathology': ['Apollo Diagnostics', 'Dr. Lal PathLabs', 'Metropolis Healthcare', 'SRL Diagnostics'],
  };

  void _navigate(BuildContext context, String serviceLabel) {
    if (serviceLabel == 'Mobile\nRecharge' || serviceLabel == 'Mobile Recharge') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileRechargeScreen()));
      return;
    }
    final providers = _providerData[serviceLabel];
    final cleanType = serviceLabel.replaceAll('\n', ' ');
    if (providers != null && providers.isNotEmpty) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ProviderListScreen(serviceType: cleanType, providers: providers),
      ));
    } else {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ServiceDetailScreen(serviceType: cleanType, providerName: cleanType),
      ));
    }
  }

  IconData _getIcon(String iconKey) {
    switch (iconKey) {
      case 'mobile': case 'mobile_recharge': return Icons.phone_android_outlined;
      case 'broadband': return Icons.wifi_outlined;
      case 'datacard': return Icons.usb_outlined;
      case 'dth': return Icons.satellite_alt_outlined;
      case 'fastag': return Icons.toll_outlined;
      case 'cable_tv': return Icons.tv_outlined;
      case 'education': return Icons.school_outlined;
      case 'electricity': return Icons.bolt_outlined;
      case 'gas': case 'lpg_gas': return Icons.local_gas_station_outlined;
      case 'landline': return Icons.phone_outlined;
      case 'credit_card': return Icons.credit_card_outlined;
      case 'water': return Icons.water_drop_outlined;
      case 'municipal_services': case 'municipal_taxes': return Icons.account_balance_outlined;
      case 'loan': return Icons.handshake_outlined;
      case 'insurance': case 'health_insurance': case 'life_insurance': return Icons.health_and_safety_outlined;
      case 'hospital': case 'hospital_pathology': return Icons.local_hospital_outlined;
      case 'housing_society': return Icons.apartment_outlined;
      case 'subscription': return Icons.subscriptions_outlined;
      case 'nps': return Icons.savings_outlined;
      case 'rental': return Icons.home_work_outlined;
      case 'ncmc': return Icons.train_outlined;
      case 'meter': return Icons.speed_outlined;
      case 'donate': return Icons.volunteer_activism_outlined;
      default: return Icons.grid_view_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomNavHeight = 64 + 16 + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          return CustomScrollView(
            slivers: [
              // ── Header ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 20, right: 20, bottom: 32,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      bottomLeft:  Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(10)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('BHARAT BILL PAYMENT',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13,
                                letterSpacing: 0.5, color: AppColors.textDark)),
                        Row(children: [
                          Container(width: 24, height: 24,
                              decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          const Text('Bharat\nConnect',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                                  color: Color(0xFF1565C0))),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    const Text('Current Balance',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text('₹${viewModel.currentBalance.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontSize: 36,
                            fontWeight: FontWeight.w800)),
                  ]),
                ),
              ),

              // ── Recharge section ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: _ServiceSection(
                    title: 'Recharge',
                    services: viewModel.rechargeServices,
                    getIcon: _getIcon,
                    onTap: (l) => _navigate(context, l),
                  ),
                ),
              ),

              // ── Bill Payment section ────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, bottomNavHeight + 8),
                  child: _ServiceSection(
                    title: 'Bill Payment',
                    services: viewModel.billPaymentServices,
                    getIcon: _getIcon,
                    onTap: (l) => _navigate(context, l),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE SECTION  — uses Wrap instead of GridView (no overflow ever)
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> services;
  final IconData Function(String) getIcon;
  final Function(String) onTap;

  const _ServiceSection({
    required this.title,
    required this.services,
    required this.getIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final itemWidth = (MediaQuery.of(context).size.width - 32 - 40) / 4;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 0,
            runSpacing: 16,
            children: services.map((s) {
              return SizedBox(
                width: itemWidth,
                child: GestureDetector(
                  onTap: () => onTap(s['label'] as String),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEEEEF5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          getIcon(s['icon'] as String),
                          color: const Color(0xFF3D4066),
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s['label'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}