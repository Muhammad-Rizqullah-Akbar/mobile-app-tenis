import 'package:flutter/material.dart';

// --- Payment Confirmation Screen (Stateful Widget) ---
class PaymentConfirmationScreen extends StatefulWidget {
  const PaymentConfirmationScreen({super.key});

  @override
  State<PaymentConfirmationScreen> createState() => _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  // GlobalKey untuk mengelola status Form dan memicu validasi.
  final _formKey = GlobalKey<FormState>();

  // State untuk form input
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  // State untuk status file upload
  String? _uploadedFileName;

  // Contoh data pesanan
  final String _lapangan = 'Lapangan 1';
  final String _date = 'Senin, 10 November 2025';
  final String _time = '10:00 - 11:00';
  final int _totalJam = 1;
  final String _totalPembayaran = 'Rp 75.000,-';
  final String _bankName = 'Bank Mandiri';
  final String _accountNumber = '1520016356871';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // LOGIKA: Mock untuk memilih file (placeholder)
  void _pickFile() {
    setState(() {
      _uploadedFileName = 'bukti_transfer_${DateTime.now().millisecondsSinceEpoch}.jpg';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('File dipilih: $_uploadedFileName')),
    );
  }

  // LOGIKA: Proses menyelesaikan pembayaran (dengan validasi Form)
  void _submitPayment() {
    // 1. Validasi Form Input Teks
    if (_formKey.currentState!.validate()) {
      // 2. Validasi File Upload (Manual)
      if (_uploadedFileName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mohon unggah bukti pembayaran.')),
        );
        return;
      }
      
      // Jika semua validasi Lolos (Form & File)
      
      // Logic API call untuk konfirmasi pembayaran
      
      // Navigasi ke Halaman Sukses
      Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentSuccessScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          children: [
            // --- RINGKASAN PESANAN ---
            _buildOrderSummary(),
            
            // --- DETAIL & PEMBAYARAN (Dibungkus Form) ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey, // Pasang GlobalKey di sini
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(icon: Icons.credit_card, title: 'Detail & Pembayaran'),
                    const SizedBox(height: 15),
                    
                    // Form Input Nama (Ganti _buildFormInput dengan _buildTextFormField)
                    _buildTextFormField(
                      icon: Icons.person_outline,
                      label: 'Nama Lengkap',
                      hint: 'Nama lengkap untuk notifikasi',
                      controller: _nameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama lengkap wajib diisi.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    // Form Input Telepon (Ganti _buildFormInput dengan _buildTextFormField)
                    _buildTextFormField(
                      icon: Icons.phone_android,
                      label: 'Nomor Telepon (WA)',
                      hint: 'Nomor WA Aktif',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nomor telepon wajib diisi.';
                        }
                        if (value.length < 8) {
                          return 'Nomor terlalu pendek.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // --- TRANSFER & BUKTI ---
                    const SectionHeader(icon: Icons.receipt_long, title: 'Transfer & Bukti'),
                    const SizedBox(height: 15),
                    
                    // Kartu Info Transfer Bank
                    _buildBankTransferInfo(),
                    const SizedBox(height: 20),

                    // Upload Bukti Pembayaran
                    _buildFileUploadSection(),
                    const SizedBox(height: 30),
                    
                    // Tombol Selesaikan Pembayaran
                    ElevatedButton.icon(
                      onPressed: _submitPayment, // Memanggil fungsi submit dengan validasi
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Selesaikan Pembayaran'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  // Widget Bagian Ringkasan Pesanan (Tetap sama)
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
              label: Text('TOTAL JAM: $_totalJam', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              backgroundColor: Colors.white24,
              labelStyle: const TextStyle(color: Colors.white),
            ),
          ),
          const Text('RINGKASAN PESANAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
                Chip(label: Text(_lapangan), backgroundColor: Colors.yellow.shade100),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_month, color: Colors.white70, size: 18),
                    const SizedBox(width: 5),
                    Text(_date, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.white70, size: 18),
                    const SizedBox(width: 5),
                    Text(_time, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Total Pembayaran
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('TOTAL\nPEMBAYARAN', style: TextStyle(color: Colors.white70, fontSize: 14)),
              Text(_totalPembayaran, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 30)),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
  
  // WIDGET BARU: Menggantikan _buildFormInput dengan TextFormField yang mendukung validasi
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
        TextFormField( // Menggunakan TextFormField
          controller: controller,
          keyboardType: keyboardType,
          validator: validator, // Menambahkan fungsi validator
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  // Widget Kartu Info Transfer Bank (Tetap sama)
  Widget _buildBankTransferInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance, color: Colors.blue, size: 20),
                const SizedBox(width: 5),
                Text('Transfer Bank - $_bankName', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Text('Transfer **$_totalPembayaran** ke:', style: const TextStyle(color: Colors.grey)),
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 5),
            const Text('a.n. BKK PLN AREA MAKASSAR SELATAN', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // Widget Bagian Upload File (Tetap sama)
  Widget _buildFileUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.upload_file, size: 18, color: Colors.grey),
            const SizedBox(width: 5),
            const Text('Transfer & Bukti', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 10),
        
        InkWell(
          onTap: _pickFile,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.blue),
                  const SizedBox(height: 5),
                  Text(
                    _uploadedFileName ?? 'Unggah Bukti Pembayaran (Max 2MB)',
                    style: TextStyle(color: _uploadedFileName != null ? Colors.black : Colors.blue),
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

// Widget Pembantu untuk Judul Seksi (Tetap sama)
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  
  const SectionHeader({super.key, required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// --- Placeholder Bottom NavBar (Tetap sama) ---
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
      onTap: (index) {
        // Implementasi navigasi di sini
      },
    );
  }
}


// --- Halaman Sukses (Tetap sama) ---
class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran Berhasil')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 100),
              const SizedBox(height: 20),
              const Text('Pesanan Berhasil Dibuat!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text(
                'Terima kasih, Bukti pembayaran Anda telah kami terima. Status pesanan akan diperbarui setelah dikonfirmasi oleh admin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              
              // Bukti Pembayaran Diterima (Card Hijau)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.description, color: Colors.green, size: 30),
                    const SizedBox(height: 10),
                    const Text('Bukti Pembayaran Diterima', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    const Text('Pesanan ini senilai total:', style: TextStyle(color: Colors.grey)),
                    Text('Rp 75.000,-', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              // Tombol Kembali ke Halaman Utama
              ElevatedButton.icon(
                onPressed: () {
                  // Kembali ke halaman utama (MainScreen)
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                icon: const Icon(Icons.home),
                label: const Text('Kembali ke Halaman Utama'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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