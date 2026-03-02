// lib/viewmodels/pay_viewmodel.dart
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../services/wallet_service.dart';

class PayViewModel extends ChangeNotifier {
  final _api           = ApiClient();
  final _walletService = WalletService();

  double  _currentBalance = 0.00;
  bool    _isLoading      = true;

  List<Map<String, dynamic>> rechargeServices    = [];
  List<Map<String, dynamic>> billPaymentServices = [];

  double get currentBalance => _currentBalance;
  bool   get isLoading      => _isLoading;

  PayViewModel() {
    _init();
  }

  Future<void> _init() async {
    await Future.wait([_loadServices(), _loadBalance()]);
  }

  Future<void> _loadServices() async {
    try {
      final response = await _api.get('/pay/services');

      if (response.statusCode == 200) {
        final data = response.data['data'];

        rechargeServices = List<Map<String, dynamic>>.from(
          (data['recharge'] as List? ?? []).map((s) => {
            'icon':      s['icon']      as String,
            'label':     s['label']     as String,
            'providers': s['providers'] as List<dynamic>? ?? [],
          }),
        );

        billPaymentServices = List<Map<String, dynamic>>.from(
          (data['bill_payment'] as List? ?? []).map((s) => {
            'icon':      s['icon']      as String,
            'label':     s['label']     as String,
            'providers': s['providers'] as List<dynamic>? ?? [],
          }),
        );
      } else {
        _applyFallback();
      }
    } on DioException catch (_) {
      _applyFallback();
    } catch (_) {
      _applyFallback();
    }
  }

  Future<void> _loadBalance() async {
    try {
      _currentBalance = await _walletService.getBalance();
    } catch (_) {
      _currentBalance = 0.0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    await _init();
  }

  // Shown only if the server is completely unreachable.
  // Providers are empty — screen falls through to ServiceDetailScreen.
  void _applyFallback() {
    rechargeServices = const [
      {'icon': 'mobile_recharge', 'label': 'Mobile\nRecharge',    'providers': <String>[]},
      {'icon': 'broadband',       'label': 'Broadband\nPostpaid', 'providers': <String>[]},
      {'icon': 'datacard',        'label': 'DataCard',            'providers': <String>[]},
      {'icon': 'dth',             'label': 'Cable TV',            'providers': <String>[]},
    ];

    billPaymentServices = const [
      {'icon': 'electricity',        'label': 'Electricity',           'providers': <String>[]},
      {'icon': 'gas',                'label': 'Gas',                   'providers': <String>[]},
      {'icon': 'lpg_gas',            'label': 'LPG Gas',               'providers': <String>[]},
      {'icon': 'water',              'label': 'Water',                 'providers': <String>[]},
      {'icon': 'fastag',             'label': 'Fastag',                'providers': <String>[]},
      {'icon': 'education',          'label': 'Education\nFees',       'providers': <String>[]},
      {'icon': 'landline',           'label': 'Landline\nPostpaid',    'providers': <String>[]},
      {'icon': 'credit_card',        'label': 'Credit Card',           'providers': <String>[]},
      {'icon': 'municipal_services', 'label': 'Municipal\nServices',   'providers': <String>[]},
      {'icon': 'municipal_taxes',    'label': 'Municipal\nTaxes',      'providers': <String>[]},
      {'icon': 'loan',               'label': 'Loan\nRepayment',       'providers': <String>[]},
      {'icon': 'insurance',          'label': 'Insurance',             'providers': <String>[]},
      {'icon': 'life_insurance',     'label': 'Life\nInsurance',       'providers': <String>[]},
      {'icon': 'health_insurance',   'label': 'Health\nInsurance',     'providers': <String>[]},
      {'icon': 'hospital',           'label': 'Hospital',              'providers': <String>[]},
      {'icon': 'hospital_pathology', 'label': 'Hospital &\nPathology', 'providers': <String>[]},
      {'icon': 'housing_society',    'label': 'Housing\nSociety',      'providers': <String>[]},
      {'icon': 'subscription',       'label': 'Subscription',          'providers': <String>[]},
      {'icon': 'nps',                'label': 'NPS',                   'providers': <String>[]},
      {'icon': 'rental',             'label': 'Rental',                'providers': <String>[]},
      {'icon': 'ncmc',               'label': 'NCMC',                  'providers': <String>[]},
      {'icon': 'meter',              'label': 'Meter',                 'providers': <String>[]},
      {'icon': 'donate',             'label': 'Donate',                'providers': <String>[]},
    ];
  }
}