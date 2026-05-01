// lib/viewmodels/home_viewmodel.dart

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/user_service.dart';
import '../services/kyc_service.dart';
import '../services/rent_service.dart';
import '../widgets/dashboard_section.dart';
import '../services/notification_service.dart';
import '../services/notification_push_service.dart';
import '../core/app_config.dart';

class HomeViewModel extends ChangeNotifier {
  final _service     = UserService();
  final _kycService  = KycService();
  final _rentService = RentService();

  FullProfile?   _profile;
  bool           _isLoading           = false;
  KycStatus?     _kycStatus;
  DashboardData? _dashboardData;
  int            _featureBannerIndex  = 0;
  int            _promoBannerIndex    = 1;
  RentStatus     _rentStatus          = RentStatus.empty();
  bool           _isCollecting        = false;

  int _unreadNotifications = 0;

  // ── Getters ───────────────────────────────────────────────────────────────

  FullProfile?   get profile             => _profile;
  bool           get isLoading           => _isLoading;
  KycStatus?     get kycStatus           => _kycStatus;
  DashboardData? get dashboardData       => _dashboardData;
  int            get featureBannerIndex  => _featureBannerIndex;
  int            get promoBannerIndex    => _promoBannerIndex;
  int            get unreadNotifications => _unreadNotifications;
  RentStatus     get rentStatus          => _rentStatus;
  bool           get isCollecting        => _isCollecting;

  bool    get isKycUnderReview       => _kycStatus?.isPending ?? false;
  String  get userName               => _profile?.name          ?? '';
  double  get walletBalance          => _profile?.walletBalance  ?? 0.0;
  bool    get isAvailabilityConfirmed => _profile?.availabilityConfirmed ?? false;
  String? get profileImageUrl        => _profile?.profileImageUrl;
  String  get referralCode           => _profile?.referralCode ?? '';
  String  get referralUrl            => _profile?.referralUrl  ?? '';

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadProfile() async {
    NotificationPushService.onAvailabilityConfirmed = () => loadProfile();
    _isLoading = true;
    notifyListeners();

    final results = await Future.wait([
      _service.getProfile(),
      _kycService.getStatus(),
      NotificationService().getNotifications(limit: 1),
      _rentService.getStatus(),
    ]);

    _profile             = results[0] as FullProfile?;
    _kycStatus           = results[1] as KycStatus;
    _unreadNotifications = (results[2] as Map<String, dynamic>)['unread'] as int;
    _rentStatus          = results[3] as RentStatus;
    _dashboardData       = DashboardData.mock();

    _isLoading = false;
    notifyListeners();
  }

  // ── Collect rent ──────────────────────────────────────────────────────────

  /// Returns null on success, error message on failure.
  Future<String?> collectRent() async {
    _isCollecting = true;
    notifyListeners();

    final result = await _rentService.collect();
    _isCollecting = false;

    if (result.success) {
      await Future.wait([refreshWalletBalance(), refreshRentStatus()]);
      return null;
    }

    notifyListeners();
    return result.error ?? 'Could not collect rent. Please try again.';
  }

  Future<void> refreshRentStatus() async {
    try {
      _rentStatus = await _rentService.getStatus();
      notifyListeners();
    } catch (_) {}
  }

  // ── Other refresh helpers ─────────────────────────────────────────────────

  Future<void> refreshUnreadCount() async {
    try {
      final result = await NotificationService().getNotifications(limit: 1);
      _unreadNotifications = result['unread'] as int;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshWalletBalance() async {
    try {
      final updated = await _service.getProfile();
      if (updated != null) { _profile = updated; notifyListeners(); }
    } catch (_) {}
  }

  Future<void> refreshKycStatus() async {
    _kycStatus = await _kycService.getStatus();
    notifyListeners();
  }

  @override
  void dispose() {
    NotificationPushService.onAvailabilityConfirmed = null;
    super.dispose();
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

  // ── Carousels ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCarousels() async {
    try {
      final response = await http.get(Uri.parse('${AppConfig.baseUrl}/carousels'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ((data['data']['carousels'] ?? []) as List).cast();
      }
      return [];
    } catch (_) { return []; }
  }

  Future<void> trackCarouselClick(int bannerId) async {
    try {
      await http.post(Uri.parse('${AppConfig.baseUrl}/carousels/$bannerId/click'));
    } catch (_) {}
  }

  // ── Services grid data ─── ← Collect is now the 6th tile ─────────────────

  final List<Map<String, String>> services = [
    {'icon': 'pay_bills',   'label': 'Pay Bills'},
    {'icon': 'new_plan',    'label': 'New Plan'},
    {'icon': 'kyc',         'label': 'KYC'},
    {'icon': 'outstanding', 'label': 'Outstanding'},
    {'icon': 'my_bills',    'label': 'My Bills'},
    {'icon': 'collect',     'label': 'Collect'},     // ← NEW
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