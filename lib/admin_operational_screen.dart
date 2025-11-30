import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

// --- Model Data Jam Operasional ---
class OperationalDay {
  final String day; // Nama Hari Indonesia (untuk UI)
  final bool isOpen; // Sesuai database: isOpen
  final String openTime;
  final String closeTime;

  OperationalDay({
    required this.day,
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
  });

  OperationalDay copyWith({bool? isOpen, String? openTime, String? closeTime}) {
    return OperationalDay(
      day: day,
      isOpen: isOpen ?? this.isOpen,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }

  // Format JSON untuk disimpan
  Map<String, dynamic> toFirestoreValue() => {
    'isOpen': isOpen,
    'openTime': openTime,
    'closeTime': closeTime,
  };
}

class AdminOperationalScreen extends StatefulWidget {
  const AdminOperationalScreen({super.key});

  @override
  State<AdminOperationalScreen> createState() => _AdminOperationalScreenState();
}

class _AdminOperationalScreenState extends State<AdminOperationalScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  // Template Default
  List<OperationalDay> _schedule = [
    OperationalDay(
      day: 'Senin',
      isOpen: true,
      openTime: '06:00',
      closeTime: '23:00',
    ),
    OperationalDay(
      day: 'Selasa',
      isOpen: true,
      openTime: '06:00',
      closeTime: '23:00',
    ),
    OperationalDay(
      day: 'Rabu',
      isOpen: true,
      openTime: '06:00',
      closeTime: '23:00',
    ),
    OperationalDay(
      day: 'Kamis',
      isOpen: true,
      openTime: '06:00',
      closeTime: '23:00',
    ),
    OperationalDay(
      day: 'Jumat',
      isOpen: true,
      openTime: '06:00',
      closeTime: '23:00',
    ),
    OperationalDay(
      day: 'Sabtu',
      isOpen: true,
      openTime: '07:00',
      closeTime: '22:00',
    ),
    OperationalDay(
      day: 'Minggu',
      isOpen: true,
      openTime: '06:00',
      closeTime: '23:00',
    ),
  ];

  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentSchedule();
  }

  String _mapIndoToEnglish(String dayName) {
    switch (dayName) {
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

  // --- 1. LOAD DATA (PERBAIKAN UTAMA DI SINI) ---
  void _loadCurrentSchedule() async {
    try {
      var snapshot = await _firestoreService.getOperationalStream().first;
      if (snapshot.exists) {
        var rootData = snapshot.data() as Map<String, dynamic>;

        // PERBAIKAN: Masuk ke dalam field 'schedule' dulu!
        var scheduleData = rootData['schedule'];

        // Cek apakah 'schedule' ada dan bentuknya Map
        if (scheduleData != null && scheduleData is Map<String, dynamic>) {
          List<OperationalDay> updatedSchedule = [];

          for (var defaultDay in _schedule) {
            String dbKey = _mapIndoToEnglish(defaultDay.day);

            if (scheduleData.containsKey(dbKey)) {
              var dayData = scheduleData[dbKey];
              updatedSchedule.add(
                defaultDay.copyWith(
                  isOpen: dayData['isOpen'] ?? true,
                  openTime: dayData['openTime'] ?? '06:00',
                  closeTime: dayData['closeTime'] ?? '23:00',
                ),
              );
            } else {
              updatedSchedule.add(defaultDay);
            }
          }

          if (mounted) {
            setState(() {
              _schedule = updatedSchedule;
            });
          }
        }
      }
    } catch (e) {
      print("Gagal load jadwal: $e");
    }
  }

  Future<String?> _selectTime(BuildContext context, String initialTime) async {
    final parts = initialTime.split(':');
    TimeOfDay initial = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      return '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
    return null;
  }

  // --- 2. SAVE DATA (PERBAIKAN UTAMA DI SINI) ---
  Future<void> _saveSchedule() async {
    setState(() => _isLoading = true);
    try {
      // Buat map jadwal dulu (Monday: {...}, Sunday: {...})
      Map<String, dynamic> scheduleMap = {};

      for (var item in _schedule) {
        String dbKey = _mapIndoToEnglish(item.day);
        scheduleMap[dbKey] = item.toFirestoreValue();
      }

      // PERBAIKAN: Bungkus map tersebut ke dalam key 'schedule'
      // agar sesuai dengan struktur database: { "schedule": { ... } }
      Map<String, dynamic> finalPayload = {'schedule': scheduleMap};

      // Kirim payload lengkap
      await _firestoreService.updateOperationalHours(finalPayload);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Jadwal Operasional Berhasil Disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atur Jam Operasional'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Tab Pilihan
                  Row(
                    children: [
                      _AdminTab(
                        icon: Icons.calendar_today,
                        label: 'Jadwal Rutin',
                        isSelected: _selectedTab == 0,
                        onTap: () => setState(() => _selectedTab = 0),
                      ),
                      const SizedBox(width: 10),
                      _AdminTab(
                        icon: Icons.warning_amber,
                        label: 'Libur/Khusus',
                        isSelected: _selectedTab == 1,
                        onTap: () => setState(() => _selectedTab = 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (_selectedTab == 0)
                    _buildJadwalRutin()
                  else
                    const Center(
                      child: Text("Fitur Pengecualian Tanggal (Coming Soon)"),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildJadwalRutin() {
    return Column(
      children: [
        ..._schedule.asMap().entries.map((entry) {
          int index = entry.key;
          OperationalDay day = entry.value;
          return OperationalDayCard(
            day: day,
            onToggle: (val) =>
                setState(() => _schedule[index] = day.copyWith(isOpen: val)),
            onTimeChange: (open, close) => setState(
              () => _schedule[index] = day.copyWith(
                openTime: open,
                closeTime: close,
              ),
            ),
            selectTime: _selectTime,
          );
        }),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _saveSchedule,
          icon: const Icon(Icons.save),
          label: const Text('SIMPAN PERUBAHAN'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}

// --- Komponen UI Pendukung ---
class _AdminTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _AdminTab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : Colors.white,
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.blue : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.blue : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OperationalDayCard extends StatelessWidget {
  final OperationalDay day;
  final ValueChanged<bool> onToggle;
  final Function(String, String) onTimeChange;
  final Function selectTime;

  const OperationalDayCard({
    super.key,
    required this.day,
    required this.onToggle,
    required this.onTimeChange,
    required this.selectTime,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: day.isOpen ? Colors.green : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Row(
                children: [
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: day.isOpen,
                      onChanged: onToggle,
                      activeColor: Colors.green,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      day.day,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: day.isOpen
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _TimeBox(
                          time: day.openTime,
                          onTap: () async {
                            final t = await selectTime(context, day.openTime);
                            if (t != null) onTimeChange(t, day.closeTime);
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text("-"),
                        ),
                        _TimeBox(
                          time: day.closeTime,
                          onTap: () async {
                            final t = await selectTime(context, day.closeTime);
                            if (t != null) onTimeChange(day.openTime, t);
                          },
                        ),
                      ],
                    )
                  : const Text(
                      "TUTUP",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  final String time;
  final VoidCallback onTap;
  const _TimeBox({required this.time, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(time, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
