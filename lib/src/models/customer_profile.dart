class CustomerProfile {
  const CustomerProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.city,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String city;
  final String? avatarUrl;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) {
      return 'CU';
    }
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  CustomerProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? city,
    String? avatarUrl,
  }) {
    return CustomerProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
