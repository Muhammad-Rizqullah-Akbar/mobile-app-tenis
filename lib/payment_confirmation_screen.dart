import 'package:flutter/material.dart';
import '../models/booking_data.dart'; // pastikan path ini benar

class PaymentConfirmationScreen extends StatefulWidget {
  final BookingData bookingData;

  const PaymentConfirmationScreen({super.key, required this.bookingData});

  @override
  State<PaymentConfirmationScreen> createState() =>
      _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _uploadedFileName;

  // Data booking
  late String _lapangan;
  late String _date;
  late String _time;
  late int _totalJam;
  late String _totalPembayaran;

  final String _bankName = 'Bank Mandiri';
  final String _accountNumber = '1520016356871';

  @override
  void initState() {
    super.initState();

    _lapangan = widget.bookingData.courtName;
    _totalJam = widget.bookingData.selectedTimes.length;
    _time = widget.bookingData.selectedTimes.join(' | ');

    _date =
        '${widget.bookingData.selectedDate.day}/${widget.bookingData.selectedDate.month}/${widget.bookingData.selectedDate.year}';

    // totalCost = 85 → tampil: Rp 85.000,-
    _totalPembayaran = 'Rp ${widget.bookingData.totalCost}.000,-';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _pickFile() {
    setState(() {
      _uploadedFileName =
          'bukti_transfer_${DateTime.now().millisecondsSinceEpoch}.jpg';
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('File dipilih: $_uploadedFileName')));
  }

  void _submitPayment() {
    if (!_formKey.currentState!.validate()) return;

    if (_uploadedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon unggah bukti pembayaran.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Konfirmasi Pembayaran',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          children: [
            _buildOrderSummary(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      icon: Icons.credit_card,
                      title: 'Detail & Pembayaran',
                    ),
                    const SizedBox(height: 15),

                    _buildTextFormField(
                      icon: Icons.person_outline,
                      label: 'Nama Lengkap',
                      hint: 'Nama lengkap untuk notifikasi',
                      controller: _nameController,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Nama wajib diisi.' : null,
                    ),
                    const SizedBox(height: 15),

                    _buildTextFormField(
                      icon: Icons.phone_android,
                      label: 'Nomor Telepon (WA)',
                      hint: 'Nomor WA aktif',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Nomor telepon wajib diisi.'
                          : null,
                    ),
                    const SizedBox(height: 30),

                    const SectionHeader(
                      icon: Icons.receipt_long,
                      title: 'Transfer & Bukti',
                    ),
                    const SizedBox(height: 15),

                    _buildBankTransferInfo(),
                    const SizedBox(height: 20),

                    _buildFileUploadSection(),
                    const SizedBox(height: 30),

                    ElevatedButton.icon(
                      onPressed: _submitPayment,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Selesaikan Pembayaran'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MyBottomNavBar(),
    );
  }

  // --- WIDGET ---
  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.deepPurple,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Chip(
              label: Text(
                'TOTAL JAM: $_totalJam',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              backgroundColor: Colors.white24,
              labelStyle: const TextStyle(color: Colors.white),
            ),
          ),
          const Text(
            'RINGKASAN PESANAN',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const Divider(color: Colors.white54, height: 20),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade700,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Chip(
                  label: Text(_lapangan),
                  backgroundColor: Colors.yellow.shade100,
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Text(_date, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 5),

                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Text(_time, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL\nPEMBAYARAN',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                _totalPembayaran,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required IconData icon,
    required String label,
    required String hint,
    required TextEditingController controller,
    required FormFieldValidator<String> validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade700),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: const InputDecoration(
            hintText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildBankTransferInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance, color: Colors.blue, size: 20),
                const SizedBox(width: 5),
                Text(
                  'Transfer Bank - $_bankName',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Text(
              'Transfer $_totalPembayaran ke:',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 5),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(
                _accountNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue,
                ),
              ),
            ),

            const SizedBox(height: 5),
            const Text(
              'a.n. BKK PLN AREA MAKASSAR SELATAN',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.upload_file, size: 18, color: Colors.grey),
            const SizedBox(width: 5),
            const Text(
              'Upload Bukti Transfer',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 10),

        InkWell(
          onTap: _pickFile,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.cloud_upload_outlined,
                    size: 40,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _uploadedFileName ?? 'Unggah Bukti Pembayaran (Max 2MB)',
                    style: TextStyle(
                      color: _uploadedFileName != null
                          ? Colors.black
                          : Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// --- Section Header ---
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const SectionHeader({super.key, required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

// --- Bottom NavBar ---
class MyBottomNavBar extends StatelessWidget {
  const MyBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      currentIndex: 0,
      selectedItemColor: Colors.blue,
      onTap: (index) {},
    );
  }
}

// --- Success Screen ---
class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran Berhasil')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 100),
              const SizedBox(height: 20),

              const Text(
                'Pesanan Berhasil Dibuat!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),
              const Text(
                'Terima kasih! Bukti pembayaran telah kami terima. Status pesanan akan diperbarui setelah admin mengonfirmasi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.description,
                      color: Colors.green,
                      size: 30,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Bukti Pembayaran Diterima',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Total Pesanan:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const Text(
                      'Rp 75.000,-',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                icon: const Icon(Icons.home),
                label: const Text('Kembali ke Halaman Utama'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const MyBottomNavBar(),
    );
  }
}
