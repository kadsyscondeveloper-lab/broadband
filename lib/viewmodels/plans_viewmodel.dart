// lib/viewmodels/plans_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/plan_model.dart';
import '../services/plan_service.dart';

enum PlanPurchaseState { idle, loading, success, error }

class PlansViewModel extends ChangeNotifier {
  final _service = PlanService();

  // ── State ────────────────────────────────────────────────────────────────────
  List<Plan> _plans = [];
  ActiveSubscription? _activeSub;
  ActiveSubscription? _queuedSub;
  bool _isLoading = false;
  String? _error;

  PlanPurchaseState _purchaseState = PlanPurchaseState.idle;
  String? _purchaseError;
  Map<String, dynamic>? _purchaseResult;

  // ── Getters ──────────────────────────────────────────────────────────────────
  List<Plan> get plans => _plans;

  ActiveSubscription? get activeSub => _activeSub;

  ActiveSubscription? get queuedSub => _queuedSub;

  bool get isLoading => _isLoading;

  String? get error => _error;

  PlanPurchaseState get purchaseState => _purchaseState;

  String? get purchaseError => _purchaseError;

  Map<String, dynamic>? get purchaseResult => _purchaseResult;

  // Group plans by validity for tab display
  List<Plan> get monthlyPlans =>
      _plans.where((p) => p.validityDays == 30).toList();

  List<Plan> get quarterlyPlans =>
      _plans.where((p) => p.validityDays == 90).toList();

  List<Plan> get annualPlans =>
      _plans.where((p) => p.validityDays == 365).toList();

  // ── Load ─────────────────────────────────────────────────────────────────────
  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getPlans(),
        _service.getActiveSubscription(),
      ]);
      _plans = results[0] as List<Plan>;
      _activeSub = results[1] as ActiveSubscription?;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Purchase ─────────────────────────────────────────────────────────────────
  Future<void> purchasePlan(int planId, {
    String paymentMode = 'wallet',
    String? couponCode,
  }) async {
    _purchaseState = PlanPurchaseState.loading;
    _purchaseError = null;
    _purchaseResult = null;
    notifyListeners();

    try {
      _purchaseResult = await _service.purchasePlan(
        planId,
        paymentMode: paymentMode,
        couponCode: couponCode,
      );
      _purchaseState = PlanPurchaseState.success;

      _activeSub = await _service.getActiveSubscription();

      final startDate = _purchaseResult?['start_date'] != null
          ? DateTime.tryParse(_purchaseResult!['start_date'].toString())
          : null;

      if (startDate != null && startDate.isAfter(DateTime.now())) {
        final planData = _purchaseResult!['plan'] as Map<String, dynamic>;
        _queuedSub = ActiveSubscription(
          id: 0,
          orderRef: _purchaseResult!['order_ref'] as String,
          status: 'active',
          amountPaid: (_purchaseResult!['amount_paid'] as num).toDouble(),
          startsAt: startDate,
          expiresAt: DateTime.tryParse(
              _purchaseResult!['expires_at'].toString()),
          planId: int.tryParse(planData['id'].toString()) ?? 0,
          planName: planData['name'] as String,
          speedMbps: (planData['speed_mbps'] as num?)?.toInt() ?? 0,
          dataLimit: planData['data_limit']?.toString() ?? 'Unlimited',
          validityDays: (planData['validity_days'] as num?)?.toInt() ?? 0,
        );
      } else {
        _queuedSub = null;
      }
    } catch (e) {
      _purchaseState = PlanPurchaseState.error;
      _purchaseError = e.toString();
    }
    notifyListeners();
  }
  void resetPurchaseState() {
    _purchaseState  = PlanPurchaseState.idle;
    _purchaseError  = null;
    _purchaseResult = null;
    notifyListeners();
  }

}