class UserModel {
  final String name;
  final String phone;
  final String email;
  final String state;
  final String city;
  final String houseNo;
  final String address;
  final String pinCode;
  final double walletBalance;
  final String? profileImageUrl;

  UserModel({
    required this.name,
    required this.phone,
    required this.email,
    required this.state,
    required this.city,
    required this.houseNo,
    required this.address,
    required this.pinCode,
    this.walletBalance = 0.0,
    this.profileImageUrl,
  });

  UserModel copyWith({
    String? name,
    String? phone,
    String? email,
    String? state,
    String? city,
    String? houseNo,
    String? address,
    String? pinCode,
    double? walletBalance,
    String? profileImageUrl,
  }) {
    return UserModel(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      state: state ?? this.state,
      city: city ?? this.city,
      houseNo: houseNo ?? this.houseNo,
      address: address ?? this.address,
      pinCode: pinCode ?? this.pinCode,
      walletBalance: walletBalance ?? this.walletBalance,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
