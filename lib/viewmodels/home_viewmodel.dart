import 'package:flutter/foundation.dart';
import '../services/user_service.dart';
import '../services/kyc_service.dart';
import '../widgets/dashboard_section.dart'; // DashboardData lives here

class HomeViewModel extends ChangeNotifier {
  final _service    = UserService();
  final _kycService = KycService();

  FullProfile?   _profile;
  bool           _isLoading          = false;
  KycStatus?     _kycStatus;
  DashboardData? _dashboardData;
  int            _featureBannerIndex = 0;
  int            _promoBannerIndex   = 1;

  // ── Getters ───────────────────────────────────────────────────────────────

  FullProfile?   get profile            => _profile;
  bool           get isLoading          => _isLoading;
  KycStatus?     get kycStatus          => _kycStatus;
  DashboardData? get dashboardData      => _dashboardData;
  int            get featureBannerIndex => _featureBannerIndex;
  int            get promoBannerIndex   => _promoBannerIndex;

  // Legacy compat
  bool get isKycUnderReview => _kycStatus?.isPending ?? false;

  String get userName      => _profile?.name          ?? '';
  double get walletBalance => _profile?.walletBalance ?? 0.0;

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();

    // Load profile + KYC in parallel
    final results = await Future.wait([
      _service.getProfile(),
      _kycService.getStatus(),
    ]);

    _profile   = results[0] as FullProfile?;
    _kycStatus = results[1] as KycStatus;

    // ── TODO: Replace with real API call when backend is ready ───────────
    // _dashboardData = await _dashboardService.getDashboard();
    _dashboardData = DashboardData.mock();
    // ─────────────────────────────────────────────────────────────────────

    _isLoading = false;
    notifyListeners();
  }

  // ── Refresh wallet balance (call after purchase) ──────────────────────────

  Future<void> refreshWalletBalance() async {
    try {
      final updatedProfile = await _service.getProfile();
      if (updatedProfile != null) {
        _profile = updatedProfile;
        notifyListeners();
      }
    } catch (e) {
      print('Error refreshing wallet: $e');
      // Don't throw — just log the error
    }
  }

  // ── Refresh KYC only (call after returning from KycScreen) ────────────────

  Future<void> refreshKycStatus() async {
    _kycStatus = await _kycService.getStatus();
    notifyListeners();
  }

  // ── Banner callbacks ──────────────────────────────────────────────────────

  void onFeatureBannerPageChanged(int index) {
    _featureBannerIndex = index;
    notifyListeners();
  }

  void onPromoBannerPageChanged(int index) {
    _promoBannerIndex = index;
    notifyListeners();
  }

  void dismissKycBanner() {
    _kycStatus = KycStatus.notSubmitted();
    notifyListeners();
  }

  // ── Static data ───────────────────────────────────────────────────────────

  final List<Map<String, String>> services = [
    {'icon': 'pay_bills',   'label': 'Pay Bills'},
    {'icon': 'new_plan',    'label': 'New Plan'},
    {'icon': 'kyc',         'label': 'KYC'},
    {'icon': 'outstanding', 'label': 'Outstanding'},
    {'icon': 'my_bills',    'label': 'My Bills'},
  ];

  final List<Map<String, String>> promoItems = [
    {
      'title':    'Speedo Prime',
      'subtitle': 'Watch your favourite movies on Speedo Prime',
      'cta':      'Watch Now',
      'type':     'prime',
    },
    {
      'title':    'Speedo TV',
      'subtitle': 'Watch all OTT content in one place',
      'cta':      'Watch Now',
      'type':     'tv',
    },
  ];
}