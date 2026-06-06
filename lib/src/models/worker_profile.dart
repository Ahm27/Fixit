class WorkerProfile {
  const WorkerProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.city,
    required this.serviceCategory,
    required this.yearsExperience,
    required this.nationalId,
    required this.hourlyRate,
    required this.bio,
    required this.isAvailable,
    this.rating = 4.7,
    this.completedJobs = 0,
    this.isVerified = true,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String city;
  final String serviceCategory;
  final int yearsExperience;
  final String nationalId;
  final double hourlyRate;
  final String bio;
  final bool isAvailable;
  final double rating;
  final int completedJobs;
  final bool isVerified;
  final String? avatarUrl;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) {
      return 'WK';
    }
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  WorkerProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? city,
    String? serviceCategory,
    int? yearsExperience,
    String? nationalId,
    double? hourlyRate,
    String? bio,
    bool? isAvailable,
    double? rating,
    int? completedJobs,
    bool? isVerified,
    String? avatarUrl,
  }) {
    return WorkerProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      nationalId: nationalId ?? this.nationalId,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      bio: bio ?? this.bio,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
      completedJobs: completedJobs ?? this.completedJobs,
      isVerified: isVerified ?? this.isVerified,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
