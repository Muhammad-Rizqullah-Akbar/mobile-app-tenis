// lib/models/booking_data.dart

class BookingData {
  // Kita tidak lagi pakai single date/court, tapi list of SelectedSlot
  final List<SelectedSlot> slots;
  final int totalCost;

  BookingData({required this.slots, required this.totalCost});
}

// Model kecil untuk menyimpan 1 kotak hijau yang dipilih user
class SelectedSlot {
  final String courtName; // "Lapangan 1" atau "Lapangan 2"
  final DateTime date; // Tanggal spesifik slot ini
  final String time; // "06:00 - 07:00"

  SelectedSlot({
    required this.courtName,
    required this.date,
    required this.time,
  });

  // Helper untuk membandingkan apakah 2 slot itu sama (untuk remove/add)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectedSlot &&
          runtimeType == other.runtimeType &&
          courtName == other.courtName &&
          // Bandingkan tanggal sampai hari saja (abaikan jam/menit datetime)
          date.year == other.date.year &&
          date.month == other.date.month &&
          date.day == other.date.day &&
          time == other.time;

  @override
  int get hashCode => Object.hash(courtName, date.day, time);
}
