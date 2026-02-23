import 'package:flutter/foundation.dart';
import '../services/wallet_service.dart';

class PayViewModel extends ChangeNotifier {
  double _currentBalance = 0.00;
  bool _isLoading = false;

  double get currentBalance => _currentBalance;
  bool get isLoading => _isLoading;
  final _walletService = WalletService();

  Future<void> loadBalance() async {
    try {
      _currentBalance = await _walletService.getBalance();
      notifyListeners();
    } catch (_) {}
  }

  final List<Map<String, dynamic>> rechargeServices = [
    {'icon': 'mobile', 'label': 'Mobile\nRecharge'},
    {'icon': 'broadband', 'label': 'Broadband\nPostpaid'},
    {'icon': 'datacard', 'label': 'DataCard'},
    {'icon': 'dth', 'label': 'DTH\nRecharge'},
    {'icon': 'fastag', 'label': 'Fastag'},
    {'icon': 'cable_tv', 'label': 'Cable TV'},
  ];

  final List<Map<String, dynamic>> billPaymentServices = [
    {'icon': 'education', 'label': 'Education\nFees'},
    {'icon': 'electricity', 'label': 'Electricity'},
    {'icon': 'gas', 'label': 'Gas'},
    {'icon': 'lpg_gas', 'label': 'LPG Gas'},
    {'icon': 'landline', 'label': 'Landline\nPostpaid'},
    {'icon': 'credit_card', 'label': 'Credit Card'},
    {'icon': 'water', 'label': 'Water'},
    {'icon': 'municipal_services', 'label': 'Municipal\nServices'},
    {'icon': 'municipal_taxes', 'label': 'Municipal\nTaxes'},
    {'icon': 'loan', 'label': 'Loan\nRepayment'},
    {'icon': 'insurance', 'label': 'Insurance'},
    {'icon': 'life_insurance', 'label': 'Life\nInsurance'},
    {'icon': 'health_insurance', 'label': 'Health\nInsurance'},
    {'icon': 'hospital', 'label': 'Hospital'},
    {'icon': 'housing_society', 'label': 'Housing\nSociety'},
    {'icon': 'subscription', 'label': 'Subscription'},
    {'icon': 'nps', 'label': 'NPS'},
    {'icon': 'rental', 'label': 'Rental'},
    {'icon': 'mobile_recharge', 'label': 'Mobile\nRecharge'},
    {'icon': 'hospital_pathology', 'label': 'Hospital &\nPathology'},
    {'icon': 'ncmc', 'label': 'NCMC'},
    {'icon': 'meter', 'label': 'Meter'},
    {'icon': 'donate', 'label': 'Donate'},
  ];

  void onServiceTapped(String serviceName) {
    // Navigate to specific service
  }
}
