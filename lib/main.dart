import 'package:flutter/material.dart';
// [PENTING] Import Firebase Core
import 'package:firebase_core/firebase_core.dart';
// [PENTING] Import Konfigurasi (File ini dibuat otomatis oleh flutterfire configure)
import 'firebase_options.dart';

// --- IMPORT SEMUA FILE YANG DIBUTUHKAN ---
import 'admin_home_screen.dart';
import 'order_history_search_screen.dart';
import 'order_history.dart';
import 'booking_screen.dart';
// import 'payment_confirmation_screen.dart'; // Tidak dipakai langsung di MainScreen, tapi dibutuhkan navigasi nanti

// ----------------------------------------------------
// --- 1. FUNGSI UTAMA (MAIN) ---
// ----------------------------------------------------
void main() async {
  // 1. Pastikan engine Flutter siap sebelum menjalankan kode async
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inisialisasi Firebase
  // Tanpa baris ini, aplikasi akan ERROR MERAH (FirebaseException) saat dibuka
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 3. Jalankan Aplikasi
  runApp(const BookingApp());
}

// ----------------------------------------------------
// --- 2. WIDGET UTAMA: BookingApp ---
// ----------------------------------------------------
class BookingApp extends StatelessWidget {
  const BookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Booking App Kuliah',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

// ----------------------------------------------------
// --- 3. MAIN SCREEN DENGAN BOTTOM NAVIGATION ---
// ----------------------------------------------------
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Daftar Halaman untuk Bottom Navbar
  static final List<Widget> _widgetOptions = <Widget>[
    // Tab 1: Booking Screen (Sudah diperbaiki dengan logic anti-bentrok)
    const BookingScreen(),

    // Tab 2: Pencarian Riwayat (Nanti kita perbaiki juga agar connect database)
    const OrderHistorySearchScreen(),

    // Tab 3: Profil User & Admin Link
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tennis Court'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: _widgetOptions[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history), // Icon History lebih cocok
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

// ----------------------------------------------------
// --- 4. PROFILE PAGE (AKSES ADMIN & RIWAYAT) ---
// ----------------------------------------------------
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Center(
            child: CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 60),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'User Profile',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const Divider(),

          // Menu Riwayat Pesanan
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Riwayat Pesanan Saya'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
              );
            },
          ),

          // Menu Akses Admin
          ListTile(
            leading: const Icon(Icons.admin_panel_settings, color: Colors.red),
            title: const Text('Akses Admin Panel'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
              );
            },
          ),

          const Spacer(),

          ElevatedButton.icon(
            onPressed: () {
              // Logic logout bisa ditambahkan di sini (misal FirebaseAuth.signOut)
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Logout berhasil.')));
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
