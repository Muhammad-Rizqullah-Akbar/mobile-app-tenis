import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';

// --- MODEL DATA ---

// 1. Model Jadwal Rutin
class OperationalDay {
  final String day;
  final bool isOpen;
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

  Map<String, dynamic> toFirestoreValue() => {
    'isOpen': isOpen,
    'openTime': openTime,
    'closeTime': closeTime,
  };
}

// 2. Model Pengecualian Tanggal
class DateException {
  String id;
  DateTime date;
  String reason;
  bool isFullDay;
  String openTime;
  String closeTime;

  DateException({
    required this.id,
    required this.date,
    required this.reason,
    required this.isFullDay,
    this.openTime = '06:00',
    this.closeTime = '23:00',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'reason': reason,
      'isFullDay': isFullDay,
      'openTime': openTime,
      'closeTime': closeTime,
    };
  }

  factory DateException.fromMap(Map<String, dynamic> map) {
    return DateException(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      reason: map['reason'] ?? '',
      isFullDay: map['isFullDay'] ?? true,
      openTime: map['openTime'] ?? '06:00',
      closeTime: map['closeTime'] ?? '23:00',
    );
  }
}

// --- SCREEN ---

class AdminOperationalScreen extends StatefulWidget {
  const AdminOperationalScreen({super.key});

  @override
  State<AdminOperationalScreen> createState() => _AdminOperationalScreenState();
}

class _AdminOperationalScreenState extends State<AdminOperationalScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  int _selectedTab = 0; // 0 = Rutin, 1 = Pengecualian

  // Data Rutin
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
      openTime: '06:00',
      closeTime: '23:00',
    ),
    OperationalDay(
      day: 'Minggu',
      isOpen: true,
      openTime: '06:00',
      closeTime: '23:00',
    ),
  ];

  // Data Pengecualian
  List<DateException> _exceptions = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
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

  // --- 1. LOAD DATA ---
  void _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      var snapshot = await _firestoreService.getOperationalStream().first;

      if (snapshot.exists) {
        var rootData = snapshot.data() as Map<String, dynamic>?;

        // A. Load Rutin
        var scheduleData = rootData?['schedule'];
        if (scheduleData != null && scheduleData is Map<String, dynamic>) {
          List<OperationalDay> updatedSchedule = [];
          for (var defaultDay in _schedule) {
            String dbKey = _mapIndoToEnglish(defaultDay.day);
            if (scheduleData.containsKey(dbKey)) {
              var dayData = scheduleData[dbKey];
              bool isOpenVal = true;
              if (dayData['isOpen'] is bool) {
                isOpenVal = dayData['isOpen'];
              } else if (dayData['isOpen'] is String) {
                isOpenVal = dayData['isOpen'].toLowerCase() == 'true';
              }

              updatedSchedule.add(
                defaultDay.copyWith(
                  isOpen: isOpenVal,
                  openTime: dayData['openTime']?.toString() ?? '06:00',
                  closeTime: dayData['closeTime']?.toString() ?? '23:00',
                ),
              );
            } else {
              updatedSchedule.add(defaultDay);
            }
          }
          setState(() => _schedule = updatedSchedule);
        }

        // B. Load Exceptions (Pengecualian)
        var exceptionsData = rootData?['exceptions'];
        if (exceptionsData != null && exceptionsData is List) {
          List<DateException> loadedExceptions = exceptionsData.map((e) {
            return DateException.fromMap(e as Map<String, dynamic>);
          }).toList();

          // Sort by date (terdekat di atas)
          loadedExceptions.sort((a, b) => a.date.compareTo(b.date));
          setState(() => _exceptions = loadedExceptions);
        }
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UTILS ---
  Future<String?> _selectTime(BuildContext context, String initialTime) async {
    try {
      final parts = initialTime.split(':');
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        ),
      );
      if (picked != null) {
        return '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {}
    return null;
  }

  Future<void> _pickDateForException() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _exceptions.add(
          DateException(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            date: picked,
            reason: '',
            isFullDay: true,
          ),
        );
        _exceptions.sort((a, b) => a.date.compareTo(b.date));
      });
    }
  }

  // --- HAPUS DENGAN KONFIRMASI (BARU) ---
  void _removeException(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pengecualian?'),
        content: Text(
          'Tanggal ${DateFormat('d MMMM yyyy', 'id_ID').format(_exceptions[index].date)} akan dihapus dari daftar. Jangan lupa klik tombol SIMPAN setelah ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              setState(() {
                _exceptions.removeAt(index);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Item dihapus. Klik "SIMPAN" untuk permanen.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // --- 2. SAVE FUNCTIONS ---

  // Save Routine (Jadwal Rutin)
  Future<void> _saveRoutine() async {
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic> scheduleMap = {};
      for (var item in _schedule) {
        scheduleMap[_mapIndoToEnglish(item.day)] = item.toFirestoreValue();
      }

      // Update field 'schedule'
      await _firestoreService.updateOperationalHoursField(
        'schedule',
        scheduleMap,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Jadwal Rutin Tersimpan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Gagal: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Save Exceptions (Pengecualian)
  Future<void> _saveExceptions() async {
    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> exceptionsList = _exceptions
          .map((e) => e.toMap())
          .toList();

      // Update field 'exceptions'
      await _firestoreService.updateOperationalHoursField(
        'exceptions',
        exceptionsList,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Pengecualian Tersimpan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Gagal: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atur Jam Operasional'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // TAB HEADER
                Container(
                  color: Colors.white,
                  child: Row(
                    children: [
                      _buildTabButton(0, 'Jadwal Rutin', Icons.calendar_today),
                      _buildTabButton(
                        1,
                        'Pengecualian',
                        Icons.warning_amber_rounded,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // CONTENT
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _selectedTab == 0
                        ? _buildRoutineTab()
                        : _buildExceptionTab(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    bool isActive = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isActive ? Colors.blue.shade50 : Colors.white,
            border: isActive
                ? const Border(bottom: BorderSide(color: Colors.blue, width: 3))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: isActive ? Colors.blue : Colors.grey),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.blue : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB CONTENT: ROUTINE ---
  Widget _buildRoutineTab() {
    return Column(
      children: [
        ..._schedule.asMap().entries.map((entry) {
          int index = entry.key;
          OperationalDay day = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Switch(
                    value: day.isOpen,
                    onChanged: (val) => setState(
                      () => _schedule[index] = day.copyWith(isOpen: val),
                    ),
                    activeColor: Colors.green,
                    activeTrackColor: Colors.green.shade200,
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      day.day,
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
                                  final t = await _selectTime(
                                    context,
                                    day.openTime,
                                  );
                                  if (t != null)
                                    setState(
                                      () => _schedule[index] = day.copyWith(
                                        openTime: t,
                                      ),
                                    );
                                },
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text("-"),
                              ),
                              _TimeBox(
                                time: day.closeTime,
                                onTap: () async {
                                  final t = await _selectTime(
                                    context,
                                    day.closeTime,
                                  );
                                  if (t != null)
                                    setState(
                                      () => _schedule[index] = day.copyWith(
                                        closeTime: t,
                                      ),
                                    );
                                },
                              ),
                            ],
                          )
                        : const Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              "TUTUP",
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _saveRoutine,
          icon: const Icon(Icons.save),
          label: const Text('SIMPAN JADWAL RUTIN'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
          ),
        ),
      ],
    );
  }

  // --- TAB CONTENT: EXCEPTIONS (DIPERBAIKI) ---
  Widget _buildExceptionTab() {
    return Column(
      children: [
        InkWell(
          onTap: _pickDateForException,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border.all(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.add_circle, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  "Tambah Tanggal Khusus / Libur",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        if (_exceptions.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              "Belum ada pengecualian tanggal.",
              style: TextStyle(color: Colors.grey),
            ),
          ),

        // MENGGUNAKAN KEY UNTUK FIX MASALAH HAPUS
        ..._exceptions.asMap().entries.map((entry) {
          int index = entry.key;
          DateException ex = entry.value;
          return Card(
            key: ValueKey(ex.id), // KEY PENTING!
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.red.shade100),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_month,
                            size: 18,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat(
                              'EEEE, d MMMM yyyy',
                              'id_ID',
                            ).format(ex.date),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      // TOMBOL HAPUS DENGAN FUNGSI BARU
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          size: 20,
                          color: Colors.red,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Hapus',
                        onPressed: () =>
                            _removeException(index), // PANGGIL FUNGSI INI
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: TextEditingController(text: ex.reason),
                        // PENTING: Update state saat mengetik agar tidak reset saat re-render
                        onChanged: (val) {
                          _exceptions[index].reason = val;
                        },
                        decoration: const InputDecoration(
                          labelText: "Alasan (Cth: Idul Fitri, Renovasi)",
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Tutup Seharian?"),
                          Switch(
                            value: ex.isFullDay,
                            onChanged: (val) {
                              setState(() {
                                _exceptions[index].isFullDay = val;
                              });
                            },
                            activeColor: Colors.red,
                            activeTrackColor: Colors.red.shade200,
                          ),
                        ],
                      ),
                      if (!ex.isFullDay)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Jam Buka:"),
                            _TimeBox(
                              time: ex.openTime,
                              onTap: () async {
                                final t = await _selectTime(
                                  context,
                                  ex.openTime,
                                );
                                if (t != null) {
                                  setState(() {
                                    _exceptions[index].openTime = t;
                                  });
                                }
                              },
                            ),
                            const Text("-"),
                            _TimeBox(
                              time: ex.closeTime,
                              onTap: () async {
                                final t = await _selectTime(
                                  context,
                                  ex.closeTime,
                                );
                                if (t != null) {
                                  setState(() {
                                    _exceptions[index].closeTime = t;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(), // Tambahkan toList()

        if (_exceptions.isNotEmpty)
          ElevatedButton.icon(
            onPressed: _saveExceptions,
            icon: const Icon(Icons.save),
            label: const Text('SIMPAN PENGECUALIAN'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
            ),
          ),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(time, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
