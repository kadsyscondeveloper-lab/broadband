import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class HomeViewModel extends ChangeNotifier {
  UserModel _user = UserModel(
    name: 'Paradeep Tech',
    phone: '+91-6354785693',
    email: 'paradeeptech@gmail.com',
    state: 'Delhi',
    city: 'Bawana',
    houseNo: '3E-1 NITHARI Rohini North West Delhi India 110086',
    address: 'fhhhhj',
    pinCode: '110086',
    walletBalance: 0.00,
  );

  bool _isKycUnderReview = true;
  int _featureBannerIndex = 0;
  int _promoBannerIndex = 1;

  UserModel get user => _user;
  bool get isKycUnderReview => _isKycUnderReview;
  int get featureBannerIndex => _featureBannerIndex;
  int get promoBannerIndex => _promoBannerIndex;

  void onFeatureBannerPageChanged(int index) {
    _featureBannerIndex = index;
    notifyListeners();
  }

  void onPromoBannerPageChanged(int index) {
    _promoBannerIndex = index;
    notifyListeners();
  }

  void checkKycStatus() {
    // In real app, call API to check KYC status
    notifyListeners();
  }

  void dismissKycBanner() {
    _isKycUnderReview = false;
    notifyListeners();
  }

  final List<Map<String, String>> services = [
    {'icon': 'pay_bills', 'label': 'Pay Bills'},
    {'icon': 'new_plan', 'label': 'New Plan'},
    {'icon': 'kyc', 'label': 'KYC'},
    {'icon': 'outstanding', 'label': 'Outstanding'},
    {'icon': 'my_bills', 'label': 'My Bills'},
  ];

  final List<Map<String, String>> promoItems = [
    {
      'title': 'Speedo Prime',
      'subtitle': 'Watch your favourite movies on Speedo Prime',
      'cta': 'Watch Now',
      'type': 'prime',
    },
    {
      'title': 'Speedo TV',
      'subtitle': 'Watch all OTT content in one place',
      'cta': 'Watch Now',
      'type': 'tv',
    },
  ];
}
