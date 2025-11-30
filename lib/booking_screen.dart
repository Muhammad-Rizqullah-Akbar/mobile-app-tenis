import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_data.dart';
import '../services/firestore_service.dart';
import 'payment_confirmation_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // --- STATE UTAMA ---

  // 1. KERANJANG BELANJA
  final List<SelectedSlot> _selectedDrafts = [];

  // 2. STATE TAMPILAN
  DateTime _focusedDate = DateTime.now();
  int _activeCourtIndex = 1; // 1 = Lapangan 1, 2 = Lapangan 2

  // 3. DATA DATABASE
  List<String> _bookedSlotsOnFocusedDay = [];
  bool _isLoadingSlots = true;
  bool _isLocaleReady = false;

  // Pricing
  int _pricePerHour = 85000;
  int _session1Price = 85000;
  int _discountPercent = 0;

  // --- LOGIC BARU: Operational Hours (DIPERBAIKI) ---
  // Menggunakan Map karena struktur di Firebase kamu adalah Object (Key-Value), bukan List
  Map<String, dynamic> _weeklySchedule = {};

  // List jam yang ditampilkan
  List<String> _availableTimes = [];

  // Controller UI
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

        // 1. Ambil data operasional
        _listenToOperationalHours();

        // 2. Ambil data booking orang lain
        _listenToRealtimeAvailability();

        // 3. Ambil data harga
        _listenToPricing();
      }
    });
  }

  @override
  void dispose() {
    _datePageController.dispose();
    _carouselController.dispose();
    super.dispose();
  }

  // --- LOGIC 1: FETCH SLOT MERAH (BOOKED) ---
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
        // Skip jika status batal/ditolak
        if (data['status'] == 'Cancelled' || data['status'] == 'Ditolak')
          continue;

        List bookings = data['bookings'] is List ? data['bookings'] : [];
        for (var booking in bookings) {
          if (booking['court'] == targetCourtStr) {
            List slots = booking['slots'] is List ? booking['slots'] : [];
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

  // --- LOGIC 2: FETCH HARGA ---
  void _listenToPricing() {
    FirestoreService().getPricingStream().listen((snapshot) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _session1Price = data['session1Price'] ?? 85000;
          _discountPercent = data['discountPercent'] ?? 0;
          _pricePerHour = _session1Price;
        });
      }
    });
  }

  // --- LOGIC 3: FETCH OPERATIONAL HOURS (PERBAIKAN TOTAL) ---
  void _listenToOperationalHours() {
    FirestoreService().getOperationalStream().listen((snapshot) {
      if (snapshot.exists && mounted) {
        // Ambil seluruh data dokumen sebagai Map (Object)
        final data = snapshot.data() as Map<String, dynamic>;

        setState(() {
          _weeklySchedule = data;
        });

        // Debugging di console untuk memastikan data masuk
        print("📦 DATA JADWAL DARI FIREBASE: $_weeklySchedule");

        // Hitung ulang jam buka
        _updateAvailableTimesForFocusedDate();
      }
    });
  }

  // Helper untuk menerjemahkan Hari Indo -> Inggris (Key Database)
  String _mapDayToEnglishKey(String indonesianDay) {
    switch (indonesianDay) {
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

  // --- FUNGSI UPDATE JAM BUKA (LOGIKA BARU) ---
  void _updateAvailableTimesForFocusedDate() {
    // 1. Dapatkan nama hari Indonesia (Contoh: "Minggu")
    String dayNameID = _getDayName(_focusedDate);

    // 2. Ubah jadi Inggris agar cocok dengan Database (Contoh: "Sunday")
    String dbKey = _mapDayToEnglishKey(dayNameID);

    print("🔍 Cek Jadwal: Hari $dayNameID -> Key DB: $dbKey");

    // 3. Ambil data spesifik hari itu dari Map
    var dayData = _weeklySchedule[dbKey];

    bool isOpen = false;
    String openTime = '06:00';
    String closeTime = '23:00';

    // 4. Cek kelengkapan data
    if (dayData != null && dayData is Map) {
      // Cek field 'isOpen' sesuai screenshot database kamu
      isOpen = dayData['isOpen'] == true;

      // Ambil jam jika ada, kalau tidak pakai default
      if (dayData.containsKey('openTime')) openTime = dayData['openTime'];
      if (dayData.containsKey('closeTime')) closeTime = dayData['closeTime'];
    }

    // 5. Update UI
    if (isOpen) {
      print("✅ STATUS: BUKA ($openTime - $closeTime)");
      setState(() {
        _availableTimes = _generateTimeSlots(openTime, closeTime);
      });
    } else {
      print("❌ STATUS: TUTUP (isOpen is false or null)");
      setState(() {
        _availableTimes = [];
      });
    }
  }

  // Helper: Generate list jam "06:00 - 07:00", dst
  List<String> _generateTimeSlots(String openTime, String closeTime) {
    final times = <String>[];
    try {
      final openParts = openTime.split(':');
      final closeParts = closeTime.split(':');

      int openHour = int.parse(openParts[0]);
      int closeHour = int.parse(closeParts[0]);

      for (int hour = openHour; hour < closeHour; hour++) {
        String start = hour.toString().padLeft(2, '0') + ':00';
        String end = (hour + 1).toString().padLeft(2, '0') + ':00';
        times.add('$start - $end');
      }
    } catch (e) {
      print("Error generating times: $e");
      return _getDefaultTimes();
    }
    return times.isEmpty ? _getDefaultTimes() : times;
  }

  List<String> _getDefaultTimes() {
    return List.generate(17, (index) {
      int hour = 6 + index;
      String start = hour.toString().padLeft(2, '0') + ':00';
      String end = (hour + 1).toString().padLeft(2, '0') + ':00';
      return '$start - $end';
    });
  }

  String _getDayName(DateTime date) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return days[date.weekday - 1];
  }

  // --- LOGIC 4: INTERAKSI USER ---

  void _toggleSlot(String time) {
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
          ),
        );
      }
    });
  }

  void _onDatePageChanged(int index) {
    DateTime today = DateTime.now();
    DateTime newDate = today.add(Duration(days: index));

    setState(() {
      _focusedDate = newDate;
    });

    _listenToRealtimeAvailability();
    _updateAvailableTimesForFocusedDate(); // Hitung ulang jam buka
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int get _totalCost {
    int subtotal = _selectedDrafts.length * _pricePerHour;
    int discountAmount = (subtotal * _discountPercent) ~/ 100;
    return subtotal - discountAmount;
  }

  String get _totalCostStr => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(_totalCost);

  void _goToPayment() {
    final bookingData = BookingData(
      slots: _selectedDrafts,
      totalCost: _totalCost,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentConfirmationScreen(bookingData: bookingData),
      ),
    );
  }

  // --- UI BUILD ---
  @override
  Widget build(BuildContext context) {
    if (!_isLocaleReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      bottomSheet: _selectedDrafts.isNotEmpty ? _buildBottomSummary() : null,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildFirebaseCarousel(),
            const SizedBox(height: 16),

            // HEADER TANGGAL
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Jadwal Lapangan",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'EEEE, d MMMM yyyy',
                          'id_ID',
                        ).format(_focusedDate),
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
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        int daysDiff = picked.difference(DateTime.now()).inDays;
                        if (picked.day == DateTime.now().day &&
                            picked.month == DateTime.now().month &&
                            picked.year == DateTime.now().year) {
                          daysDiff = 0;
                        }
                        if (daysDiff >= 0) {
                          _datePageController.jumpToPage(daysDiff);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),

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

  // --- WIDGETS ---

  Widget _buildFirebaseCarousel() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirestoreService().getCarouselStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 160);
        var data = snapshot.data!.data() as Map<String, dynamic>?;
        List images = data?['images'] ?? [];
        if (images.isEmpty) return const SizedBox(height: 160);

        return SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _carouselController,
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    images[index]['url'] ?? '',
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
    bool hasSelection = _selectedDrafts.any(
      (s) => s.courtName == 'Lapangan $id',
    );

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _activeCourtIndex = id;
          });
          _listenToRealtimeAvailability();
        },
        child: Stack(
          children: [
            Container(
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
            if (hasSelection)
              Positioned(
                right: 5,
                top: 5,
                child: CircleAvatar(
                  radius: 4,
                  backgroundColor: isActive ? Colors.white : Colors.orange,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotGrid() {
    if (_availableTimes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_clock, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Fasilitas Tutup',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tidak ada jadwal operasional pada\n${DateFormat('EEEE, d MMMM', 'id_ID').format(_focusedDate)}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
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
          childAspectRatio: 1.8,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          String time = _availableTimes[index];
          bool isBooked = _bookedSlotsOnFocusedDay.contains(time);
          bool isSelected = _selectedDrafts.any(
            (slot) =>
                slot.time == time &&
                slot.courtName == 'Lapangan $_activeCourtIndex' &&
                _isSameDay(slot.date, _focusedDate),
          );

          Color bgColor = Colors.white;
          Color textColor = Colors.black87;
          Color borderColor = Colors.grey.shade300;

          if (isBooked) {
            bgColor = Colors.red.shade50;
            textColor = Colors.red.shade200;
            borderColor = Colors.red.shade100;
          } else if (isSelected) {
            bgColor = Colors.blue;
            textColor = Colors.white;
            borderColor = Colors.blue;
          }

          return InkWell(
            onTap: isBooked ? null : () => _toggleSlot(time),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                time.replaceAll(' - ', '\n'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  decoration: isBooked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedDrafts.length} slot × ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(_pricePerHour)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.indigo.shade700,
                    ),
                  ),
                  if (_discountPercent > 0)
                    Text(
                      '${_discountPercent}% OFF',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Grand Total:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.indigo,
                      ),
                    ),
                    Text(
                      _totalCostStr,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                        fontSize: 20,
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
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Lanjut Bayar",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
