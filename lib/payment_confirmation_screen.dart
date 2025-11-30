import 'dart:io'; // Untuk Mobile
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:image_picker/image_picker.dart';
// Hapus import cloud_firestore karena kita akan pakai lewat service
import '../models/booking_data.dart';
import '../services/firestore_service.dart';

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

  // Gunakan XFile agar konsisten dengan Service baru & Web
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  final String _bankName = 'Bank Mandiri';
  final String _accountNumber = '1520016356871';

  final Map<String, Map<String, List<String>>> _groupedSlots = {};

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    print(
      '📦 PaymentConfirmationScreen initialized with ${widget.bookingData.slots.length} slots',
    );
    _groupSlotsForDisplay();
  }

  void _groupSlotsForDisplay() {
    try {
      // Validasi data
      if (widget.bookingData.slots.isEmpty) {
        print('⚠️ Tidak ada slot yang dipilih!');
        return;
      }

      print(
        '🔄 Mengelompokkan ${widget.bookingData.slots.length} slots untuk tampilan...',
      );

      for (var slot in widget.bookingData.slots) {
        // Validasi setiap slot
        if (slot.courtName.isEmpty) {
          print('❌ Slot dengan courtName kosong ditemukan!');
          continue;
        }

        if (slot.time.isEmpty) {
          print(
            '❌ Slot dengan time kosong ditemukan untuk court: ${slot.courtName}',
          );
          continue;
        }

        String dateStr = DateFormat(
          'EEEE, d MMMM yyyy',
          'id_ID',
        ).format(slot.date);

        // Pisahkan waktu dengan aman
        String timeSimple = slot.time.split(' - ')[0].trim();

        print('✅ Slot: Court=$slot.courtName, Date=$dateStr, Time=$timeSimple');

        if (!_groupedSlots.containsKey(slot.courtName)) {
          _groupedSlots[slot.courtName] = {};
        }

        if (!_groupedSlots[slot.courtName]!.containsKey(dateStr)) {
          _groupedSlots[slot.courtName]![dateStr] = [];
        }

        _groupedSlots[slot.courtName]![dateStr]!.add(timeSimple);
      }

      // Sort times untuk setiap date
      _groupedSlots.forEach((court, dates) {
        dates.forEach((date, times) {
          times.sort();
        });
      });

      print(
        '✅ Pengelompokan selesai. Total courts: ${_groupedSlots.keys.length}',
      );
    } catch (e, stackTrace) {
      print('❌ ERROR dalam _groupSlotsForDisplay: $e');
      print('Stack Trace: $stackTrace');
    }
  }

  // FUNGSI PILIH GAMBAR (AMAN WEB/MOBILE)
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengambil gambar: $e')));
    }
  }

  // FUNGSI SUBMIT (UPLOAD + SAVE VIA SERVICE)
  Future<void> _submitPayment() async {
    print('🔍 Memulai validasi form...');

    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation gagal');
      return;
    }

    if (_selectedImage == null) {
      print('❌ Tidak ada gambar yang dipilih');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon unggah bukti pembayaran.')),
      );
      return;
    }

    // Validasi data booking
    if (widget.bookingData.slots.isEmpty) {
      print('❌ Slots kosong!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tidak ada slot yang dipilih. Mohon kembali dan pilih slot.',
          ),
        ),
      );
      return;
    }

    print('📋 Nama: ${_nameController.text}');
    print('📋 Phone: ${_phoneController.text}');
    print('📦 Total Slots: ${widget.bookingData.slots.length}');
    print('💰 Total Cost: ${widget.bookingData.totalCost}');

    setState(() => _isLoading = true);

    try {
      // 1. Upload Gambar via Service
      print('🚀 Mengupload bukti pembayaran...');
      String fileName = 'bukti_${DateTime.now().millisecondsSinceEpoch}.jpg';
      String proofUrl = await FirestoreService().uploadProof(
        _selectedImage!,
        fileName,
      );
      print("✅ Bukti pembayaran berhasil diupload: $proofUrl");

      // 2. Siapkan Data Booking
      String orderId = 'APP-${DateTime.now().millisecondsSinceEpoch}';
      print("📋 Order ID: $orderId");
      print('📦 Grouped Slots: $_groupedSlots');

      List<Map<String, dynamic>> bookingsPayload = [];

      // Validasi _groupedSlots tidak kosong
      if (_groupedSlots.isEmpty) {
        print('❌ _groupedSlots kosong! Ini adalah masalah data.');
        throw Exception(
          'Data slot tidak dapat diproses. Silakan kembali ke halaman booking dan pilih slot lagi.',
        );
      }

      // Gunakan for loop biasa untuk kontrol error yang lebih baik
      for (String courtName in _groupedSlots.keys) {
        List<Map<String, String>> slotsPayload = [];
        Map<String, List<String>> datesMap = _groupedSlots[courtName]!;

        for (String dateStr in datesMap.keys) {
          List<String> timesList = datesMap[dateStr]!;

          for (String tSimple in timesList) {
            try {
              // Cari slot asli untuk mendapatkan time lengkap "06:00 - 07:00"
              final matchingSlots = widget.bookingData.slots
                  .where(
                    (s) =>
                        s.courtName == courtName &&
                        DateFormat(
                              'EEEE, d MMMM yyyy',
                              'id_ID',
                            ).format(s.date) ==
                            dateStr &&
                        s.time.startsWith(tSimple),
                  )
                  .toList();

              if (matchingSlots.isNotEmpty) {
                slotsPayload.add({
                  'date': dateStr,
                  'time': matchingSlots.first.time,
                });
                print(
                  "✅ Slot ditemukan: Court=$courtName, Date=$dateStr, Time=${matchingSlots.first.time}",
                );
              } else {
                // Fallback: gunakan time sederhana
                slotsPayload.add({'date': dateStr, 'time': tSimple});
                print(
                  "⚠️ Slot tidak ditemukan (menggunakan fallback): Court=$courtName, Date=$dateStr, Time=$tSimple",
                );
              }
            } catch (e) {
              print(
                "❌ Error saat mencari slot: Court=$courtName, Date=$dateStr, Time=$tSimple, Error=$e",
              );
              slotsPayload.add({'date': dateStr, 'time': tSimple});
            }
          }
        }

        if (slotsPayload.isNotEmpty) {
          bookingsPayload.add({'court': courtName, 'slots': slotsPayload});
        }
      }

      if (bookingsPayload.isEmpty) {
        print('❌ bookingsPayload kosong!');
        throw Exception('Gagal memproses data booking. Silakan coba lagi.');
      }

      print("📦 Booking Payload: $bookingsPayload");

      // 3. Simpan ke Firestore
      print('💾 Menyimpan ke Firestore...');
      await FirestoreService().addBooking(
        orderId: orderId,
        customerName: _nameController.text,
        customerPhone: _phoneController.text,
        totalPrice: widget.bookingData.totalCost,
        proofUrl: proofUrl,
        bookings: bookingsPayload,
      );

      print('✅ Data berhasil disimpan ke Firestore!');

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()),
        );
      }
    } catch (e, stackTrace) {
      print("❌ ERROR SUBMIT PAYMENT: $e");
      print("Stack Trace: $stackTrace");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memproses pesanan: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String totalStr = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(widget.bookingData.totalCost);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Konfirmasi Pembayaran"),
        elevation: 0.5,
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          border: Border(top: BorderSide(color: Colors.blue.shade100)),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Grand Total:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue.shade900,
                ),
              ),
              Text(
                totalStr,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
        ),
      ),

      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ..._groupedSlots.entries.map((entry) {
                return _buildCourtCard(entry.key, entry.value);
              }),

              const SizedBox(height: 24),

              const SectionHeader(icon: Icons.person, title: 'Data Pemesan'),
              const SizedBox(height: 10),
              _buildTextField(
                "Nama Lengkap",
                "Masukkan nama Anda",
                _nameController,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                "Nomor WhatsApp",
                "08xxxxxxxx",
                _phoneController,
                isNumber: true,
              ),

              const SizedBox(height: 24),

              const SectionHeader(icon: Icons.payment, title: 'Pembayaran'),
              const SizedBox(height: 10),
              _buildBankInfo(),
              const SizedBox(height: 16),

              _buildUploadBox(),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _isLoading ? null : _submitPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text("Mengupload Bukti..."),
                        ],
                      )
                    : const Text(
                        "Konfirmasi & Kirim",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET PREVIEW GAMBAR (CROSS PLATFORM FIX)
  Widget _buildUploadBox() {
    return InkWell(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
          ),
        ),
        child: _selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // LOGIC TAMPIL GAMBAR (WEB vs MOBILE)
                    kIsWeb
                        ? Image.network(
                            _selectedImage!.path,
                            fit: BoxFit.cover,
                          ) // Web
                        : Image.file(
                            File(_selectedImage!.path),
                            fit: BoxFit.cover,
                          ), // Mobile

                    Container(
                      color: Colors.black38,
                      child: const Center(
                        child: Icon(Icons.edit, color: Colors.white, size: 30),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.cloud_upload, color: Colors.grey, size: 40),
                  SizedBox(height: 8),
                  Text(
                    "Ketuk untuk Upload Bukti Transfer",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
      ),
    );
  }

  // --- Widget Helper Lainnya (Sama seperti sebelumnya) ---
  Widget _buildCourtCard(String courtName, Map<String, List<String>> datesMap) {
    int hoursCount = 0;
    datesMap.forEach((_, times) => hoursCount += times.length);
    int subTotal = hoursCount * 85000;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Ringkasan Pesanan ($hoursCount Jam)",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    courtName,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: datesMap.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  entry.value.join(", "),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Subtotal", style: TextStyle(color: Colors.white70)),
                Row(
                  children: [
                    const Icon(
                      Icons.local_offer,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(subTotal),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController ctrl, {
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
          validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
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

  Widget _buildBankInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance, color: Colors.blue),
              const SizedBox(width: 10),
              Text(
                _bankName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _accountNumber,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const Text(
            "a.n. BKK PLN AREA MAKASSAR SELATAN",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const SectionHeader({super.key, required this.icon, required this.title});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text(
              "Pesanan Terkirim!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text("Kembali ke Home"),
            ),
          ],
        ),
      ),
    );
  }
}
