import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mendapatkan User saat ini
  User? get currentUser => _auth.currentUser;

  // 1. LOGIN (Sign In)
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // 2. REGISTER (Sign Up) & Simpan Data User ke Firestore
  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      // a. Buat Akun di Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // b. Simpan detail tambahan ke Firestore 'users' collection
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'username': name,
          'phone': phone,
          'role': 'user', // Default role
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // 3. LOGOUT
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 4. CEK ROLE (Admin/User)
  Future<String> getUserRole() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data()?['role'] ?? 'user';
      }
    }
    return 'user';
  }

  // 5. [BARU] RESET PASSWORD (Kirim Email)
  // Fungsi ini digunakan di Admin Management untuk mereset password admin lain
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print("✅ Email reset password terkirim ke $email");
    } on FirebaseAuthException catch (e) {
      print("❌ Gagal kirim email reset: ${e.message}");
      throw Exception(e.message);
    }
  }
}
