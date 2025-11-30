import 'package:flutter/material.dart';
import 'services/firestore_service.dart';

class AdminPriceAndPaymentScreen extends StatefulWidget {
  const AdminPriceAndPaymentScreen({super.key});

  @override
  State<AdminPriceAndPaymentScreen> createState() =>
      _AdminPriceAndPaymentScreenState();
}

class _AdminPriceAndPaymentScreenState
    extends State<AdminPriceAndPaymentScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _price1Controller = TextEditingController();
  final TextEditingController _price2Controller = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _accountHolderController =
      TextEditingController();

  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    try {
      final pricingSnap = await _firestoreService.getPricingStream().first;
      final paymentSnap = await _firestoreService.getPaymentInfoStream().first;

      final pricingData = pricingSnap.data() as Map<String, dynamic>? ?? {};
      final paymentData = paymentSnap.data() as Map<String, dynamic>? ?? {};

      setState(() {
        _price1Controller.text = (pricingData['session1Price'] ?? 75000)
            .toString();
        _price2Controller.text = (pricingData['session2Price'] ?? 95000)
            .toString();
        _discountController.text = (pricingData['discountPercent'] ?? 0)
            .toString();
        _bankNameController.text = paymentData['bankName'] ?? 'Bank Mandiri';
        _accountNumberController.text = paymentData['accountNumber'] ?? '';
        _accountHolderController.text = paymentData['accountHolder'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
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

  void _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      int price1 = int.tryParse(_price1Controller.text) ?? 0;
      int price2 = int.tryParse(_price2Controller.text) ?? 0;
      int discount = int.tryParse(_discountController.text) ?? 0;

      if (price1 <= 0 || price2 <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harga harus lebih dari 0!')),
        );
        setState(() => _isSaving = false);
        return;
      }

      await _firestoreService.updatePricing(
        session1Price: price1,
        session2Price: price2,
        discountPercent: discount,
      );

      await _firestoreService.updatePaymentInfo(
        bankName: _bankNameController.text,
        accountNumber: _accountNumberController.text,
        accountHolder: _accountHolderController.text,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Pengaturan berhasil disimpan!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tarif & Pembayaran'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarif & Pembayaran'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kelola Tarif Sewa & Metode Pembayaran',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Perubahan akan langsung berlaku di aplikasi pelanggan.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _buildPricingSection(),
            const SizedBox(height: 24),
            _buildPaymentSection(),
            const SizedBox(height: 24),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💰 Tarif Per Jam',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          _buildPriceField(
            'Harga Sesi 1 (Pagi 06:00-14:00)',
            _price1Controller,
          ),
          const SizedBox(height: 12),
          _buildPriceField(
            'Harga Sesi 2 (Sore/Malam 14:00-23:00)',
            _price2Controller,
          ),
          const SizedBox(height: 12),
          _buildPriceField('Diskon (%)', _discountController),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏦 Rekening Pembayaran',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Nama Bank',
            'Contoh: Bank Mandiri',
            _bankNameController,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            'Nomor Rekening',
            'Contoh: 1520016356871',
            _accountNumberController,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            'Atas Nama',
            'Contoh: BKK PLN AREA MAKASSAR SELATAN',
            _accountHolderController,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _saveChanges,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isSaving
          ? const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            )
          : const Text(
              'Simpan Perubahan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
    );
  }

  Widget _buildPriceField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Masukkan harga...',
            prefixText: 'Rp ',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}
