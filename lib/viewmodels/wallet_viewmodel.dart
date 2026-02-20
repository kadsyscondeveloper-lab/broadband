// lib/viewmodels/wallet_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../services/wallet_service.dart';

enum RechargeState { idle, loading, success, error }

class WalletViewModel extends ChangeNotifier {
  final _service = WalletService();

  double _balance = 0.0;
  bool   _balanceLoading = false;

  List<WalletTransaction> _transactions = [];
  bool   _txLoading = false;
  String? _txError;

  RechargeState _rechargeState = RechargeState.idle;
  String? _rechargeError;
  double? _newBalance;
  String? _lastOrderRef;

  double _selectedAmount = 0;
  final customAmountPresets = [100.0, 200.0, 500.0, 1000.0, 2000.0];

  // ── Getters ───────────────────────────────────────────────────────────────
  double  get balance         => _balance;
  bool    get balanceLoading  => _balanceLoading;
  List<WalletTransaction> get transactions => _transactions;
  bool    get txLoading       => _txLoading;
  String? get txError         => _txError;
  RechargeState get rechargeState  => _rechargeState;
  String? get rechargeError        => _rechargeError;
  double? get newBalance           => _newBalance;
  String? get lastOrderRef         => _lastOrderRef;
  double  get selectedAmount       => _selectedAmount;
  bool    get isRecharging         => _rechargeState == RechargeState.loading;

  // ── Actions ───────────────────────────────────────────────────────────────

  void setAmount(double amount) {
    _selectedAmount = amount;
    notifyListeners();
  }

  Future<void> loadBalance() async {
    _balanceLoading = true;
    notifyListeners();
    try {
      _balance = await _service.getBalance();
    } catch (_) {}
    _balanceLoading = false;
    notifyListeners();
  }

  Future<void> loadTransactions() async {
    _txLoading = true;
    _txError   = null;
    notifyListeners();
    try {
      _transactions = await _service.getTransactions();
    } catch (e) {
      _txError = e.toString();
    }
    _txLoading = false;
    notifyListeners();
  }

  Future<void> recharge({required String paymentMethod}) async {
    if (_selectedAmount < 10) {
      _rechargeError  = 'Please select or enter a valid amount (min ₹10).';
      _rechargeState  = RechargeState.error;
      notifyListeners();
      return;
    }

    _rechargeState  = RechargeState.loading;
    _rechargeError  = null;
    notifyListeners();

    final result = await _service.recharge(
      amount:        _selectedAmount,
      paymentMethod: paymentMethod,
    );

    if (result.success) {
      _rechargeState = RechargeState.success;
      _newBalance    = result.newBalance;
      _lastOrderRef  = result.orderRef;
      _balance       = result.newBalance ?? _balance;
    } else {
      _rechargeState = RechargeState.error;
      _rechargeError = result.error;
    }
    notifyListeners();
  }

  void resetRechargeState() {
    _rechargeState = RechargeState.idle;
    _rechargeError = null;
    _newBalance    = null;
    _selectedAmount = 0;
    notifyListeners();
  }
}