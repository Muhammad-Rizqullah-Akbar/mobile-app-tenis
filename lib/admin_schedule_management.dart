import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'services/firestore_service.dart';

class AdminScheduleManagementScreen extends StatefulWidget {
  const AdminScheduleManagementScreen({super.key});

  @override
  State<AdminScheduleManagementScreen> createState() =>
      _AdminScheduleManagementScreenState();
}

class _AdminScheduleManagementScreenState
    extends State<AdminScheduleManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    // Menambah tab 'Pending' agar admin bisa memantau yang belum bayar
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- LOGIC: Buka Dialog Reschedule ---
  void _showRescheduleDialog(Map<String, dynamic> orderData) {
    // Ambil data booking lama (asumsi 1 order = 1 booking court untuk simplifikasi edit)
    List bookings = orderData['bookings'] ?? [];
    if (bookings.isEmpty) return;

    Map<String, dynamic> firstBooking = bookings[0];
    String courtName = firstBooking['court'] ?? 'Lapangan 1';

    // Ambil slot pertama sebagai default value
    List slots = firstBooking['slots'] ?? [];
    String initialDateStr = slots.isNotEmpty ? slots[0]['date'] : '';
    String initialTimeStr = slots.isNotEmpty ? slots[0]['time'] : '';

    // Controller untuk Form
    DateTime selectedDate = DateTime.now();
    try {
      // Coba parsing tanggal lama (Format: "Senin, 1 Januari 2025")
      // Karena format teks susah diparse balik, kita default ke Now() dulu
      // atau biarkan user pilih baru.
    } catch (_) {}

    final timeController = TextEditingController(text: initialTimeStr);
    String selectedCourt = courtName;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Reschedule Booking'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Atur Jadwal Baru:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  // 1. Pilih Tanggal
                  const Text(
                    "Tanggal Baru",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 60)),
                      );
                      if (picked != null) {
                        setStateDialog(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(top: 5, bottom: 15),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat(
                              'EEEE, d MMMM yyyy',
                              'id_ID',
                            ).format(selectedDate),
                          ),
                          const Icon(Icons.calendar_today, size: 16),
                        ],
                      ),
                    ),
                  ),

                  // 2. Pilih Lapangan
                  const Text(
                    "Lapangan",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedCourt,
                    items: ['Lapangan 1', 'Lapangan 2']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) =>
                        setStateDialog(() => selectedCourt = val!),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 3. Input Jam (Manual String dulu agar fleksibel)
                  const Text(
                    "Jam (Contoh: 08:00 - 10:00)",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  TextField(
                    controller: timeController,
                    decoration: const InputDecoration(
                      hintText: "00:00 - 00:00",
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (timeController.text.isEmpty) return;

                  try {
                    // Format data baru
                    String newDateStr = DateFormat(
                      'EEEE, d MMMM yyyy',
                      'id_ID',
                    ).format(selectedDate);

                    // Struktur baru untuk di-save
                    List<Map<String, dynamic>> newBookingsPayload = [
                      {
                        'court': selectedCourt,
                        'slots': [
                          {'date': newDateStr, 'time': timeController.text},
                        ],
                      },
                    ];

                    // Panggil Service
                    await _firestoreService.rescheduleOrder(
                      orderId: orderData['orderId'],
                      newBookings: newBookingsPayload,
                    );

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Booking berhasil dipindah!'),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text('Simpan Perubahan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _cancelBooking(String docId, String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Booking'),
        content: Text('Anda yakin ingin membatalkan booking $orderId?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestoreService.updateOrderStatus(docId, 'Cancelled');
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Booking dibatalkan')),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> statuses = [
      'Confirmed',
      'Pending',
      'Rescheduled',
      'Cancelled',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Lapangan'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: statuses.map((name) => Tab(text: name)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: statuses.map((status) {
          return StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.getBookingsByStatus(status),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError)
                return Center(child: Text('Error: ${snapshot.error}'));

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 50, color: Colors.grey[300]),
                      const SizedBox(height: 10),
                      Text(
                        'Tidak ada jadwal "$status"',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;

                  return BookingScheduleCard(
                    data: data,
                    onReschedule: () => _showRescheduleDialog(data),
                    onCancel: () => _cancelBooking(doc.id, data['orderId']),
                  );
                },
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

class BookingScheduleCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onReschedule;
  final VoidCallback onCancel;

  const BookingScheduleCard({
    super.key,
    required this.data,
    required this.onReschedule,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final orderId = data['orderId'] ?? 'N/A';
    final name = data['customerName'] ?? 'Unknown';
    final status = data['status'] ?? 'Unknown';

    // Parse Slots
    List slots =
        (data['bookings'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    String slotDetails = "No Slot Data";

    if (slots.isNotEmpty) {
      // Ambil slot pertama dulu untuk display
      var firstBooking = slots[0];
      String court = firstBooking['court'] ?? '-';
      List timeSlots = firstBooking['slots'] ?? [];

      if (timeSlots.isNotEmpty) {
        String date = timeSlots[0]['date'] ?? '-';
        String times = timeSlots.map((s) => s['time']).join(', ');
        slotDetails = "$court\n$date\nJam: $times";
      }
    }

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'confirmed':
        statusColor = Colors.green;
        break;
      case 'rescheduled':
        statusColor = Colors.orange;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      case 'pending':
        statusColor = Colors.amber;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  orderId,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(),

            // Slot Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.access_time_filled,
                  size: 18,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    slotDetails,
                    style: const TextStyle(color: Colors.black87, height: 1.3),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // Action Buttons
            if (status != 'Cancelled')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: onReschedule,
                    icon: const Icon(Icons.edit_calendar, size: 16),
                    label: const Text("Reschedule"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel, size: 16),
                    label: const Text("Batal"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
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
