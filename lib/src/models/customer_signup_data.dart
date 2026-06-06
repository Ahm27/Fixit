class CustomerSignupData {
  const CustomerSignupData({
    required this.fullName,
    required this.email,
    required this.password,
    required this.phone,
    required this.city,
  });

  final String fullName;
  final String email;
  final String password;
  final String phone;
  final String city;
}
