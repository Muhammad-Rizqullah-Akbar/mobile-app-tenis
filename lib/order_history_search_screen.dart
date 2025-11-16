import 'package:flutter/material.dart';

// --- Model Data Pesanan (Disederhanakan dari Riwayat Pesanan Admin) ---
class OrderHistoryItem {
  final String name;
  final String date;
  final String time;
  final String court;
  final String bookingId;
  final double total;
  final String status;

  OrderHistoryItem({
    required this.name,
    required this.date,
    required this.time,
    required this.court,
    required this.bookingId,
    required this.total,
    required this.status,
  });
}

// --- Order History Search Screen (NO SCAFFOLD) ---
class OrderHistorySearchScreen extends StatefulWidget {
  const OrderHistorySearchScreen({super.key});

  @override
  State<OrderHistorySearchScreen> createState() =>
      _OrderHistorySearchScreenState();
}

class _OrderHistorySearchScreenState extends State<OrderHistorySearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Mock Data Riwayat Pesanan
  final List<OrderHistoryItem> _allOrders = [
    OrderHistoryItem(
      name: 'Eqi',
      date: 'Minggu, 9 November 2025',
      time: '06:00 - 08:00',
      court: 'Lapangan 1, Lapangan 2',
      bookingId: 'WEB-JLOzqEEzgL',
      total: 340000.0,
      status: 'Pending',
    ),
    OrderHistoryItem(
      name: 'Ayari Tenri beta',
      date: 'Senin, 8 Desember 2110',
      time: '06:00 - 08:00',
      court: 'Lapangan 2',
      bookingId: 'WEB-I3IVk_btql',
      total: 170000.0,
      status: 'Confirmed',
    ),
    OrderHistoryItem(
      name: 'Andi Mutiara',
      date: 'Jumat, 14 November 2025',
      time: '18:00 - 20:00',
      court: 'Lapangan 1',
      bookingId: 'WEB-MUTIARA1',
      total: 150000.0,
      status: 'Completed',
    ),
    OrderHistoryItem(
      name: 'Rahmatullah',
      date: 'Selasa, 11 November 2025',
      time: '10:00 - 11:00',
      court: 'Lapangan 2',
      bookingId: 'WEB-RAHMAT2',
      total: 75000.0,
      status: 'Cancelled',
    ),
  ];

  List<OrderHistoryItem> get _filteredOrders {
    String query = _searchController.text.toLowerCase();

    if (query.isEmpty) {
      return _allOrders;
    }

    return _allOrders.where((order) {
      return order.name.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // SEARCH BAR
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Cari Riwayat Pesanan berdasarkan Nama Pelanggan...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () =>
                          setState(() => _searchController.clear()),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 15,
                horizontal: 10,
              ),
            ),
          ),
        ),

        // LIST VIEW
        Expanded(
          child: ListView.builder(
            itemCount: _filteredOrders.length,
            itemBuilder: (context, index) {
              final order = _filteredOrders[index];
              return OrderHistoryCard(order: order);
            },
          ),
        ),
      ],
    );
  }
}

// --- Card Komponen ---
class OrderHistoryCard extends StatelessWidget {
  final OrderHistoryItem order;

  const OrderHistoryCard({super.key, required this.order});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.amber.shade200;
      case 'confirmed':
        return Colors.green.shade200;
      case 'completed':
        return Colors.blue.shade200;
      case 'cancelled':
        return Colors.red.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nama + Status
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order.status,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Tanggal + Waktu
            Row(
              children: [
                const Icon(Icons.calendar_month, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${order.date} | ${order.time}'),
              ],
            ),
            const SizedBox(height: 4),

            // Lapangan
            Row(
              children: [
                const Icon(Icons.sports_tennis, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Lapangan: ${order.court}'),
              ],
            ),
            const SizedBox(height: 8),

            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 8),

            // Booking ID + Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.bookingId,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  'Rp ${order.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 16,
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
