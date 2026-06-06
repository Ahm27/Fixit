class EarningsSummary {
  const EarningsSummary({
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
    required this.availableBalance,
    required this.completedJobs,
    required this.averageTicket,
  });

  final double today;
  final double thisWeek;
  final double thisMonth;
  final double availableBalance;
  final int completedJobs;
  final double averageTicket;
}
