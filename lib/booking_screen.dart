import 'package:flutter/material.dart';

// Definisi Model Data Sederhana (mereplikasi data dari Next.js)
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

// --- Booking Screen (Stateful Widget) ---
class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now();
  int _selectedCourt = 1; // 1 = Lapangan 1, 2 = Lapangan 2
  
  // Contoh data slot (harus diambil dari API di proyek nyata)
  List<Slot> _slots = [
    Slot('06:00 - 07:00'), Slot('07:00 - 08:00'),
    Slot('08:00 - 09:00'), Slot('09:00 - 10:00'),
    Slot('10:00 - 11:00'), Slot('11:00 - 12:00'),
    Slot('12:00 - 13:00'), Slot('13:00 - 14:00'),
    Slot('14:00 - 15:00'), Slot('15:00 - 16:00'),
    Slot('16:00 - 17:00'), Slot('17:00 - 18:00'),
    Slot('18:00 - 19:00'), Slot('19:00 - 20:00'),
    Slot('20:00 - 21:00'), Slot('21:00 - 22:00'),
    Slot('22:00 - 23:00'),
    // Tambahkan Slot('07:00 - 08:00', isAvailable: false) untuk simulasi
  ];

  // LOGIKA: Fungsi untuk menghitung total jam dan biaya
  int get _selectedHours => _slots.where((s) => s.isSelected).length;
  String get _totalCost {
    // Harga per jam sederhana: Rp 85.000
    int total = _selectedHours * 85000;
    // Format ke Rupiah, ini membutuhkan package intl di pubspec.yaml
    return 'Rp ${total.toStringAsFixed(0)}.000,-'; 
  }

  // LOGIKA: Fungsi saat Slot diklik
  void _toggleSlot(int index) {
    setState(() {
      _slots[index] = _slots[index].copyWith(
        isSelected: !_slots[index].isSelected,
      );
    });
  }

  // LOGIKA: Date Picker untuk memilih tanggal
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Di sini Anda harus memuat ulang _slots berdasarkan tanggal yang baru
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tennis Court.')),
      body: Column(
        children: [
          // Bagian Carousel (dibuat terpisah di file lain nanti)
          const ImagePlaceholder(height: 180), // Placeholder untuk Carousel
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- JADWAL YANG TERSEDIA & DATE PICKER ---
                  Row(
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
                              Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                              const Icon(Icons.calendar_month, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // --- LAPANGAN TABS ---
                  Row(
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
                  ),
                  const SizedBox(height: 20),
                  
                  // --- SLOT JAM (GridView) ---
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 3.5,
                    ),
                    itemCount: _slots.length,
                    itemBuilder: (context, index) {
                      final slot = _slots[index];
                      return SlotButton(
                        slot: slot,
                        onTap: () {
                          if (slot.isAvailable) {
                            _toggleSlot(index);
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 100), // Ruang bawah
                ],
              ),
            ),
          ),
          
          // --- RINGKASAN PESANAN (Sticky Footer) ---
          if (_selectedHours > 0)
            RingkasanPesanan(
              totalHours: _selectedHours,
              totalCost: _totalCost,
              courtName: 'Lapangan $_selectedCourt',
              onPay: () {
                // Navigasi ke Halaman Pembayaran
                // Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentScreen()));
              },
            ),
        ],
      ),
    );
  }
}

// --- Komponen Pembantu ---

class ImagePlaceholder extends StatelessWidget {
  final double height;
  const ImagePlaceholder({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Text('Carousel Gambar Lapangan', style: TextStyle(color: Colors.grey)),
    );
  }
}

class _CourtTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CourtTab({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade200,
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
    Color backgroundColor = slot.isSelected
        ? Colors.blue
        : slot.isAvailable
            ? Colors.green.shade100
            : Colors.red.shade100;

    Color foregroundColor = slot.isSelected 
        ? Colors.white 
        : Colors.green.shade900;

    return InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: slot.isAvailable ? Colors.transparent : Colors.red.shade400)
        ),
        child: Text(
          slot.time,
          style: TextStyle(
            color: foregroundColor,
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
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text('Total Jam: $totalHours', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
                const Text('Ringkasan Pesanan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(color: Colors.white54),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(courtName, style: const TextStyle(color: Colors.white70)),
                    Text(totalCost, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Bayar Sekarang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// --- Placeholder Bottom NavBar (untuk melengkapi tampilan) ---
class MyBottomNavBar extends StatelessWidget {
  const MyBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      currentIndex: 0,
      selectedItemColor: Colors.blue,
      onTap: (index) {
        // Implementasi navigasi di sini
      },
    );
  }
}