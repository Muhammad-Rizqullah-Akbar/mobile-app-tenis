// lib/models/booking_data.dart

class BookingData {
  final List<SelectedSlot> slots;
  final int totalCost;

  BookingData({required this.slots, required this.totalCost});
}

// Model untuk 1 kotak hijau yang dipilih user
class SelectedSlot {
  final String courtName; // "Lapangan 1"
  final DateTime date; // Tanggalnya
  final String time; // "06:00 - 07:00"
  final int price; // [BARU] Harga spesifik slot ini

  SelectedSlot({
    required this.courtName,
    required this.date,
    required this.time,
    required this.price, // Wajib diisi saat dipilih
  });

  // Helper untuk membandingkan slot (agar bisa di-unselect)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectedSlot &&
          runtimeType == other.runtimeType &&
          courtName == other.courtName &&
          date.year == other.date.year &&
          date.month == other.date.month &&
          date.day == other.date.day &&
          time == other.time;

  @override
  int get hashCode => Object.hash(courtName, date.day, time);
}
