import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Asumsi AdminDrawer dan AdminHomeScreen diimpor dari file lain,
// tapi untuk mempermudah, kita akan menggunakan AdminDrawer dari file admin_home_screen.dart.
// Untuk kode ini berjalan, pastikan file admin_home_screen.dart sudah diimpor ke main.dart.

// --- Model Data Pesanan ---
class OrderItem {
  final String name;
  final DateTime date;
  final String time;
  final String courts;
  final String bookingId;
  final int amount;
  final String status;

  OrderItem({
    required this.name,
    required this.date,
    required this.time,
    required this.courts,
    required this.bookingId,
    required this.amount,
    required this.status,
  });
}

// --- Admin History Screen (Stateful Widget) ---
class AdminHistoryScreen extends StatefulWidget {
  const AdminHistoryScreen({super.key});

  @override
  State<AdminHistoryScreen> createState() => _AdminHistoryScreenState();
}

class _AdminHistoryScreenState extends State<AdminHistoryScreen> {
  // State untuk Filter Periode
  DateTime? _startDate;
  DateTime? _endDate;
  bool _selectAll = false;

  // Mock data pesanan (mereplikasi data dari Next.js)
  final List<OrderItem> _allOrders = [
    OrderItem(
      name: 'Eqi',
      date: DateTime(2025, 11, 9),
      time: '06:00 - 08:00',
      courts: 'Lapangan 1, Lapangan 2',
      bookingId: '#WEB-JLOZqEEZgL',
      amount: 340000,
      status: 'Pending',
    ),
    OrderItem(
      name: 'Ayari Tenri beta',
      date: DateTime(2110, 12, 8),
      time: '06:00 - 08:00',
      courts: 'Lapangan 2',
      bookingId: '#WEB-I3lVk_btql',
      amount: 170000,
      status: 'Pending',
    ),
    // Tambahkan 14 data lainnya untuk mencukupi jumlah (16)
    ...List.generate(
      14,
      (index) => OrderItem(
        name: 'Pesanan #${index + 3}',
        date: DateTime(2025, 10, 20 + index),
        time: '10:00 - 11:00',
        courts: 'Lapangan 1',
        bookingId: '#WEB-${index + 3}',
        amount: 85000,
        status: index.isEven ? 'Confirmed' : 'Cancelled',
      ),
    ),
  ];

  // State untuk menyimpan status checkbox setiap item
  late List<bool> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = List<bool>.filled(_allOrders.length, false);
  }

  // LOGIKA: Fungsi untuk menampilkan Date Picker
  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2110),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // LOGIKA: Fungsi saat Checkbox "Pilih Semua" diklik
  void _toggleSelectAll(bool? value) {
    if (value != null) {
      setState(() {
        _selectAll = value;
        _selectedItems = List<bool>.filled(_allOrders.length, value);
      });
    }
  }

  // LOGIKA: Fungsi saat Checkbox item individual diklik
  void _toggleItemSelection(int index, bool? value) {
    if (value != null) {
      setState(() {
        _selectedItems[index] = value;
        if (!value) {
          _selectAll = false;
        } else if (_selectedItems.every((element) => element)) {
          _selectAll = true;
        }
      });
    }
  }

  // LOGIKA: Fungsi Export
  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mengekspor 16 data pesanan...')),
    );
  }

  // Fungsi untuk format Rupiah sederhana
  String _formatRupiah(int amount) {
    // Menggunakan NumberFormat untuk format Rupiah yang benar
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount).replaceAll(',', '.');
  }

  @override
  Widget build(BuildContext context) {
    final int selectedCount = _selectedItems.where((element) => element).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrasi'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      // MENGHILANGKAN AdminDrawerPlaceholder dan menggantinya dengan Drawer aslinya
      // Asumsi AdminDrawer sudah tersedia via import di file lain atau di sini.
      // Jika AdminDrawer tidak tersedia di sini, Anda harus memasukkannya.
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Riwayat Pesanan',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                // Tombol Export
                ElevatedButton.icon(
                  onPressed: _exportData,
                  icon: const Icon(Icons.download, size: 18),
                  label: Text('Export (${_allOrders.length})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- FILTER PERIODE ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Periode',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                // Input Tanggal Mulai
                _buildDateField(
                  'Dari Tanggal',
                  _startDate,
                  (date) => _selectDate(context, true),
                ),
                const SizedBox(height: 10),
                // Input Tanggal Akhir
                _buildDateField(
                  'Sampai Tanggal',
                  _endDate,
                  (date) => _selectDate(context, false),
                ),
                const SizedBox(height: 15),
                // Tombol Filter
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Menerapkan filter...')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Filter'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // --- PILIH SEMUA & DAFTAR PESANAN ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Checkbox(value: _selectAll, onChanged: _toggleSelectAll),
                Text('Pilih Semua (${_allOrders.length})'),
                if (selectedCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      '($selectedCount dipilih)',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _allOrders.length,
              itemBuilder: (context, index) {
                final order = _allOrders[index];
                final isSelected = _selectedItems[index];

                return OrderHistoryCard(
                  order: order,
                  isSelected: isSelected,
                  onSelect: (value) => _toggleItemSelection(index, value),
                  formatRupiah: _formatRupiah,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget Pembantu untuk Input Tanggal
  Widget _buildDateField(
    String label,
    DateTime? date,
    ValueChanged<DateTime?> onTap,
  ) {
    final dateString = date != null
        ? DateFormat('dd/MM/yyyy').format(date)
        : 'dd/mm/yyyy';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => onTap(date),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateString,
                  style: TextStyle(
                    color: date != null ? Colors.black87 : Colors.grey,
                  ),
                ),
                const Icon(Icons.calendar_month),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// --- Komponen Riwayat Pesanan Card ---
class OrderHistoryCard extends StatelessWidget {
  final OrderItem order;
  final bool isSelected;
  final ValueChanged<bool?> onSelect;
  final String Function(int) formatRupiah;

  const OrderHistoryCard({
    super.key,
    required this.order,
    required this.isSelected,
    required this.onSelect,
    required this.formatRupiah,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(value: isSelected, onChanged: onSelect),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          order.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        // Status Chip
                        StatusChip(status: order.status),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Detail Booking
                    Text(
                      // Format Tanggal menggunakan locale id_ID (yang memicu error Anda)
                      '${DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(order.date)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          order.time,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.person, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Lapangan: ${order.courts}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // ID dan Harga
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          order.bookingId,
                          style: const TextStyle(color: Colors.blue),
                        ),
                        Text(
                          formatRupiah(order.amount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Komponen Pembantu untuk Status Chip (HARUS ADA DI FILE INI)
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
      case 'Pending':
        color = Colors.yellow.shade700;
        break;
      case 'Cancelled':
        color = Colors.red.shade500;
        break;
      default:
        color = Colors.grey.shade500;
    }

    return Chip(
      label: Text(
        status,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    );
  }
}
