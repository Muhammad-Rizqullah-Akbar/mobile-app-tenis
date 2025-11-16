import 'package:flutter/material.dart';

// --- IMPORT SEMUA FILE YANG DIBUTUHKAN ---
// Pastikan semua file ini ada di folder 'lib/' Anda:
import 'admin_home_screen.dart';
import 'payment_confirmation_screen.dart';
import 'order_history_search_screen.dart'; // <<< GANTI MENJADI HALAMAN RIWAYAT PESANAN
import 'order_history.dart'; // <<< GANTI MENJADI HALAMAN RIWAYAT PESANAN
import 'booking_screen.dart';

void main() {
  runApp(const BookingApp());
}

// ----------------------------------------------------
// --- 1. WIDGET UTAMA: BookingApp (Material App) ---
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
// --- 2. MAIN SCREEN DENGAN BOTTOM NAVIGATION ---
// ----------------------------------------------------
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Halaman dari Bottom Navbar
  static final List<Widget> _widgetOptions = <Widget>[
    const BookingScreen(),
    const OrderHistorySearchScreen(), // <<< TAB CARI DIGANTI JADI RIWAYAT PESANAN
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
            icon: Icon(Icons.search), // ICON LEBIH LOGIS
            label: 'Riwayat', // LABEL DIGANTI
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
// --- 3. PROFILE PAGE (AKSES ADMIN & RIWAYAT) ---
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
                MaterialPageRoute(
                  builder: (_) => const OrderHistoryScreen(), // <<< FIX
                ),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logout dilakukan.')),
              );
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
