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
            'icon':      s['icon'] as String,
            'label':     (s['label'] as String).replaceAll('\\n', '\n'),
            // providers are now objects with name, icon_data, icon_mime
            'providers': (s['providers'] as List<dynamic>? ?? []).map((p) {
              if (p is Map) {
                return {
                  'name':      p['name'] as String? ?? '',
                  'icon_data': p['icon_data'] as String?,
                  'icon_mime': p['icon_mime'] as String?,
                };
              }
              // Fallback for plain strings (old API response)
              return {
                'name':      p.toString(),
                'icon_data': null,
                'icon_mime': null,
              };
            }).toList(),
          }),
        );

        billPaymentServices = List<Map<String, dynamic>>.from(
          (data['bill_payment'] as List? ?? []).map((s) => {
            'icon':      s['icon'] as String,
            'label':     (s['label'] as String).replaceAll('\\n', '\n'),
            'providers': (s['providers'] as List<dynamic>? ?? []).map((p) {
              if (p is Map) {
                return {
                  'name':      p['name'] as String? ?? '',
                  'icon_data': p['icon_data'] as String?,
                  'icon_mime': p['icon_mime'] as String?,
                };
              }
              return {
                'name':      p.toString(),
                'icon_data': null,
                'icon_mime': null,
              };
            }).toList(),
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
      {'icon': 'mobile_recharge', 'label': 'Mobile\nRecharge',    'providers': <Map<String, dynamic>>[]},
      {'icon': 'broadband',       'label': 'Broadband\nPostpaid', 'providers': <Map<String, dynamic>>[]},
      {'icon': 'datacard',        'label': 'DataCard',            'providers': <Map<String, dynamic>>[]},
      {'icon': 'dth',             'label': 'Cable TV',            'providers': <Map<String, dynamic>>[]},
    ];

    billPaymentServices = const [
      {'icon': 'electricity',        'label': 'Electricity',           'providers': <Map<String, dynamic>>[]},
      {'icon': 'gas',                'label': 'Gas',                   'providers': <Map<String, dynamic>>[]},
      {'icon': 'lpg_gas',            'label': 'LPG Gas',               'providers': <Map<String, dynamic>>[]},
      {'icon': 'water',              'label': 'Water',                 'providers': <Map<String, dynamic>>[]},
      {'icon': 'fastag',             'label': 'Fastag',                'providers': <Map<String, dynamic>>[]},
      {'icon': 'education',          'label': 'Education\nFees',       'providers': <Map<String, dynamic>>[]},
      {'icon': 'landline',           'label': 'Landline\nPostpaid',    'providers': <Map<String, dynamic>>[]},
      {'icon': 'credit_card',        'label': 'Credit Card',           'providers': <Map<String, dynamic>>[]},
      {'icon': 'municipal_services', 'label': 'Municipal\nServices',   'providers': <Map<String, dynamic>>[]},
      {'icon': 'municipal_taxes',    'label': 'Municipal\nTaxes',      'providers': <Map<String, dynamic>>[]},
      {'icon': 'loan',               'label': 'Loan\nRepayment',       'providers': <Map<String, dynamic>>[]},
      {'icon': 'insurance',          'label': 'Insurance',             'providers': <Map<String, dynamic>>[]},
      {'icon': 'life_insurance',     'label': 'Life\nInsurance',       'providers': <Map<String, dynamic>>[]},
      {'icon': 'health_insurance',   'label': 'Health\nInsurance',     'providers': <Map<String, dynamic>>[]},
      {'icon': 'hospital',           'label': 'Hospital',              'providers': <Map<String, dynamic>>[]},
      {'icon': 'hospital_pathology', 'label': 'Hospital &\nPathology', 'providers': <Map<String, dynamic>>[]},
      {'icon': 'housing_society',    'label': 'Housing\nSociety',      'providers': <Map<String, dynamic>>[]},
      {'icon': 'subscription',       'label': 'Subscription',          'providers': <Map<String, dynamic>>[]},
      {'icon': 'nps',                'label': 'NPS',                   'providers': <Map<String, dynamic>>[]},
      {'icon': 'rental',             'label': 'Rental',                'providers': <Map<String, dynamic>>[]},
      {'icon': 'ncmc',               'label': 'NCMC',                  'providers': <Map<String, dynamic>>[]},
      {'icon': 'meter',              'label': 'Meter',                 'providers': <Map<String, dynamic>>[]},
      {'icon': 'donate',             'label': 'Donate',                'providers': <Map<String, dynamic>>[]},
    ];
  }
}