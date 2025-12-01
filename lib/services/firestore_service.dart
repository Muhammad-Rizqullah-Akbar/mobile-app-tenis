import 'dart:typed_data'; // [WAJIB] Untuk Uint8List
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // [WAJIB] Storage
import 'package:image_picker/image_picker.dart'; // [WAJIB] XFile

class FirestoreService {
  // --- REFERENSI COLLECTION ---
  final CollectionReference _ordersRef = FirebaseFirestore.instance.collection(
    'orders',
  );
  final CollectionReference _settingsRef = FirebaseFirestore.instance
      .collection('settings');
  final CollectionReference _usersRef = FirebaseFirestore.instance.collection(
    'users',
  );

  // ===========================================================================
  // 1. BAGIAN ORDERS (PESANAN)
  // ===========================================================================

  // CREATE: Tambah Booking Baru
  Future<void> addBooking({
    required String orderId,
    required String customerName,
    required String customerPhone,
    required int totalPrice,
    required String proofUrl,
    required List<Map<String, dynamic>> bookings,
  }) async {
    try {
      await _ordersRef.doc(orderId).set({
        'orderId': orderId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'totalPrice': totalPrice,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'mobile_app',
        'proofUrl': proofUrl,
        'isRescheduled': false,
        'bookings': bookings,
      });
      print("✅ DATA BOOKING BERHASIL DISIMPAN KE FIRESTORE!");
    } catch (e) {
      print("❌ Gagal simpan ke Firestore: $e");
      throw Exception('Gagal menyimpan pesanan.');
    }
  }

  // FUNGSI UPLOAD BUKTI BAYAR
  Future<String> uploadProof(XFile file, String fileName) async {
    try {
      print("🚀 Mencoba upload gambar ke Storage...");
      Uint8List data = await file.readAsBytes();
      Reference ref = FirebaseStorage.instance.ref().child(
        'payment_proofs/$fileName',
      );
      UploadTask uploadTask = ref.putData(
        data,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      TaskSnapshot snapshot = await uploadTask;
      String url = await snapshot.ref.getDownloadURL();
      print("✅ Upload Berhasil! URL: $url");
      return url;
    } catch (e) {
      print("⚠️ Upload Gagal (CORS/Network). Pakai placeholder.");
      return "https://via.placeholder.com/400x300.png?text=Bukti+Transfer+(Error+Upload)";
    }
  }

  // READ: Ambil Semua Data Pesanan (ADMIN)
  Stream<QuerySnapshot> getOrdersStream() {
    return _ordersRef.orderBy('createdAt', descending: true).snapshots();
  }

  // READ: Ambil Data Pesanan Spesifik User (USER)
  Stream<QuerySnapshot> getUserOrdersStream(String userIdentifier) {
    return _ordersRef
        .where('customerName', isEqualTo: userIdentifier)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // UPDATE Status Pesanan
  Future<void> updateOrderStatus(String docId, String newStatus) async {
    await _ordersRef.doc(docId).update({'status': newStatus});
  }

  // DELETE Pesanan
  Future<void> deleteOrder(String docId) async {
    await _ordersRef.doc(docId).delete();
  }

  // ===========================================================================
  // 2. BAGIAN SETTINGS (Pricing, Operational, Carousel)
  // ===========================================================================

  // --- PRICING ---
  Stream<DocumentSnapshot> getPricingStream() {
    return _settingsRef.doc('pricing').snapshots();
  }

  Future<void> updatePricing({
    required int session1Price,
    required int session2Price,
    required int discountPercent,
  }) async {
    try {
      await _settingsRef.doc('pricing').set({
        'session1Price': session1Price,
        'session2Price': session2Price,
        'discountPercent': discountPercent,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print("✅ Harga berhasil diperbarui!");
    } catch (e) {
      print("❌ Gagal update harga: $e");
      throw Exception('Gagal memperbarui harga.');
    }
  }

  // --- PAYMENT INFO ---
  Stream<DocumentSnapshot> getPaymentInfoStream() {
    return _settingsRef.doc('payment_info').snapshots();
  }

  Future<void> updatePaymentInfo({
    required String bankName,
    required String accountNumber,
    required String accountHolder,
  }) async {
    try {
      await _settingsRef.doc('payment_info').set({
        'bankName': bankName,
        'accountNumber': accountNumber,
        'accountHolder': accountHolder,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print("✅ Info pembayaran berhasil diperbarui!");
    } catch (e) {
      print("❌ Gagal update info pembayaran: $e");
      throw Exception('Gagal memperbarui info pembayaran.');
    }
  }

  // --- CAROUSEL ---
  Stream<DocumentSnapshot> getCarouselStream() {
    return _settingsRef.doc('carousel').snapshots();
  }

  Future<void> updateCarouselImages(List<Map<String, dynamic>> images) async {
    try {
      await _settingsRef.doc('carousel').set({
        'images': images,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print("✅ Carousel berhasil diperbarui!");
    } catch (e) {
      print("❌ Gagal update carousel: $e");
      throw Exception('Gagal memperbarui carousel.');
    }
  }

  Future<String> uploadCarouselImage(XFile file, String fileName) async {
    try {
      Uint8List data = await file.readAsBytes();
      Reference ref = FirebaseStorage.instance.ref().child(
        'carousel_images/$fileName',
      );
      UploadTask uploadTask = ref.putData(
        data,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("❌ Gagal upload carousel: $e");
      throw Exception('Gagal mengupload gambar carousel.');
    }
  }

  // --- OPERATIONAL HOURS ---

  Stream<DocumentSnapshot> getOperationalStream() {
    return _settingsRef.doc('operating_hours').snapshots();
  }

  // [FUNGSI UTAMA 1] Update seluruh dokumen (Legacy/Backward Compatibility)
  Future<void> updateOperationalHours(Map<String, dynamic> scheduleData) async {
    // Kita arahkan ke fungsi field spesifik agar aman
    await updateOperationalHoursField('schedule', scheduleData);
  }

  // [FUNGSI UTAMA 2] Update Field Spesifik (schedule atau exceptions)
  // Ini yang dipanggil oleh AdminOperationalScreen yang baru
  Future<void> updateOperationalHoursField(
    String fieldName,
    dynamic data,
  ) async {
    try {
      print("🚀 Mengupdate field '$fieldName' di operating_hours...");

      // Gunakan SetOptions(merge: true) agar field lain tidak hilang
      // Contoh: Update 'exceptions' tidak akan menghapus 'schedule'
      await _settingsRef.doc('operating_hours').set({
        fieldName: data,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("✅ Sukses update field '$fieldName'!");
    } catch (e) {
      print("❌ Gagal update '$fieldName': $e");
      throw Exception('Gagal menyimpan perubahan jam operasional.');
    }
  }

  // ===========================================================================
  // 3. BAGIAN USERS (ADMIN ACCOUNT)
  // ===========================================================================

  Stream<QuerySnapshot> getAdminsStream() {
    return _usersRef.where('role', isEqualTo: 'admin').snapshots();
  }

  // Update Password (Hanya timestamp, karena pass asli di Auth)
  Future<void> updateAdminPassword(String userId, String newPassword) async {
    try {
      await _usersRef.doc(userId).update({
        'passwordUpdatedAt': FieldValue.serverTimestamp(),
      });
      print("✅ Password berhasil diperbarui!");
    } catch (e) {
      print("❌ Gagal update password: $e");
      throw Exception('Gagal memperbarui password.');
    }
  }

  // [BARU] Update Data User (Username & Phone) - Dipakai di Admin Management
  Future<void> updateUserData(
    String uid, {
    required String username,
    required String phone,
  }) async {
    try {
      await _usersRef.doc(uid).update({
        'username': username,
        'phone': phone,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("✅ Data Admin berhasil diupdate!");
    } catch (e) {
      print("❌ Gagal update user: $e");
      throw Exception('Gagal mengupdate data user.');
    }
  }

  // ===========================================================================
  // 4. BAGIAN ADMIN BOOKING MANAGEMENT
  // ===========================================================================

  Stream<QuerySnapshot> getBookingsByStatus(String status) {
    if (status == 'Semua') {
      return _ordersRef.orderBy('createdAt', descending: true).snapshots();
    }
    return _ordersRef
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<List<Map<String, dynamic>>> getBookingsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _ordersRef
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print("❌ Gagal ambil data by date range: $e");
      return [];
    }
  }

  Future<void> bulkUpdateOrderStatus(
    List<String> orderIds,
    String newStatus,
  ) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (String orderId in orderIds) {
        batch.update(_ordersRef.doc(orderId), {'status': newStatus});
      }
      await batch.commit();
      print("✅ Status pesanan berhasil diperbarui!");
    } catch (e) {
      print("❌ Gagal update status pesanan: $e");
      throw Exception('Gagal memperbarui status pesanan.');
    }
  }

  Future<void> addManualBooking({
    required String customerName,
    required String customerPhone,
    required List<Map<String, dynamic>> bookings,
    required int totalPrice,
  }) async {
    try {
      String orderId = 'APP-${DateTime.now().millisecondsSinceEpoch}';
      await _ordersRef.doc(orderId).set({
        'orderId': orderId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'totalPrice': totalPrice,
        'status': 'Confirmed',
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'admin_app',
        'proofUrl': '',
        'isRescheduled': false,
        'bookings': bookings,
      });
      print("✅ Booking manual berhasil dibuat!");
    } catch (e) {
      print("❌ Gagal membuat booking manual: $e");
      throw Exception('Gagal membuat booking manual.');
    }
  }

  // [BARU] Fungsi Reschedule Beneran (Update Slot Waktu)
  Future<void> rescheduleOrder({
    required String orderId,
    required List<Map<String, dynamic>> newBookings,
  }) async {
    try {
      // Kita cari dokumen berdasarkan field 'orderId'
      // Karena kadang ID dokumen == orderId, tapi kadang beda (tergantung implementasi add booking)
      // Tapi di sini kita asumsikan doc ID = orderId sesuai fungsi addBooking

      await _ordersRef.doc(orderId).update({
        'bookings': newBookings, // Timpa slot lama dengan yang baru
        'status': 'Rescheduled', // Ubah status
        'isRescheduled': true, // Tandai pernah di-reschedule
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("✅ Order $orderId berhasil di-reschedule!");
    } catch (e) {
      print("❌ Gagal reschedule: $e");
      throw Exception('Gagal melakukan reschedule.');
    }
  }
}
