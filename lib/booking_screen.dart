import 'package:flutter/material.dart';
import 'models/booking_data.dart';
import 'payment_confirmation_screen.dart';

/// ----------------- MODEL SLOT -----------------
class Slot {
  final String time;
  final bool isAvailable;
  final bool isSelected;

  Slot(this.time, {this.isAvailable = true, this.isSelected = false});

  Slot copyWith({bool? isSelected}) {
    return Slot(
      time,
      isAvailable: isAvailable,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

/// ----------------- BOOKING SCREEN -----------------
class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now();
  int _selectedCourt = 1;

  final List<Slot> _slots = [
    Slot('06:00 - 07:00'),
    Slot('07:00 - 08:00'),
    Slot('08:00 - 09:00'),
    Slot('09:00 - 10:00'),
    Slot('10:00 - 11:00'),
    Slot('11:00 - 12:00'),
    Slot('12:00 - 13:00'),
    Slot('13:00 - 14:00'),
    Slot('14:00 - 15:00'),
    Slot('15:00 - 16:00'),
    Slot('16:00 - 17:00'),
    Slot('17:00 - 18:00'),
    Slot('18:00 - 19:00'),
    Slot('19:00 - 20:00'),
    Slot('20:00 - 21:00'),
    Slot('21:00 - 22:00'),
    Slot('22:00 - 23:00'),
  ];

  final int _pricePerHour = 85000;

  int get _selectedHours => _slots.where((s) => s.isSelected).length;

  String get _totalCost => _formatRupiah(_selectedHours * _pricePerHour);

  /// ----------------- CAROUSEL -----------------
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _activePage = 0;

  final List<String> _carouselImages = [
    'https://picsum.photos/800/400?image=1050',
    'https://picsum.photos/800/400?image=1043',
    'https://picsum.photos/800/400?image=1027',
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      final page = (_pageController.page ?? 0).round();
      if (page != _activePage) {
        setState(() => _activePage = page);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// ----------------- HELPERS -----------------
  void _toggleSlot(int index) {
    if (!_slots[index].isAvailable) return;
    setState(() {
      _slots[index] = _slots[index].copyWith(
        isSelected: !_slots[index].isSelected,
      );
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatRupiah(int value) {
    final s = value.toString();
    final buffer = StringBuffer();
    int count = 0;

    for (int i = s.length - 1; i >= 0; i--) {
      buffer.write(s[i]);
      count++;
      if (count == 3 && i != 0) {
        buffer.write('.');
        count = 0;
      }
    }

    final reversed = buffer.toString().split('').reversed.join();
    return 'Rp $reversed,-';
  }

  void _goToPayment() {
    final selectedTimes = _slots
        .where((s) => s.isSelected)
        .map((s) => s.time)
        .toList();

    if (selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 jam untuk melanjutkan.')),
      );
      return;
    }

    final bookingData = BookingData(
      courtName: 'Lapangan $_selectedCourt',
      selectedDate: _selectedDate,
      selectedTimes: selectedTimes,
      totalCost: _selectedHours * _pricePerHour,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentConfirmationScreen(bookingData: bookingData),
      ),
    );
  }

  /// ----------------- UI -----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Hapus AppBar → biar bersih
      appBar: null,

      // BottomSheet tetap
      bottomSheet: _selectedHours > 0
          ? RingkasanPesanan(
              totalHours: _selectedHours,
              totalCost: _totalCost,
              courtName: 'Lapangan $_selectedCourt',
              onPay: _goToPayment,
            )
          : null,

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCarousel(), // ← Pindah ke scroll, tidak sticky
            const SizedBox(height: 20),
            _buildHeader(),
            const SizedBox(height: 15),
            _buildCourtTabs(),
            const SizedBox(height: 20),
            _buildSlotGrid(),
            const SizedBox(height: 150), // ruang untuk bottomSheet
          ],
        ),
      ),
    );
  }

  /// ----------------- SUB-WIDGETS -----------------
  Widget _buildCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _carouselImages.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _carouselImages[index],
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_carouselImages.length, (i) {
            final active = i == _activePage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? Colors.blue : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Jadwal yang Tersedia',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                ),
                const SizedBox(width: 6),
                const Icon(Icons.calendar_month, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourtTabs() {
    return Row(
      children: [
        _CourtTab(
          label: 'Lapangan 1',
          isSelected: _selectedCourt == 1,
          onTap: () => setState(() => _selectedCourt = 1),
        ),
        const SizedBox(width: 10),
        _CourtTab(
          label: 'Lapangan 2',
          isSelected: _selectedCourt == 2,
          onTap: () => setState(() => _selectedCourt = 2),
        ),
      ],
    );
  }

  Widget _buildSlotGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _slots.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 3.5,
      ),
      itemBuilder: (context, index) {
        return SlotButton(slot: _slots[index], onTap: () => _toggleSlot(index));
      },
    );
  }
}

/// ----------------- SUB COMPONENTS -----------------
class _CourtTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CourtTab({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class SlotButton extends StatelessWidget {
  final Slot slot;
  final VoidCallback onTap;

  const SlotButton({super.key, required this.slot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = slot.isSelected
        ? Colors.blue
        : slot.isAvailable
        ? Colors.green.shade100
        : Colors.red.shade100;

    final textColor = slot.isSelected ? Colors.white : Colors.green.shade900;

    return InkWell(
      onTap: slot.isAvailable ? onTap : null,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: slot.isAvailable ? Colors.transparent : Colors.red.shade400,
          ),
        ),
        child: Text(
          slot.time,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w500,
            decoration: slot.isAvailable ? null : TextDecoration.lineThrough,
          ),
        ),
      ),
    );
  }
}

class RingkasanPesanan extends StatelessWidget {
  final int totalHours;
  final String totalCost;
  final String courtName;
  final VoidCallback onPay;

  const RingkasanPesanan({
    super.key,
    required this.totalHours,
    required this.totalCost,
    required this.courtName,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 5),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'Total Jam: $totalHours',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    'Ringkasan Pesanan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Divider(color: Colors.white54),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        courtName,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        totalCost,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: onPay,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Bayar Sekarang',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
