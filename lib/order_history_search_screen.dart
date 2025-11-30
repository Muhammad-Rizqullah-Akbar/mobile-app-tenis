import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'services/firestore_service.dart';

// --- Order History Search Screen (FIRESTORE INTEGRATED) ---
class OrderHistorySearchScreen extends StatefulWidget {
  const OrderHistorySearchScreen({super.key});

  @override
  State<OrderHistorySearchScreen> createState() =>
      _OrderHistorySearchScreenState();
}

class _OrderHistorySearchScreenState extends State<OrderHistorySearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter orders berdasarkan search query
  Stream<List<OrderData>> _getFilteredOrders() {
    String query = _searchController.text.toLowerCase().trim();

    return _firestoreService.getOrdersStream().map((snapshot) {
      List<OrderData> orders = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Parse data dari Firestore
        final order = OrderData.fromFirestore(data);

        // Filter berdasarkan nama customer atau booking ID
        if (query.isEmpty ||
            order.customerName.toLowerCase().contains(query) ||
            order.orderId.toLowerCase().contains(query)) {
          orders.add(order);
        }
      }

      // Sort berdasarkan tanggal terbaru
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return orders;
    });
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
              hintText: 'Cari berdasarkan Nama atau Order ID...',
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

        // ORDERS LIST WITH FIRESTORE INTEGRATION
        Expanded(
          child: StreamBuilder<List<OrderData>>(
            stream: _getFilteredOrders(),
            builder: (context, snapshot) {
              // Loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Error state
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Terjadi kesalahan: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                );
              }

              // No data state
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? 'Belum ada riwayat pesanan'
                            : 'Tidak ada hasil yang cocok',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              // Data found
              final orders = snapshot.data!;
              return ListView.builder(
                itemCount: orders.length,
                padding: const EdgeInsets.only(bottom: 16),
                itemBuilder: (context, index) {
                  return OrderHistoryCard(order: orders[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// --- Order Data Model ---
class OrderData {
  final String orderId;
  final String customerName;
  final String customerPhone;
  final int totalPrice;
  final String status;
  final DateTime createdAt;
  final String proofUrl;
  final List<Map<String, dynamic>> bookings;

  OrderData({
    required this.orderId,
    required this.customerName,
    required this.customerPhone,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.proofUrl,
    required this.bookings,
  });

  // Parse data dari Firestore
  factory OrderData.fromFirestore(Map<String, dynamic> data) {
    return OrderData(
      orderId: data['orderId'] ?? 'N/A',
      customerName: data['customerName'] ?? 'Unknown',
      customerPhone: data['customerPhone'] ?? 'N/A',
      totalPrice: data['totalPrice'] ?? 0,
      status: data['status'] ?? 'Unknown',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      proofUrl: data['proofUrl'] ?? '',
      bookings: List<Map<String, dynamic>>.from(data['bookings'] ?? []),
    );
  }

  // Format total price sebagai Rupiah
  String get formattedTotal {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(totalPrice);
  }

  // Format tanggal
  String get formattedDate {
    return DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(createdAt);
  }

  // Get booking details as string
  String get bookingDetails {
    List<String> details = [];
    for (var booking in bookings) {
      String court = booking['court'] ?? 'Unknown';
      List slots = booking['slots'] ?? [];
      String timeInfo = slots.isNotEmpty
          ? (slots.first['time'] ?? 'Unknown time')
          : 'No slots';
      details.add('$court: $timeInfo');
    }
    return details.join(' | ');
  }
}

// --- Card Komponen ---
class OrderHistoryCard extends StatelessWidget {
  final OrderData order;

  const OrderHistoryCard({super.key, required this.order});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.amber.shade100;
      case 'confirmed':
        return Colors.green.shade100;
      case 'completed':
        return Colors.blue.shade100;
      case 'cancelled':
      case 'ditolak':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.amber.shade800;
      case 'confirmed':
        return Colors.green.shade800;
      case 'completed':
        return Colors.blue.shade800;
      case 'cancelled':
      case 'ditolak':
        return Colors.red.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu Verifikasi';
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
      case 'ditolak':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          _showOrderDetails(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Nama + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.orderId,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getStatusLabel(order.status),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: _getStatusTextColor(order.status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Divider
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 12),

              // Info: Tanggal + No HP
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.formattedDate,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Info: Nomor HP
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.customerPhone,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 12),

              // Booking Details + Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lapangan & Waktu',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.bookingDetails,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.formattedTotal,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildDetailSheet(),
    );
  }

  Widget _buildDetailSheet() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Judul
            const Text(
              'Detail Pesanan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),

            // Order ID
            _buildDetailRow('Order ID', order.orderId),
            const SizedBox(height: 12),

            // Nama Customer
            _buildDetailRow('Nama Pelanggan', order.customerName),
            const SizedBox(height: 12),

            // No HP
            _buildDetailRow('No Telepon', order.customerPhone),
            const SizedBox(height: 12),

            // Tanggal
            _buildDetailRow('Tanggal Pesanan', order.formattedDate),
            const SizedBox(height: 12),

            // Status
            _buildDetailRow(
              'Status',
              _getStatusLabel(order.status),
              statusColor: _getStatusColor(order.status),
              statusTextColor: _getStatusTextColor(order.status),
            ),
            const SizedBox(height: 20),

            // Booking Details
            const Text(
              'Detail Lapangan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ..._buildBookingDetails(),
            const SizedBox(height: 20),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Harga',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  order.formattedTotal,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? statusColor,
    Color? statusTextColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
        Expanded(
          flex: 3,
          child: statusColor != null
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: statusTextColor,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
        ),
      ],
    );
  }

  List<Widget> _buildBookingDetails() {
    return order.bookings.asMap().entries.map((entry) {
      int index = entry.key + 1;
      Map<String, dynamic> booking = entry.value;
      String court = booking['court'] ?? 'Unknown';
      List slots = booking['slots'] ?? [];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$index. $court',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          const SizedBox(height: 4),
          ...slots.map((slot) {
            String date = slot['date'] ?? 'Unknown date';
            String time = slot['time'] ?? 'Unknown time';
            return Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Text(
                '• $date - $time',
                style: TextStyle(color: Colors.grey[700], fontSize: 11),
              ),
            );
          }).toList(),
          const SizedBox(height: 12),
        ],
      );
    }).toList();
  }
}
