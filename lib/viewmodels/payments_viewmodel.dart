import 'package:flutter/foundation.dart';
import '../models/help_ticket_model.dart';

class PaymentsViewModel extends ChangeNotifier {
  List<PaymentTransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _error;

  List<PaymentTransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasTransactions => _transactions.isNotEmpty;

  Future<void> loadTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 800));
      _transactions = []; // No transactions yet
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkForTransactions() async {
    await loadTransactions();
  }
}
