import 'package:flutter/material.dart';
// --- IMPORT SEMUA FILE ADMIN UNTUK NAVIGASI ---
import 'admin_account_screen.dart'; // Untuk Manajemen Akun
import 'admin_carousel_management_screen.dart'; // Untuk Pengaturan Carousel
import 'admin_history_screen.dart'; // Untuk Riwayat Pesanan
import 'admin_operational_screen.dart'; // Untuk Jam Operasional
import 'admin_price_and_payment_screen.dart'; // Untuk Tarif & Pembayaran
import 'admin_schedule_management.dart'; // Untuk Kelola Jadwal

// --- Admin Home Screen (Stateless Widget) ---
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  // Fungsi navigasi yang bersih
  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrasi'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      drawer: const AdminDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manajemen Aplikasi',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              'Pilih kategori di bawah ini untuk mengelola konfigurasi sistem Tennis Court Anda.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 25),

            // --- Menu Item Cards ---
            AdminMenuItemCard(
              icon: Icons.manage_accounts, // Mengubah ikon settings lama
              iconColor: Colors.teal,
              title: 'Manajemen Akun',
              subtitle: 'Kelola kata sandi, email, dan detail akun Admin Anda.',
              onTap: () => _navigateTo(
                context,
                const AdminAccountScreen(),
              ), // Navigasi Bekerja
            ),
            AdminMenuItemCard(
              icon: Icons.payments,
              iconColor: Colors.amber,
              title: 'Tarif & Pembayaran',
              subtitle:
                  'Atur harga sewa per jam dan konfigurasi metode pembayaran.',
              onTap: () => _navigateTo(
                context,
                const AdminPriceAndPaymentScreen(),
              ), // Navigasi Bekerja
            ),
            AdminMenuItemCard(
              icon: Icons.schedule,
              iconColor: Colors.redAccent,
              title: 'Jam Operasional',
              subtitle: 'Tentukan jam buka dan tutup harian Lapangan Tenis.',
              onTap: () => _navigateTo(
                context,
                const AdminOperationalScreen(),
              ), // Navigasi Bekerja
            ),
            AdminMenuItemCard(
              icon: Icons.image,
              iconColor: Colors.blue,
              title: 'Pengaturan Carousel',
              subtitle:
                  'Tambah, hapus, atau atur urutan gambar di halaman utama (carousel).',
              onTap: () => _navigateTo(
                context,
                const AdminCarouselScreen(),
              ), // Navigasi Bekerja
            ),

            const SizedBox(height: 30),

            // --- TOMBOL KEMBALI KE APLIKASI USER ---
            ElevatedButton.icon(
              onPressed: () {
                // popUntil kembali ke root screen (MainScreen)
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text(
                'Kembali ke Halaman Booking',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade600,
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
    );
  }
}

// --- Komponen Kartu Menu Admin ---
class AdminMenuItemCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const AdminMenuItemCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Komponen Drawer Admin (Menu Samping) ---
class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  void _navigateToAndPopDrawer(BuildContext context, Widget screen) {
    Navigator.pop(context); // Tutup drawer terlebih dahulu
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        // Menggunakan Column agar bisa menggunakan Spacer
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Tennis Court.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // --- ITEM NAVIGASI DRAWER ---
          _buildDrawerItem(
            context,
            icon: Icons.home,
            title: 'Home Page (Admin)',
            onTap: () =>
                _navigateToAndPopDrawer(context, const AdminHomeScreen()),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.calendar_today,
            title: 'Kelola Jadwal',
            onTap: () => _navigateToAndPopDrawer(
              context,
              const AdminScheduleManagementScreen(),
            ), // Navigasi Bekerja
          ),
          _buildDrawerItem(
            context,
            icon: Icons.history,
            title: 'Riwayat Pesanan',
            onTap: () => _navigateToAndPopDrawer(
              context,
              const AdminHistoryScreen(),
            ), // Navigasi Bekerja
          ),
          _buildDrawerItem(
            context,
            icon: Icons.settings,
            title: 'Pengaturan',
            onTap: () =>
                _navigateToAndPopDrawer(context, const AdminHomeScreen()),
          ),

          const Spacer(), // Mendorong item di bawah ke paling bawah
          // --- LOGOUT / KEMBALI ---
          ListTile(
            leading: const Icon(Icons.arrow_back, color: Colors.red),
            title: const Text('Keluar & Kembali ke Booking'),
            onTap: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }

  // Widget Pembantu untuk item Drawer
  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue.shade800),
      title: Text(title),
      onTap: onTap,
    );
  }
}
