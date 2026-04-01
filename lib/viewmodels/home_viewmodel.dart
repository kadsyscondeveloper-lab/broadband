// lib/viewmodels/home_viewmodel.dart
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/user_service.dart';
import '../services/kyc_service.dart';
import '../widgets/dashboard_section.dart';
import '../services/notification_service.dart';
import '../services/notification_push_service.dart';

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
  int                _unreadNotifications= 0;
  int            get unreadNotifications => _unreadNotifications;

  // Legacy compat
  bool get isKycUnderReview => _kycStatus?.isPending ?? false;

  String  get userName        => _profile?.name          ?? '';
  double  get walletBalance   => _profile?.walletBalance ?? 0.0;
  bool get isAvailabilityConfirmed => _profile?.availabilityConfirmed ?? false;
  String? get profileImageUrl => _profile?.profileImageUrl;
  String  get referralCode => _profile?.referralCode ?? '';
  String  get referralUrl  => _profile?.referralUrl  ?? '';

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadProfile() async {
    NotificationPushService.onAvailabilityConfirmed = () {
      loadProfile();
    };
    _isLoading = true;
    notifyListeners();

    // Load profile + KYC in parallel
    final results = await Future.wait([
      _service.getProfile(),
      _kycService.getStatus(),
      NotificationService().getNotifications(limit: 1),
    ]);

    _profile   = results[0] as FullProfile?;
    _kycStatus = results[1] as KycStatus;
    _unreadNotifications = (results[2] as Map<String, dynamic>)['unread'] as int;

    // ── TODO: Replace with real API call when backend is ready ───────────
    // _dashboardData = await _dashboardService.getDashboard();
    _dashboardData = DashboardData.mock();
    // ─────────────────────────────────────────────────────────────────────

    _isLoading = false;
    notifyListeners();
  }

  //Refresh for motification
  Future<void> refreshUnreadCount() async {
    try {
      final result = await NotificationService().getNotifications(limit: 1);
      _unreadNotifications = result['unread'] as int;
      notifyListeners();
    } catch (_) {}
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

  Future<List<dynamic>> getCarousels() async {
    try {
      // Replace with your actual API URL
      final response = await http.get(
        Uri.parse('http://103.88.81.7:3000/api/v1/carousels'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['carousels'] ?? [];
      } else {
        print('Failed to load carousels: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error loading carousels: $e');
      return [];
    }
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