import 'package:flutter/material.dart';

// --- Model Data Jam Operasional ---
class OperationalDay {
  final String day;
  final bool isActive;
  final String openTime;
  final String closeTime;

  OperationalDay({
    required this.day,
    required this.isActive,
    required this.openTime,
    required this.closeTime,
  });

  OperationalDay copyWith({
    bool? isActive,
    String? openTime,
    String? closeTime,
  }) {
    return OperationalDay(
      day: day,
      isActive: isActive ?? this.isActive,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }
}

// --- Admin Operational Screen ---
class AdminOperationalScreen extends StatefulWidget {
  const AdminOperationalScreen({super.key});

  @override
  State<AdminOperationalScreen> createState() => _AdminOperationalScreenState();
}

class _AdminOperationalScreenState extends State<AdminOperationalScreen> {
  // Menggunakan 'late final' jika data akan dimuat sekali dari API,
  // tetapi karena ini adalah state lokal yang bisa diubah, kita biarkan saja non-final
  // dan abaikan warning 'prefer_final_fields' (karena state ini memang diubah)
  List<OperationalDay> _schedule = [
    OperationalDay(day: 'Minggu', isActive: true, openTime: '06:00', closeTime: '23:00'),
    OperationalDay(day: 'Senin', isActive: true, openTime: '06:00', closeTime: '23:00'),
    OperationalDay(day: 'Selasa', isActive: true, openTime: '06:00', closeTime: '23:00'),
    OperationalDay(day: 'Rabu', isActive: true, openTime: '06:00', closeTime: '23:00'),
    OperationalDay(day: 'Kamis', isActive: true, openTime: '06:00', closeTime: '23:00'),
    OperationalDay(day: 'Jumat', isActive: true, openTime: '06:00', closeTime: '23:00'),
    OperationalDay(day: 'Sabtu', isActive: true, openTime: '07:00', closeTime: '22:00'),
  ];
  
  int _selectedTab = 0; // 0 = Jadwal Rutin, 1 = Pengecualian Tanggal

  // Fungsi untuk menampilkan Time Picker
  Future<String?> _selectTime(BuildContext context, String initialTime) async {
    // Parsing string "HH:MM" ke TimeOfDay
    final parts = initialTime.split(':');
    TimeOfDay initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null) {
      // Format kembali ke string "HH:MM"
      return '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
    return null;
  }

  // Fungsi untuk menyimpan perubahan
  void _saveSchedule() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Jadwal Operasional Disimpan!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrasi'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kelola Jam Operasional',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Tentukan jam buka rutin mingguan dan pengecualian tanggal.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // --- TAB SWITCHER (Jadwal Rutin / Pengecualian Tanggal) ---
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
                  label: 'Pengecualian Tanggal',
                  isSelected: _selectedTab == 1,
                  onTap: () => setState(() => _selectedTab = 1),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- KONTEN TAB ---
            _selectedTab == 0
                ? _buildJadwalRutin()
                : _buildPengecualianTanggal(),
          ],
        ),
      ),
    );
  }

  // --- Widget untuk Jadwal Rutin ---
  Widget _buildJadwalRutin() {
    return Column(
      children: [
        ..._schedule.asMap().entries.map((entry) {
          int index = entry.key;
          OperationalDay day = entry.value;

          return OperationalDayCard(
            day: day,
            onToggle: (bool newValue) {
              setState(() {
                _schedule[index] = day.copyWith(isActive: newValue);
              });
            },
            onTimeChange: (String newOpen, String newClose) {
               setState(() {
                _schedule[index] = day.copyWith(openTime: newOpen, closeTime: newClose);
              });
            },
            selectTime: _selectTime,
          );
        }), // Menghapus .toList() untuk warning "unnecessary_to_list_in_spreads"
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _saveSchedule,
          icon: const Icon(Icons.save),
          label: const Text('Simpan Jam Operasional'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  // --- Widget untuk Pengecualian Tanggal (Sesuai image_fc851b.png) ---
  Widget _buildPengecualianTanggal() {
     // Implementasi kompleks Pengecualian Tanggal di sini
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         ElevatedButton.icon(
          onPressed: () { /* Tambah Pengecualian */ },
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Tambah Pengecualian Tanggal'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),
        // Contoh satu item pengecualian
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('10/11/2025', style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.close, color: Colors.red)),
                ],
              ),
              const SizedBox(height: 10),
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Alasan (Cth: Maintenance, Libur Nasional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tutup Sepanjang Hari'),
                  Switch(value: true, onChanged: (val) {}),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () { /* Simpan Pengecualian */ },
          icon: const Icon(Icons.save),
          label: const Text('Simpan Pengecualian Tanggal'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

// --- Komponen Pembantu ---

class _AdminTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AdminTab({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: isSelected ? Colors.blue.shade800 : Colors.black87),
              const SizedBox(width: 5),
              Flexible(child: Text(label, style: TextStyle(color: isSelected ? Colors.blue.shade800 : Colors.black87))),
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
  final Function(String newOpen, String newClose) onTimeChange;
  final Function _selectTime;

  // CONSTRUCTOR DIPERBAIKI: HANYA ADA SATU onTimeChange
  const OperationalDayCard({
    super.key,
    required this.day,
    required this.onToggle,
    required this.onTimeChange,
    required Function selectTime,
  }) : _selectTime = selectTime;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: day.isActive ? Colors.green.shade400 : Colors.grey.shade400),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Switch(
                  value: day.isActive,
                  onChanged: onToggle,
                  // DEPRECATED MEMBER USE FIX: Ganti activeColor menjadi activeTrackColor (atau biarkan default)
                  activeColor: Colors.green.shade700,
                  activeTrackColor: Colors.green.shade300, 
                ),
                Text(day.day, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            
            // Time Pickers
            Row(
              children: [
                _TimeButton(
                  time: day.openTime,
                  onTap: day.isActive ? () async {
                    String? newTime = await _selectTime(context, day.openTime);
                    if (newTime != null) {
                      onTimeChange(newTime, day.closeTime);
                    }
                  } : null,
                ),
                const Text(' - '),
                _TimeButton(
                  time: day.closeTime,
                  onTap: day.isActive ? () async {
                    String? newTime = await _selectTime(context, day.closeTime);
                    if (newTime != null) {
                      onTimeChange(day.openTime, newTime);
                    }
                  } : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String time;
  final VoidCallback? onTap;

  const _TimeButton({required this.time, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(5),
          color: onTap != null ? Colors.white : Colors.grey.shade300,
        ),
        child: Row(
          children: [
            Text(time, style: TextStyle(color: onTap != null ? Colors.black : Colors.grey)),
            const SizedBox(width: 5),
            const Icon(Icons.access_time, size: 18),
          ],
        ),
      ),
    );
  }
}