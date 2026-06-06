class WorkerSignupData {
  const WorkerSignupData({
    required this.fullName,
    required this.email,
    required this.password,
    required this.phone,
    required this.city,
    required this.serviceCategory,
    required this.yearsExperience,
    required this.nationalId,
    required this.hourlyRate,
    required this.bio,
  });

  final String fullName;
  final String email;
  final String password;
  final String phone;
  final String city;
  final String serviceCategory;
  final int yearsExperience;
  final String nationalId;
  final double hourlyRate;
  final String bio;
}
