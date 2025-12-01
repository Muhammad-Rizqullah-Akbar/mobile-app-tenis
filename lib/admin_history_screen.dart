import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'services/firestore_service.dart';

class AdminHistoryScreen extends StatefulWidget {
  const AdminHistoryScreen({super.key});

  @override
  State<AdminHistoryScreen> createState() => _AdminHistoryScreenState();
}

class _AdminHistoryScreenState extends State<AdminHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  DateTime? _startDate;
  DateTime? _endDate;
  Set<String> _selectedOrderIds = {};
  String _filterStatus = 'Semua';

  // --- Date Picker Logic ---
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

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedOrderIds.clear();
      _filterStatus = 'Semua';
    });
  }

  // --- Bulk Update Logic ---
  void _bulkUpdateStatus(String newStatus) async {
    if (_selectedOrderIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu pesanan!')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text(
          'Update status ke "$newStatus" untuk ${_selectedOrderIds.length} pesanan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog dulu

              try {
                await _firestoreService.bulkUpdateOrderStatus(
                  _selectedOrderIds.toList(),
                  newStatus,
                );

                if (mounted) {
                  setState(() => _selectedOrderIds.clear());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Status berhasil diperbarui!'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // --- Delete Logic ---
  Future<void> _deleteOrder(String docId, String orderId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pesanan'),
        content: Text(
          'Yakin ingin menghapus pesanan $orderId?\n\nTindakan ini tidak dapat dibatalkan!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog

              try {
                await _firestoreService.deleteOrder(docId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Pesanan berhasil dihapus!'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- CSV Export Logic (Disimpan untuk nanti) ---
  Future<void> _exportToCSV(List<DocumentSnapshot> orders) async {
    try {
      final headers = [
        'No',
        'Order ID',
        'Nama Customer',
        'No. Telepon',
        'Status',
        'Tanggal',
        'Total (Rp)',
        'Sumber',
      ];
      final csvBuffer = StringBuffer();
      csvBuffer.writeln(headers.join(','));

      for (int i = 0; i < orders.length; i++) {
        final data = orders[i].data() as Map<String, dynamic>;
        final createdAt = data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now();

        List<String> row = [
          (i + 1).toString(),
          data['orderId'] ?? 'N/A',
          '"${data['customerName'] ?? 'N/A'}"',
          '"${data['customerPhone'] ?? 'N/A'}"',
          data['status'] ?? 'N/A',
          DateFormat('dd/MM/yyyy HH:mm').format(createdAt),
          (data['totalPrice'] ?? 0).toString(),
          data['source'] ?? 'mobile_app',
        ];
        csvBuffer.writeln(row.join(','));
      }

      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/laporan_pesanan_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
      final file = File(path);
      await file.writeAsString(csvBuffer.toString());

      await Share.shareXFiles([XFile(path)], text: 'Export Data Pesanan CSV');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Menu bagikan CSV terbuka!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error export: $e')));
      }
    }
  }

  // --- SHOW DETAIL ORDER + BUKTI BAYAR ---
  void _showOrderDetail(BuildContext context, Map<String, dynamic> data) {
    String proofUrl = data['proofUrl'] ?? '';
    List bookings = data['bookings'] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
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

              const Text(
                "Detail Pesanan",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              _buildDetailRow("Nama", data['customerName'] ?? '-'),
              _buildDetailRow("No. HP", data['customerPhone'] ?? '-'),
              _buildDetailRow(
                "Total",
                "Rp ${NumberFormat('#,###').format(data['totalPrice'] ?? 0)}",
              ),

              const Divider(height: 30),

              const Text(
                "Jadwal Booking:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...bookings.map(
                (b) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b['court'] ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (b['slots'] != null)
                        ...(b['slots'] as List)
                            .map((s) => Text("${s['date']} (${s['time']})"))
                            .toList(),
                    ],
                  ),
                ),
              ),

              const Divider(height: 30),

              const Text(
                "Bukti Pembayaran:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              if (proofUrl.isNotEmpty && proofUrl.startsWith('http'))
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        child: InteractiveViewer(
                          child: Image.network(proofUrl),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        proofUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, loading) {
                          if (loading == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                        errorBuilder: (ctx, error, stackTrace) => const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 40,
                                color: Colors.grey,
                              ),
                              Text(
                                "Gagal memuat gambar",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Text(
                    "Tidak ada bukti pembayaran.\n(Mungkin booking manual/tunai)",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.orange),
                  ),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // TOMBOL EXPORT DISEMBUNYIKAN SEMENTARA
          /*
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: StreamBuilder<QuerySnapshot>(
              stream: _filterStatus == 'Semua'
                  ? _firestoreService.getOrdersStream()
                  : _firestoreService.getBookingsByStatus(_filterStatus),
              builder: (context, snapshot) {
                final canExport = snapshot.hasData && (snapshot.data?.docs.isNotEmpty ?? false);
                return ElevatedButton.icon(
                  onPressed: canExport ? () => _exportToCSV(snapshot.data!.docs) : null,
                  icon: const Icon(Icons.download),
                  label: const Text('📥 Export ke CSV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                );
              },
            ),
          ),
          */
          const SizedBox(height: 10), // Ganti dengan spacer kecil
          // FILTER SECTION
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Pesanan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),

                // Status Filter
                DropdownButtonFormField<String>(
                  value: _filterStatus,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items:
                      [
                            'Semua',
                            'Pending',
                            'Confirmed',
                            'Completed',
                            'Cancelled',
                          ]
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                  onChanged: (value) =>
                      setState(() => _filterStatus = value ?? 'Semua'),
                ),

                const SizedBox(height: 12),

                // Date Range
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectDate(context, true),
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _startDate == null
                              ? 'Dari Tgl'
                              : DateFormat('dd/MM/yy').format(_startDate!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectDate(context, false),
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _endDate == null
                              ? 'Sampai Tgl'
                              : DateFormat('dd/MM/yy').format(_endDate!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.refresh),
                      tooltip: "Reset Filter",
                    ),
                  ],
                ),
              ],
            ),
          ),

          // BULK ACTION BUTTONS
          if (_selectedOrderIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _bulkUpdateStatus('Confirmed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text(
                        '✓ Konfirmasi',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _bulkUpdateStatus('Cancelled'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text(
                        '✕ Batalkan',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // ORDERS LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _filterStatus == 'Semua'
                  ? _firestoreService.getOrdersStream()
                  : _firestoreService.getBookingsByStatus(_filterStatus),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError)
                  return Center(child: Text('Error: ${snapshot.error}'));

                final docs = snapshot.data?.docs ?? [];

                // Filter by Date (Client Side)
                final filteredDocs = _startDate != null && _endDate != null
                    ? docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final createdAt = data['createdAt'] is Timestamp
                            ? (data['createdAt'] as Timestamp).toDate()
                            : DateTime.now();
                        return createdAt.isAfter(_startDate!) &&
                            createdAt.isBefore(
                              _endDate!.add(const Duration(days: 1)),
                            );
                      }).toList()
                    : docs;

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('Tidak ada pesanan'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final orderId = data['orderId'] as String;
                    final isSelected = _selectedOrderIds.contains(orderId);

                    return AdminOrderCard(
                      docId: doc.id,
                      data: data,
                      isSelected: isSelected,
                      onSelect: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedOrderIds.add(orderId);
                          } else {
                            _selectedOrderIds.remove(orderId);
                          }
                        });
                      },
                      onDelete: (docId, orderId) =>
                          _deleteOrder(docId, orderId),
                      onTap: () => _showOrderDetail(context, data),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AdminOrderCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final bool isSelected;
  final Function(bool) onSelect;
  final Function(String, String) onDelete;
  final VoidCallback onTap;

  const AdminOrderCard({
    super.key,
    required this.docId,
    required this.data,
    required this.isSelected,
    required this.onSelect,
    required this.onDelete,
    required this.onTap,
  });

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return '🟡';
      case 'confirmed':
        return '🟢';
      case 'completed':
        return '🔵';
      case 'cancelled':
        return '🔴';
      default:
        return '⚪';
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderId = data['orderId'] ?? 'N/A';
    final name = data['customerName'] ?? 'Unknown';
    final status = data['status'] ?? 'Unknown';
    final total = data['totalPrice'] ?? 0;
    final createdAt = data['createdAt'] is Timestamp
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.now();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        children: [
          // 1. AREA KLIK UTAMA (DETAIL)
          InkWell(
            onTap: onTap, // Membuka Detail Pesanan
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              // Padding kanan besar agar teks tidak tertimpa tombol hapus/checkbox
              padding: const EdgeInsets.fromLTRB(16, 16, 50, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(_getStatusColor(status)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    orderId,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${NumberFormat('#,###').format(total)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. TOMBOL HAPUS
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              tooltip: 'Hapus',
              onPressed: () => onDelete(docId, orderId),
            ),
          ),

          // 3. CHECKBOX
          Positioned(
            bottom: 8,
            right: 0,
            child: Checkbox(
              value: isSelected,
              onChanged: (val) => onSelect(val ?? false),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
