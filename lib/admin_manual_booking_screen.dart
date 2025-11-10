import 'package:flutter/material.dart';

// --- Model Data Slot Sederhana (sama seperti di booking_screen) ---
class Slot {
  final String time;
  final bool isAvailable;
  final bool isSelected;

  Slot(this.time, {this.isAvailable = true, this.isSelected = false});

  Slot copyWith({bool? isSelected}) {
    return Slot(
      time,
      isAvailable: isAvailable,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

// --- Admin Manual Booking Screen (Stateful Widget) ---
class AdminManualBookingScreen extends StatefulWidget {
  const AdminManualBookingScreen({super.key});

  @override
  State<AdminManualBookingScreen> createState() => _AdminManualBookingScreenState();
}

class _AdminManualBookingScreenState extends State<AdminManualBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  // State untuk Slot Booking
  DateTime _selectedDate = DateTime.now();
  int _selectedCourt = 1; 
  int _pricePerSession = 75000; // Harga default
  List<Slot> _slots = [
    Slot('06:00 - 07:00'), Slot('07:00 - 08:00'),
    Slot('08:00 - 09:00'), Slot('09:00 - 10:00'),
    Slot('10:00 - 11:00'), Slot('11:00 - 12:00'),
    Slot('12:00 - 13:00'), Slot('13:00 - 14:00'),
    Slot('14:00 - 15:00'), Slot('15:00 - 16:00'),
    Slot('16:00 - 17:00'), Slot('17:00 - 18:00'),
    Slot('18:00 - 19:00'), Slot('19:00 - 20:00'),
    Slot('20:00 - 21:00'), Slot('21:00 - 22:00'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // LOGIKA: Menghitung total jam dan biaya
  int get _selectedHours => _slots.where((s) => s.isSelected).length;
  int get _totalCost => _selectedHours * _pricePerSession;

  // LOGIKA: Toggle Slot
  void _toggleSlot(int index) {
    setState(() {
      _slots[index] = _slots[index].copyWith(
        isSelected: !_slots[index].isSelected,
      );
    });
  }
  
  // LOGIKA: Proses Konfirmasi Booking Manual
  void _confirmManualBooking() {
    if (_formKey.currentState!.validate() && _selectedHours > 0) {
      // Logic API call untuk membuat booking baru
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking Manual untuk ${_nameController.text} (${_selectedHours} jam) berhasil dikonfirmasi!')),
      );
      // Reset form setelah sukses
      setState(() {
        _nameController.clear();
        _phoneController.clear();
        _slots = _slots.map((s) => s.copyWith(isSelected: false)).toList();
      });
    } else if (_selectedHours == 0) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih setidaknya satu slot jam.')),
      );
    }
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
              'Booking Manual',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            
            // --- DETAIL PELANGGAN (Form) ---
            Form(
              key: _formKey,
              child: _buildCustomerDetailSection(),
            ),
            const SizedBox(height: 25),

            // --- JADWAL & SLOT ---
            _buildScheduleSection(),
            const SizedBox(height: 20),

            // --- RINGKASAN PESANAN (Sticky Footer) ---
            _buildSummarySection(),
            const SizedBox(height: 30),
            
            // --- TOMBOL KONFIRMASI ---
            ElevatedButton.icon(
              onPressed: _confirmManualBooking,
              icon: const Icon(Icons.check_circle),
              label: const Text('Konfirmasi Booking Manual', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Bagian Detail Pelanggan
  Widget _buildCustomerDetailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Detail Pelanggan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Divider(thickness: 1, height: 20),
        
        _ManualBookingFormField(
          icon: Icons.person_outline,
          label: 'Nama Pelanggan',
          hint: 'Masukkan nama lengkap',
          controller: _nameController,
          validator: (val) => val == null || val.isEmpty ? 'Nama wajib diisi' : null,
        ),
        const SizedBox(height: 15),
        
        _ManualBookingFormField(
          icon: Icons.phone_android,
          label: 'Nomor Kontak (WA/Telp)',
          hint: '08xxxxxxxxx',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          validator: (val) => val == null || val.isEmpty ? 'Kontak wajib diisi' : null,
        ),
      ],
    );
  }

  // Bagian Jadwal dan Slot
  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Senin, 10 November 2025', style: Theme.of(context).textTheme.titleMedium),
            // Date Picker Icon (Placeholder)
            const Icon(Icons.calendar_month), 
          ],
        ),
        const SizedBox(height: 10),
        
        // Lapangan Tabs
        Row(
          children: [
            _CourtTab(
              label: 'Lapangan 1',
              isSelected: _selectedCourt == 1,
              onTap: () => setState(() => _selectedCourt = 1),
            ),
            const SizedBox(width: 10),
            _CourtTab(
              label: 'Lapangan 2',
              isSelected: _selectedCourt == 2,
              onTap: () => setState(() => _selectedCourt = 2),
            ),
          ],
        ),
        const SizedBox(height: 15),

        // Slot Jam (GridView)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 3.5,
          ),
          itemCount: _slots.length,
          itemBuilder: (context, index) {
            final slot = _slots[index];
            return SlotButton(
              slot: slot,
              onTap: () {
                if (slot.isAvailable) {
                  _toggleSlot(index);
                }
              },
            );
          },
        ),
      ],
    );
  }
  
  // Bagian Ringkasan Pesanan (Footer)
  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Chip(
              label: Text(_selectedHours == 0 ? '0 Jam' : 'Total Jam: $_selectedHours'),
              backgroundColor: Colors.white24,
              labelStyle: const TextStyle(color: Colors.white),
            ),
          ),
          const Text('Ringkasan Pesanan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(color: Colors.white54, height: 20),
          
          Text(
            'Senin, 10 November 2025', 
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            _selectedHours == 0 
                ? 'Pilih slot jam...'
                : 'Pukul: ${ _slots.where((s) => s.isSelected).map((s) => s.time.split(' - ')[0]).join(', ')}',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 10),
          
          // Total Biaya
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Biaya', style: TextStyle(color: Colors.white70)),
              Text(
                'Rp ${_totalCost.toStringAsFixed(0)}.000,-',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Komponen Pembantu (Diambil dari screen lain) ---

class _ManualBookingFormField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final TextInputType keyboardType;

  const _ManualBookingFormField({
    required this.icon,
    required this.label,
    required this.hint,
    required this.controller,
    required this.validator,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade700),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

// Widget untuk Tab Lapangan (Diambil dari booking_screen.dart)
class _CourtTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CourtTab({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// Widget untuk Tombol Slot Jam (Diambil dari booking_screen.dart)
class SlotButton extends StatelessWidget {
  final Slot slot;
  final VoidCallback onTap;

  const SlotButton({super.key, required this.slot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = slot.isSelected
        ? Colors.blue
        : slot.isAvailable
            ? Colors.green.shade100
            : Colors.red.shade100;

    Color foregroundColor = slot.isSelected 
        ? Colors.white 
        : slot.isAvailable
            ? Colors.green.shade900
            : Colors.red.shade900;

    return InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: slot.isAvailable ? Colors.transparent : Colors.red.shade400)
        ),
        child: Text(
          slot.time,
          style: TextStyle(
            color: foregroundColor,
            fontWeight: FontWeight.w500,
            decoration: slot.isAvailable ? null : TextDecoration.lineThrough,
          ),
        ),
      ),
    );
  }
}