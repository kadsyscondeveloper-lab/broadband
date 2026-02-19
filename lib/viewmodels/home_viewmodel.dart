import 'package:flutter/foundation.dart';
import '../services/user_service.dart';

class HomeViewModel extends ChangeNotifier {
  final _service = UserService();

  FullProfile? _profile;
  bool _isLoading        = false;
  bool _isKycUnderReview = false;
  int  _featureBannerIndex = 0;
  int  _promoBannerIndex   = 1;

  // ── Getters ───────────────────────────────────────────────────────────────

  FullProfile? get profile        => _profile;
  bool   get isLoading            => _isLoading;
  bool   get isKycUnderReview     => _isKycUnderReview;
  int    get featureBannerIndex   => _featureBannerIndex;
  int    get promoBannerIndex     => _promoBannerIndex;

  // Convenience — UI uses these directly
  String get userName      => _profile?.name          ?? '';
  double get walletBalance => _profile?.walletBalance ?? 0.0;

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();

    _profile = await _service.getProfile();

    // Drive the KYC banner from the real status
    final kyc = _profile?.kycStatus ?? '';
    _isKycUnderReview = kyc == 'pending' || kyc == 'under_review';

    _isLoading = false;
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
    _isKycUnderReview = false;
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