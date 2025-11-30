import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:html' as html;
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
              try {
                await _firestoreService.bulkUpdateOrderStatus(
                  _selectedOrderIds.toList(),
                  newStatus,
                );
                if (mounted) {
                  Navigator.pop(context);
                  setState(() => _selectedOrderIds.clear());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Status berhasil diperbarui!'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
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
              try {
                await _firestoreService.deleteOrder(docId);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Pesanan berhasil dihapus!'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
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

  Future<void> _exportToCSV(List<DocumentSnapshot> orders) async {
    try {
      // CSV Headers
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
      final rows = <List<String>>[];

      // CSV Data
      for (int i = 0; i < orders.length; i++) {
        final data = orders[i].data() as Map<String, dynamic>;
        final createdAt = data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now();

        rows.add([
          (i + 1).toString(),
          data['orderId'] ?? 'N/A',
          data['customerName'] ?? 'N/A',
          data['customerPhone'] ?? 'N/A',
          data['status'] ?? 'N/A',
          DateFormat('dd/MM/yyyy HH:mm').format(createdAt),
          (data['totalPrice'] ?? 0).toString(),
          data['source'] ?? 'mobile_app',
        ]);
      }

      // Build CSV String
      final csv = StringBuffer();
      csv.writeln(headers.join(','));
      for (final row in rows) {
        csv.writeln(row.map((cell) => '\"$cell\"').join(','));
      }

      final csvContent = csv.toString();
      final bytes = utf8.encode(csvContent);
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Create and click download link
      (html.AnchorElement(href: url)..setAttribute(
            'download',
            'export_pesanan_${DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now())}.csv',
          ))
          .click();

      // Cleanup
      html.Url.revokeObjectUrl(url);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Export CSV berhasil! ${orders.length} pesanan diunduh',
            ),
            duration: const Duration(seconds: 2),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // EXPORT BUTTON
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: StreamBuilder<QuerySnapshot>(
              stream: _filterStatus == 'Semua'
                  ? _firestoreService.getOrdersStream()
                  : _firestoreService.getBookingsByStatus(_filterStatus),
              builder: (context, snapshot) {
                final canExport =
                    snapshot.hasData &&
                    (snapshot.data?.docs.isNotEmpty ?? false);
                return ElevatedButton.icon(
                  onPressed: canExport
                      ? () => _exportToCSV(snapshot.data!.docs)
                      : null,
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
                DropdownButton<String>(
                  value: _filterStatus,
                  isExpanded: true,
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
                      child: ElevatedButton.icon(
                        onPressed: () => _selectDate(context, true),
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _startDate == null
                              ? 'Dari'
                              : DateFormat('dd/MM/yyyy').format(_startDate!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _selectDate(context, false),
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _endDate == null
                              ? 'Sampai'
                              : DateFormat('dd/MM/yyyy').format(_endDate!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Reset'),
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
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        const Text('Tidak ada pesanan'),
                      ],
                    ),
                  );
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

  const AdminOrderCard({
    required this.docId,
    required this.data,
    required this.isSelected,
    required this.onSelect,
    required this.onDelete,
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
          CheckboxListTile(
            value: isSelected,
            onChanged: (value) => onSelect(value ?? false),
            title: Column(
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
                const SizedBox(height: 4),
                Text(
                  orderId,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(DateFormat('dd/MM/yyyy HH:mm').format(createdAt)),
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
          // Delete Button
          Positioned(
            right: 8,
            top: 8,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => onDelete(docId, orderId),
              tooltip: 'Hapus pesanan',
            ),
          ),
        ],
      ),
    );
  }
}
