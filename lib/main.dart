import 'package:flutter/material.dart';

// ✅ Semua import wajib di atas
import 'admin_home_screen.dart';
import 'booking_screen.dart';
import 'payment_confirmation_screen.dart';

void main() {
  runApp(const BookingApp());
}

// --- WIDGET UTAMA: BookingApp ---
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

// --- LAYAR UTAMA USER ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const BookingScreen(),
    const BookingPagePlaceholder(),
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
        title: const Text('Booking Tempat Olahraga'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Center(
        child: _widgetOptions[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Cari',
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

// --- PROFILE PAGE ---
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: CircleAvatar(radius: 50, child: Icon(Icons.person, size: 60)),
          ),
          const SizedBox(height: 20),
          Text('User Profile', style: Theme.of(context).textTheme.headlineSmall),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('Lihat Pesanan Saya'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaymentConfirmationScreen()),
              );
            },
          ),

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
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Logout dilakukan.')));
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

// --- PLACEHOLDER SEARCH PAGE ---
class BookingPagePlaceholder extends StatelessWidget {
  const BookingPagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Halaman Pencarian/Booking: Tambahkan Fitur Pencarian di sini."),
    );
  }
}
