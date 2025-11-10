import 'package:flutter/material.dart';

// --- Model Data (Mereplikasi State atau Data dari Backend) ---
class PriceConfig {
  final int session1Price;
  final int session2Price;
  final int discountPercent;
  final String bankName;
  final String accountNumber;
  final String accountHolder;

  PriceConfig({
    required this.session1Price,
    required this.session2Price,
    required this.discountPercent,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
  });

  PriceConfig copyWith({
    int? session1Price,
    int? session2Price,
    int? discountPercent,
    String? bankName,
    String? accountNumber,
    String? accountHolder,
  }) {
    return PriceConfig(
      session1Price: session1Price ?? this.session1Price,
      session2Price: session2Price ?? this.session2Price,
      discountPercent: discountPercent ?? this.discountPercent,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountHolder: accountHolder ?? this.accountHolder,
    );
  }
}

// --- Admin Price & Payment Screen (Stateful Widget) ---
class AdminPriceAndPaymentScreen extends StatefulWidget {
  const AdminPriceAndPaymentScreen({super.key});

  @override
  State<AdminPriceAndPaymentScreen> createState() => _AdminPriceAndPaymentScreenState();
}

class _AdminPriceAndPaymentScreenState extends State<AdminPriceAndPaymentScreen> {
  
  // State data konfigurasi harga
  late PriceConfig _config;

  // Controller untuk form
  final TextEditingController _price1Controller = TextEditingController();
  final TextEditingController _price2Controller = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _accountHolderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Inisialisasi mock data (Di proyek nyata, ini harus diambil dari Firestore/API)
    _config = PriceConfig(
      session1Price: 75000,
      session2Price: 95000,
      discountPercent: 0,
      bankName: 'Bank Mandiri',
      accountNumber: '1520016356871',
      accountHolder: 'BKK PLN AREA MAKASSAR SELATAN',
    );

    // Set nilai awal ke controllers
    _price1Controller.text = _config.session1Price.toString();
    _price2Controller.text = _config.session2Price.toString();
    _discountController.text = _config.discountPercent.toString();
    _bankNameController.text = _config.bankName;
    _accountNumberController.text = _config.accountNumber;
    _accountHolderController.text = _config.accountHolder;
  }
  
  @override
  void dispose() {
    _price1Controller.dispose();
    _price2Controller.dispose();
    _discountController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  // LOGIKA: Menyimpan perubahan (mirip dengan fungsi API di Next.js)
  void _saveChanges() {
    setState(() {
      _config = _config.copyWith(
        session1Price: int.tryParse(_price1Controller.text) ?? _config.session1Price,
        session2Price: int.tryParse(_price2Controller.text) ?? _config.session2Price,
        discountPercent: int.tryParse(_discountController.text) ?? _config.discountPercent,
        bankName: _bankNameController.text,
        accountNumber: _accountNumberController.text,
        accountHolder: _accountHolderController.text,
      );
    });
    
    // Logic: Kirim data _config yang baru ke API/Firestore
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perubahan Tarif dan Pembayaran berhasil disimpan!')),
    );
  }

  // Fungsi pembantu untuk format Rupiah sederhana
  String _formatRupiah(int amount) {
    // Di aplikasi nyata, gunakan package intl
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
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
              'Tarif & Pembayaran',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Atur harga sewa lapangan dan kelola informasi rekening transfer.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // --- KARTU HARGA SAAT INI ---
            Row(
              children: [
                _PriceCard(
                  title: 'HARGA SAAT INI',
                  subtitle: 'Sesi 1',
                  price: _formatRupiah(_config.session1Price),
                  iconColor: Colors.blue,
                ),
                const SizedBox(width: 10),
                _PriceCard(
                  title: 'HARGA SAAT INI',
                  subtitle: 'Sesi 2',
                  price: _formatRupiah(_config.session2Price),
                  iconColor: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- FORM HARGA SEWA ---
            _buildSectionTitle(Icons.access_time, 'Harga Sewa Per Sesi'),
            _buildPriceInput('Harga Sesi 1 (Rp)', _price1Controller),
            const SizedBox(height: 15),
            _buildPriceInput('Harga Sesi 2 (Rp)', _price2Controller),
            const SizedBox(height: 30),

            // --- FORM DISKON ---
            _buildSectionTitle(Icons.percent, 'Diskon Umum'),
            _buildPriceInput('Diskon (%)', _discountController, isPercent: true),
            const SizedBox(height: 30),
            
            // --- FORM REKENING PEMBAYARAN ---
            _buildSectionTitle(Icons.account_balance_wallet, 'Rekening Pembayaran'),
            _buildTextFormField('Nama Bank', _bankNameController),
            const SizedBox(height: 15),
            _buildTextFormField('Nomor Rekening', _accountNumberController, keyboardType: TextInputType.number),
            const SizedBox(height: 15),
            _buildTextFormField('Atas Nama (A.N.)', _accountHolderController),
            const SizedBox(height: 30),

            // --- TOMBOL SIMPAN ---
            ElevatedButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save),
              label: const Text('Simpan Semua Perubahan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Widget Pembantu Judul Seksi
  Widget _buildSectionTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
  
  // Widget Pembantu Input Harga
  Widget _buildPriceInput(String label, TextEditingController controller, {bool isPercent = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            suffixText: isPercent ? '%' : null,
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            isDense: true,
          ),
        ),
      ],
    );
  }

  // Widget Pembantu Text Form Field umum
  Widget _buildTextFormField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: const InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

// --- Komponen Kartu Harga Kecil ---
class _PriceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final Color iconColor;

  const _PriceCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text(subtitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              Text(
                price,
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}