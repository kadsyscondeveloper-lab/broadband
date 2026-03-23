// lib/viewmodels/plans_viewmodel.dart
//
// BUG FIXES:
//
// Bug 1 — First purchase wrongly shows "Plan Queued":
//   OLD: Flutter compared start_date (server time) with DateTime.now() (device time).
//        Clock skew of even 1 second between server and device triggered this.
//   FIX: Server now returns `is_queued: bool` in the purchase response.
//        Flutter reads that flag — no client-side date comparison at all.
//
// Bug 2 — Double plan shown after purchase:
//   OLD: _activeSub was set from getActiveSubscription() AND _queuedSub was
//        set from the purchase response for the same plan.
//   FIX: After purchase, re-fetch BOTH subscriptions from the API.
//        Since the server sets is_queued correctly, there's never a double.
//
// Bug 3 — Queued plan disappears on re-entering the plans screen:
//   OLD: _queuedSub was only set during purchasePlan() and held in memory.
//        load() never fetched it, so it was null on every re-entry.
//   FIX: load() now calls getQueuedSubscription() every time, so the queued
//        plan persists across screen exits and re-entries.

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

  // ── Load ─────────────────────────────────────────────────────────────────────
  // FIX (Bug 3): load() now fetches BOTH the active and queued subscriptions
  // every time, so the queued plan is always visible on re-entry.

  Future<void> load() async {
    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getPlans(),
        _service.getActiveSubscription(),
        _service.getQueuedSubscription(),   // ← FIX: always fetch queued sub
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
  // FIX (Bug 1 + Bug 2):
  //   • No longer uses client-side date comparison to determine is_queued.
  //     Server returns `is_queued: true/false` — we trust that.
  //   • After purchase, re-fetches BOTH subscriptions from the API instead of
  //     constructing _queuedSub from the purchase response. This prevents the
  //     double-plan bug because the server never returns the same plan in both
  //     active and queued slots simultaneously.

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

      // Re-fetch both subscriptions from the server.
      // Server's is_queued flag (in _purchaseResult) tells the UI what to show,
      // and the API calls ensure state is correct after leaving and re-entering.
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