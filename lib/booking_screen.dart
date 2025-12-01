import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_data.dart';
import '../services/firestore_service.dart';
import 'payment_confirmation_screen.dart';

// --- MODEL DATE EXCEPTION (Internal Helper) ---
class DateException {
  DateTime date;
  bool isFullDay;
  String openTime;
  String closeTime;

  DateException({
    required this.date,
    required this.isFullDay,
    this.openTime = '06:00',
    this.closeTime = '23:00',
  });

  factory DateException.fromMap(Map<String, dynamic> map) {
    return DateException(
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      isFullDay: map['isFullDay'] ?? true,
      openTime: map['openTime'] ?? '06:00',
      closeTime: map['closeTime'] ?? '23:00',
    );
  }
}

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // --- STATE UTAMA ---
  final List<SelectedSlot> _selectedDrafts = []; // Keranjang sementara

  DateTime _focusedDate = DateTime.now();
  int _activeCourtIndex = 1; // 1 = Lapangan 1, 2 = Lapangan 2

  // --- DATA DARI DATABASE ---
  List<String> _bookedSlotsOnFocusedDay = []; // Slot merah
  bool _isLoadingSlots = true;
  bool _isLocaleReady = false;

  // PRICING
  int _session1Price = 75000;
  int _session2Price = 95000;
  int _discountPercent = 0;

  // OPERATIONAL (RUTIN & EXCEPTION)
  Map<String, dynamic> _weeklySchedule = {};
  List<DateException> _exceptions = []; // [BARU] List Pengecualian
  List<String> _availableTimes = [];

  // CONTROLLER
  late PageController _datePageController;
  final PageController _carouselController = PageController(
    viewportFraction: 0.92,
  );

  @override
  void initState() {
    super.initState();
    _datePageController = PageController(initialPage: 0);

    initializeDateFormatting('id_ID', null).then((_) {
      if (mounted) {
        setState(() => _isLocaleReady = true);
        _listenToPricing();
        _listenToOperationalHours();
        _listenToRealtimeAvailability();
      }
    });
  }

  @override
  void dispose() {
    _datePageController.dispose();
    _carouselController.dispose();
    super.dispose();
  }

  // --- 1. LOGIC HARGA ---
  void _listenToPricing() {
    FirestoreService().getPricingStream().listen((snapshot) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _session1Price = data['session1Price'] ?? 75000;
          _session2Price = data['session2Price'] ?? 95000;
          _discountPercent = data['discountPercent'] ?? 0;
        });
      }
    });
  }

  int _getPriceForTime(String timeSlot) {
    try {
      int startHour = int.parse(timeSlot.split(':')[0]);
      if (startHour < 18) {
        return _session1Price;
      } else {
        return _session2Price;
      }
    } catch (e) {
      return _session2Price;
    }
  }

  // --- 2. LOGIC JAM OPERASIONAL (DIPERBAIKI: Support Exceptions) ---
  void _listenToOperationalHours() {
    print("🔥 DEBUG: Memulai listener Operational Hours...");
    FirestoreService().getOperationalStream().listen((snapshot) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data() as Map<String, dynamic>;

        // 1. Ambil Jadwal Rutin
        final scheduleData = data['schedule'];

        // 2. Ambil Pengecualian (Exceptions)
        final exceptionsData = data['exceptions'];

        setState(() {
          // Parse Schedule
          if (scheduleData is Map<String, dynamic>) {
            _weeklySchedule = scheduleData;
          } else {
            _weeklySchedule = {};
          }

          // Parse Exceptions
          if (exceptionsData is List) {
            _exceptions = exceptionsData
                .map((e) => DateException.fromMap(e as Map<String, dynamic>))
                .toList();
            print("✅ Loaded ${_exceptions.length} exceptions");
          } else {
            _exceptions = [];
          }
        });

        // Update UI setelah data masuk
        _updateAvailableTimesForFocusedDate();
      }
    });
  }

  String _mapDayToEnglishKey(String indonesianDay) {
    String day = indonesianDay.trim();
    switch (day) {
      case 'Senin':
        return 'Monday';
      case 'Selasa':
        return 'Tuesday';
      case 'Rabu':
        return 'Wednesday';
      case 'Kamis':
        return 'Thursday';
      case 'Jumat':
        return 'Friday';
      case 'Sabtu':
        return 'Saturday';
      case 'Minggu':
        return 'Sunday';
      default:
        return 'Monday';
    }
  }

  // LOGIKA INTI: Penentuan Buka/Tutup (Cek Exception Dulu!)
  void _updateAvailableTimesForFocusedDate() {
    bool isOpen = true;
    String openTime = '06:00';
    String closeTime = '23:00';
    bool isExceptionFound = false;

    // A. CEK APAKAH TANGGAL INI ADA DI LIST EXCEPTION?
    String focusedDateStr = DateFormat('yyyy-MM-dd').format(_focusedDate);

    try {
      final exception = _exceptions.firstWhere(
        (ex) => DateFormat('yyyy-MM-dd').format(ex.date) == focusedDateStr,
      );

      // Jika ketemu exception:
      isExceptionFound = true;
      print("🚨 EXCEPTION FOUND untuk tanggal $focusedDateStr!");

      if (exception.isFullDay) {
        isOpen = false; // Tutup seharian
        print("   -> Status: TUTUP SEHARIAN");
      } else {
        isOpen = true; // Buka jam khusus
        openTime = exception.openTime;
        closeTime = exception.closeTime;
        print("   -> Status: JAM KHUSUS ($openTime - $closeTime)");
      }
    } catch (e) {
      // Tidak ketemu exception, lanjut ke jadwal rutin
      isExceptionFound = false;
    }

    // B. JIKA TIDAK ADA EXCEPTION, PAKAI JADWAL RUTIN
    if (!isExceptionFound) {
      String dayNameID = DateFormat('EEEE', 'id_ID').format(_focusedDate);
      String dbKey = _mapDayToEnglishKey(dayNameID);

      var dayData = _weeklySchedule[dbKey];

      if (dayData != null && dayData is Map) {
        var rawIsOpen = dayData['isOpen'];
        if (rawIsOpen is bool)
          isOpen = rawIsOpen;
        else if (rawIsOpen is String)
          isOpen = rawIsOpen.toLowerCase() == 'true';

        openTime = dayData['openTime']?.toString() ?? '06:00';
        closeTime = dayData['closeTime']?.toString() ?? '23:00';
      }
    }

    // 4. Update UI
    setState(() {
      if (!isOpen) {
        _availableTimes = []; // Toko Tutup
      } else {
        _availableTimes = _generateTimeSlots(openTime, closeTime);
      }
    });
  }

  List<String> _generateTimeSlots(String open, String close) {
    List<String> times = [];
    try {
      int start = int.parse(open.split(':')[0]);
      int end = int.parse(close.split(':')[0]);

      for (int i = start; i < end; i++) {
        String s = i.toString().padLeft(2, '0') + ":00";
        String e = (i + 1).toString().padLeft(2, '0') + ":00";
        times.add("$s - $e");
      }
    } catch (e) {
      print("❌ Error generate jam: $e");
      return ["06:00 - 07:00", "07:00 - 08:00"]; // Fallback
    }
    return times;
  }

  // --- 3. LOGIC KETERSEDIAAN ---
  void _listenToRealtimeAvailability() {
    if (!_isLocaleReady) return;
    setState(() => _isLoadingSlots = true);

    FirestoreService().getOrdersStream().listen((snapshot) {
      List<String> takenSlots = [];
      String targetDateStr = DateFormat(
        'EEEE, d MMMM yyyy',
        'id_ID',
      ).format(_focusedDate);
      String targetCourtStr = 'Lapangan $_activeCourtIndex';

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data['status'] == 'Cancelled' || data['status'] == 'Ditolak')
          continue;

        List bookings = data['bookings'] ?? [];
        for (var booking in bookings) {
          if (booking['court'] == targetCourtStr) {
            List slots = booking['slots'] ?? [];
            for (var s in slots) {
              if (s['date'] == targetDateStr) {
                takenSlots.add(s['time']);
              }
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _bookedSlotsOnFocusedDay = takenSlots;
          _isLoadingSlots = false;
        });
      }
    });
  }

  // --- INTERAKSI USER ---
  void _toggleSlot(String time) {
    int slotPrice = _getPriceForTime(time);
    int index = _selectedDrafts.indexWhere(
      (slot) =>
          slot.time == time &&
          slot.courtName == 'Lapangan $_activeCourtIndex' &&
          _isSameDay(slot.date, _focusedDate),
    );

    setState(() {
      if (index >= 0) {
        _selectedDrafts.removeAt(index);
      } else {
        _selectedDrafts.add(
          SelectedSlot(
            courtName: 'Lapangan $_activeCourtIndex',
            date: _focusedDate,
            time: time,
            price: slotPrice,
          ),
        );
      }
    });
  }

  void _onDatePageChanged(int index) {
    DateTime today = DateTime.now();
    DateTime newDate = today.add(Duration(days: index));
    setState(() => _focusedDate = newDate);

    _listenToRealtimeAvailability();
    _updateAvailableTimesForFocusedDate();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int get _subTotal {
    int total = 0;
    for (var slot in _selectedDrafts) {
      total += slot.price;
    }
    return total;
  }

  int get _grandTotal {
    int discountAmount = (_subTotal * _discountPercent) ~/ 100;
    return _subTotal - discountAmount;
  }

  void _goToPayment() {
    final bookingData = BookingData(
      slots: _selectedDrafts,
      totalCost: _grandTotal,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentConfirmationScreen(bookingData: bookingData),
      ),
    );
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    if (!_isLocaleReady)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      bottomSheet: _selectedDrafts.isNotEmpty ? _buildBottomSummary() : null,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildFirebaseCarousel(),
            const SizedBox(height: 10),
            _buildDateHeader(),
            const SizedBox(height: 10),
            _buildCourtSelector(),
            const SizedBox(height: 10),
            Expanded(
              child: PageView.builder(
                controller: _datePageController,
                onPageChanged: _onDatePageChanged,
                itemBuilder: (context, index) {
                  return _isLoadingSlots
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 160),
                          child: _buildSlotGrid(),
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Jadwal Lapangan",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_focusedDate),
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.blue),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _focusedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (picked != null) {
                int daysDiff = picked.difference(DateTime.now()).inDays;
                if (daysDiff < 0) daysDiff = 0;
                _datePageController.jumpToPage(daysDiff);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFirebaseCarousel() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirestoreService().getCarouselStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 150);
        var data = snapshot.data!.data() as Map<String, dynamic>?;
        List images = data?['images'] ?? [];
        if (images.isEmpty) return const SizedBox(height: 150);

        return SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _carouselController,
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    images[index]['url'],
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) =>
                        Container(color: Colors.grey.shade300),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCourtSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildCourtTab('Lapangan 1', 1),
          const SizedBox(width: 12),
          _buildCourtTab('Lapangan 2', 2),
        ],
      ),
    );
  }

  Widget _buildCourtTab(String label, int id) {
    bool isActive = _activeCourtIndex == id;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _activeCourtIndex = id);
          _listenToRealtimeAvailability();
        },
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? Colors.blue : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlotGrid() {
    // TAMPILAN JIKA TUTUP
    if (_availableTimes.isEmpty) {
      // Cek apakah tutup karena Exception?
      String reason = "Tidak ada jadwal operasional.";
      try {
        final ex = _exceptions.firstWhere(
          (e) =>
              DateFormat('yyyy-MM-dd').format(e.date) ==
              DateFormat('yyyy-MM-dd').format(_focusedDate),
        );
        // Jika karena pengecualian, tampilkan alasannya? (Opsional)
        // reason = "Tutup: " + ex.reason;
      } catch (_) {}

      return Center(
        child: Column(
          children: [
            const SizedBox(height: 50),
            Icon(Icons.block, size: 50, color: Colors.red.shade200),
            const SizedBox(height: 10),
            const Text(
              "Lapangan Tutup",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(reason, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _availableTimes.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1.6,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          String time = _availableTimes[index];
          bool isBooked = _bookedSlotsOnFocusedDay.contains(time);
          bool isSelected = _selectedDrafts.any(
            (s) =>
                s.time == time &&
                s.courtName == 'Lapangan $_activeCourtIndex' &&
                _isSameDay(s.date, _focusedDate),
          );

          Color bgColor = Colors.white;
          Color textColor = Colors.black87;

          if (isBooked) {
            bgColor = Colors.red.shade50;
            textColor = Colors.red.shade200;
          } else if (isSelected) {
            bgColor = Colors.blue;
            textColor = Colors.white;
          }

          int price = _getPriceForTime(time);
          String priceLabel = NumberFormat.compactCurrency(
            locale: 'id_ID',
            symbol: '',
          ).format(price);

          return InkWell(
            onTap: isBooked ? null : () => _toggleSlot(time),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey.shade300,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    time.split(' - ')[0],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: textColor,
                    ),
                  ),
                  if (!isBooked)
                    Text(
                      priceLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.white70 : Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomSummary() {
    String totalStr = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(_grandTotal);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${_selectedDrafts.length} Slot Terpilih",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  totalStr,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _goToPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
              ),
              child: const Text("LANJUT BAYAR"),
            ),
          ],
        ),
      ),
    );
  }
}
