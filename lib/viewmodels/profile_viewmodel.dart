import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class ProfileViewModel extends ChangeNotifier {
  UserModel _user = UserModel(
    name: 'Paradeep Tech',
    phone: '6354785693',
    email: 'paradeeptech@gmail.com',
    state: 'Delhi',
    city: 'Bawana',
    houseNo: '3E-1 NITHARI Rohini North West Delhi India 110086',
    address: 'fhhhhj',
    pinCode: '110086',
    walletBalance: 0.00,
  );

  bool _isUpdating = false;
  String? _updateError;
  bool _updateSuccess = false;

  UserModel get user => _user;
  bool get isUpdating => _isUpdating;
  String? get updateError => _updateError;
  bool get updateSuccess => _updateSuccess;

  final List<String> states = ['Delhi', 'Maharashtra', 'Karnataka', 'Tamil Nadu', 'Uttar Pradesh'];
  final List<String> cities = ['Bawana', 'Rohini', 'Dwarka', 'Lajpat Nagar', 'Saket'];

  void updateName(String value) {
    _user = _user.copyWith(name: value);
    notifyListeners();
  }

  void updateEmail(String value) {
    _user = _user.copyWith(email: value);
    notifyListeners();
  }

  void updateState(String value) {
    _user = _user.copyWith(state: value);
    notifyListeners();
  }

  void updateCity(String value) {
    _user = _user.copyWith(city: value);
    notifyListeners();
  }

  void updateHouseNo(String value) {
    _user = _user.copyWith(houseNo: value);
    notifyListeners();
  }

  void updateAddress(String value) {
    _user = _user.copyWith(address: value);
    notifyListeners();
  }

  void updatePinCode(String value) {
    _user = _user.copyWith(pinCode: value);
    notifyListeners();
  }

  Future<void> updateProfile() async {
    _isUpdating = true;
    _updateError = null;
    _updateSuccess = false;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      _updateSuccess = true;
    } catch (e) {
      _updateError = e.toString();
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  void resetUpdateState() {
    _updateSuccess = false;
    _updateError = null;
    notifyListeners();
  }
}
