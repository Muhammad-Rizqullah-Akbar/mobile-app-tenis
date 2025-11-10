import 'package:flutter/material.dart';

// --- Model Data Booking Aktif (Mirip dengan OrderItem, tapi fokus pada status aktif) ---
class BookingItem {
  final String id;
  final String name;
  final DateTime date;
  final String timeSlots; // Cth: 06:00-07:00 & 07:00-08:00
  final String court;
  final int amount;
  final String status; // 'Confirmed', 'Rescheduled', 'Cancelled'

  BookingItem({
    required this.id,
    required this.name,
    required this.date,
    required this.timeSlots,
    required this.court,
    required this.amount,
    required this.status,
  });
}

// --- Admin Schedule Management Screen (DefaultTabController) ---
class AdminScheduleManagementScreen extends StatefulWidget {
  const AdminScheduleManagementScreen({super.key});

  @override
  State<AdminScheduleManagementScreen> createState() => _AdminScheduleManagementScreenState();
}

class _AdminScheduleManagementScreenState extends State<AdminScheduleManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Data Mock Booking Aktif
  List<BookingItem> _allBookings = [
    BookingItem(
      id: '#WEB-I3lVk_btql',
      name: 'Ayari Tenri beta',
      date: DateTime(2025, 12, 8),
      timeSlots: '06:00 - 07:00 & 07:00 - 08:00',
      court: 'Lapangan 2',
      amount: 170000,
      status: 'Confirmed',
    ),
    BookingItem(
      id: '#WEB-M4nDy_087z',
      name: 'Muhammad Rizqullah',
      date: DateTime(2025, 11, 15),
      timeSlots: '10:00 - 11:00',
      court: 'Lapangan 1',
      amount: 85000,
      status: 'Rescheduled',
    ),
    BookingItem(
      id: '#WEB-Q2wXy_987a',
      name: 'Fitriani',
      date: DateTime(2025, 11, 10),
      timeSlots: '18:00 - 19:00',
      court: 'Lapangan 2',
      amount: 95000,
      status: 'Confirmed',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Fungsi untuk memfilter daftar berdasarkan tab yang dipilih
  List<BookingItem> _getFilteredBookings(String status) {
    if (status == 'Semua') {
      return _allBookings;
    }
    return _allBookings.where((b) => b.status == status).toList();
  }

  // Fungsi Aksi Reschedule
  void _reschedule(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reschedule Booking'),
        content: Text('Anda yakin ingin menjadwal ulang booking $id?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Booking $id dijadwalkan ulang (Implementasi navigasi ke form reschedule).')),
              );
            },
            child: const Text('Ya, Reschedule'),
          ),
        ],
      ),
    );
  }

  // Fungsi Aksi Delete
  void _deleteBooking(String id) {
    setState(() {
      _allBookings.removeWhere((b) => b.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Booking $id berhasil dihapus.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Definisi isi untuk setiap tab
    final List<String> tabs = ['Semua', 'Confirmed', 'Rescheduled'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrasi'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Kelola Jadwal Lapangan',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          
          // --- TAB BAR FILTER ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorSize: TabBarIndicatorSize.label,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.blue,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black87,
              tabs: tabs.map((name) => Tab(text: name)).toList(),
            ),
          ),
          
          // --- TAB BAR VIEW (Isi Daftar) ---
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: tabs.map((status) {
                final filteredList = _getFilteredBookings(status);
                
                if (filteredList.isEmpty) {
                  return Center(
                    child: Text('Tidak ada jadwal dengan status "$status".'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final booking = filteredList[index];
                    return BookingScheduleCard(
                      booking: booking,
                      onReschedule: () => _reschedule(booking.id),
                      onDelete: () => _deleteBooking(booking.id),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Komponen Kartu Jadwal Booking ---
class BookingScheduleCard extends StatelessWidget {
  final BookingItem booking;
  final VoidCallback onReschedule;
  final VoidCallback onDelete;

  const BookingScheduleCard({
    super.key,
    required this.booking,
    required this.onReschedule,
    required this.onDelete,
  });

  // Fungsi sederhana untuk format Rupiah
  String _formatRupiah(int amount) {
    // Di aplikasi nyata, gunakan package intl
    String s = amount.toString();
    if (s.length > 3) {
      s = s.substring(0, s.length - 3) + '.' + s.substring(s.length - 3);
    }
    return 'Rp $s.000,-';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  booking.id,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                StatusChip(status: booking.status), // Menggunakan chip status yang sudah ada
              ],
            ),
            const Divider(height: 10, thickness: 0.5),
            
            Text(
              booking.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 5),
            
            // Detail Waktu dan Lapangan
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${booking.date.day}/${booking.date.month}/${booking.date.year} | ${booking.timeSlots}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            Text(
              'Lapangan: ${booking.court}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatRupiah(booking.amount),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green.shade700),
                ),
                
                // Tombol Aksi
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.cached, color: Colors.orange), // Ikon Reschedule
                      onPressed: onReschedule,
                      tooltip: 'Jadwal Ulang',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red), // Ikon Delete
                      onPressed: onDelete,
                      tooltip: 'Hapus Booking',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Komponen Pembantu untuk Status Chip (Diambil dari admin_history_screen.dart)
class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Confirmed':
        color = Colors.green.shade500;
        break;
      case 'Rescheduled':
        color = Colors.orange.shade500;
        break;
      case 'Cancelled':
        color = Colors.red.shade500;
        break;
      default:
        color = Colors.grey.shade500;
    }
    
    return Chip(
      label: Text(status, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    );
  }
}