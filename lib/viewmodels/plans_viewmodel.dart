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
  bool _isLoading = false;
  String? _error;

  PlanPurchaseState _purchaseState = PlanPurchaseState.idle;
  String? _purchaseError;
  Map<String, dynamic>? _purchaseResult;

  // ── Getters ──────────────────────────────────────────────────────────────────
  List<Plan> get plans        => _plans;
  ActiveSubscription? get activeSub => _activeSub;
  bool get isLoading          => _isLoading;
  String? get error           => _error;

  PlanPurchaseState get purchaseState  => _purchaseState;
  String? get purchaseError            => _purchaseError;
  Map<String, dynamic>? get purchaseResult => _purchaseResult;

  // Group plans by validity for tab display
  List<Plan> get monthlyPlans    => _plans.where((p) => p.validityDays == 30).toList();
  List<Plan> get quarterlyPlans  => _plans.where((p) => p.validityDays == 90).toList();
  List<Plan> get annualPlans     => _plans.where((p) => p.validityDays == 365).toList();

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
      _plans     = results[0] as List<Plan>;
      _activeSub = results[1] as ActiveSubscription?;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Purchase ─────────────────────────────────────────────────────────────────
  Future<void> purchasePlan(int planId, {String paymentMode = 'wallet'}) async {
    _purchaseState = PlanPurchaseState.loading;
    _purchaseError = null;
    _purchaseResult = null;
    notifyListeners();

    try {
      _purchaseResult = await _service.purchasePlan(planId, paymentMode: paymentMode);
      _purchaseState  = PlanPurchaseState.success;
      // Refresh active subscription after purchase
      _activeSub = await _service.getActiveSubscription();
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