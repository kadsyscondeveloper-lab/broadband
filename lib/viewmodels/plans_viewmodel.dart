// lib/viewmodels/plans_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/plan_model.dart';
import '../services/plan_service.dart';

enum PlanPurchaseState { idle, loading, success, error }

class PlansViewModel extends ChangeNotifier {
  final _service = PlanService();

  // ── State ────────────────────────────────────────────────────────────────────
  List<Plan>          _plans     = [];
  ActiveSubscription? _activeSub;
  ActiveSubscription? _queuedSub;
  bool                _isLoading = false;
  String?             _error;

  PlanPurchaseState        _purchaseState  = PlanPurchaseState.idle;
  String?                  _purchaseError;
  Map<String, dynamic>?    _purchaseResult;

  // ── Getters ──────────────────────────────────────────────────────────────────
  List<Plan>          get plans         => _plans;
  ActiveSubscription? get activeSub     => _activeSub;
  ActiveSubscription? get queuedSub     => _queuedSub;
  bool                get isLoading     => _isLoading;
  String?             get error         => _error;
  PlanPurchaseState   get purchaseState => _purchaseState;
  String?             get purchaseError => _purchaseError;
  Map<String, dynamic>? get purchaseResult => _purchaseResult;

  List<Plan> get monthlyPlans   => _plans.where((p) => p.validityDays == 30).toList();
  List<Plan> get quarterlyPlans => _plans.where((p) => p.validityDays == 90).toList();
  List<Plan> get annualPlans    => _plans.where((p) => p.validityDays == 365).toList();

  // ── Purchase eligibility ─────────────────────────────────────────────────────
  //
  // Rules (mirror the backend guards in planService.purchasePlan):
  //   • If a queued plan already exists → blocked (one queue slot only)
  //   • If the active plan has > 2 days remaining → blocked (renewal window)
  //   • Otherwise → allowed

  /// Whether the user is currently allowed to purchase / queue a new plan.
  bool get canPurchaseNewPlan {
    if (_queuedSub != null) return false;  // already one plan queued
    if (_activeSub == null) return true;   // no active plan → can buy freely
    return _activeSub!.daysRemaining <= 2; // within the 2-day renewal window
  }

  /// The earliest calendar date the user can renew (active expiry minus 2 days).
  /// Returns null when there is no active subscription.
  DateTime? get renewalAvailableFrom {
    if (_activeSub?.expiresAt == null) return null;
    return _activeSub!.expiresAt!.subtract(const Duration(days: 2));
  }

  // ── Load ─────────────────────────────────────────────────────────────────────
  Future<void> load() async {
    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getPlans(),
        _service.getActiveSubscription(),
        _service.getQueuedSubscription(),
      ]);
      _plans     = results[0] as List<Plan>;
      _activeSub = results[1] as ActiveSubscription?;
      _queuedSub = results[2] as ActiveSubscription?;
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
    _purchaseState  = PlanPurchaseState.loading;
    _purchaseError  = null;
    _purchaseResult = null;
    notifyListeners();

    try {
      _purchaseResult = await _service.purchasePlan(
        planId,
        paymentMode: paymentMode,
        couponCode:  couponCode,
      );
      _purchaseState = PlanPurchaseState.success;

      // Re-fetch both subscriptions so state is accurate on re-entry.
      final results = await Future.wait([
        _service.getActiveSubscription(),
        _service.getQueuedSubscription(),
      ]);
      _activeSub = results[0] as ActiveSubscription?;
      _queuedSub = results[1] as ActiveSubscription?;

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