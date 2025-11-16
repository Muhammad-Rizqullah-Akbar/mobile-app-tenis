class BookingData {
  final String courtName;
  final DateTime selectedDate;
  final List<String> selectedTimes;
  final int totalCost;

  BookingData({
    required this.courtName,
    required this.selectedDate,
    required this.selectedTimes,
    required this.totalCost,
  });
}
