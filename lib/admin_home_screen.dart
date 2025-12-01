import 'package:flutter/material.dart';
import 'admin_account_screen.dart';
import 'admin_carousel_management_screen.dart';
import 'admin_history_screen.dart';
import 'admin_operational_screen.dart';
import 'admin_price_and_payment_screen.dart';
import 'admin_schedule_management.dart';
import 'services/auth_service.dart'; // Import Auth Service
import 'screens/auth/login_screen.dart'; // Import Login Screen

// --- Admin Home Screen (Stateless Widget) ---
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      drawer: const AdminDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pusat Kontrol',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              'Kelola seluruh konfigurasi aplikasi Tennis Court dari sini.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 25),

            // --- Menu Item Cards ---
            AdminMenuItemCard(
              icon: Icons.manage_accounts,
              iconColor: Colors.teal,
              title: 'Manajemen Akun',
              subtitle: 'Kelola data profil admin dan reset password.',
              onTap: () => _navigateTo(context, const AdminAccountScreen()),
            ),
            AdminMenuItemCard(
              icon: Icons.payments,
              iconColor: Colors.amber,
              title: 'Tarif & Pembayaran',
              subtitle: 'Atur harga sewa dan info rekening pembayaran.',
              onTap: () =>
                  _navigateTo(context, const AdminPriceAndPaymentScreen()),
            ),
            AdminMenuItemCard(
              icon: Icons.schedule,
              iconColor: Colors.redAccent,
              title: 'Jam Operasional',
              subtitle: 'Tentukan jam buka harian dan hari libur.',
              onTap: () => _navigateTo(context, const AdminOperationalScreen()),
            ),
            AdminMenuItemCard(
              icon: Icons.image,
              iconColor: Colors.blue,
              title: 'Pengaturan Carousel',
              subtitle: 'Upload dan atur urutan banner promosi.',
              onTap: () => _navigateTo(context, const AdminCarouselScreen()),
            ),

            const SizedBox(height: 30),

            // --- TOMBOL KEMBALI KE MODE USER (TANPA LOGOUT) ---
            ElevatedButton.icon(
              onPressed: () {
                // Cukup kembali ke halaman sebelumnya (MainScreen)
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text(
                'Kembali ke Tampilan User',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade700,
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
    Navigator.pop(context); // Tutup drawer
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            accountName: const Text(
              "Admin Panel",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: const Text("Administrator Mode"),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.admin_panel_settings,
                size: 40,
                color: Colors.blue,
              ),
            ),
          ),

          // --- MENU UTAMA ---

          // 1. Dashboard (Halaman ini)
          _buildDrawerItem(
            context,
            icon: Icons.dashboard,
            title: 'Dashboard Utama',
            onTap: () {
              Navigator.pop(context);
            },
          ),

          // 2. Kelola Jadwal
          _buildDrawerItem(
            context,
            icon: Icons.calendar_month,
            title: 'Kelola Jadwal Booking',
            onTap: () => _navigateToAndPopDrawer(
              context,
              const AdminScheduleManagementScreen(),
            ),
          ),

          // 3. Riwayat Pesanan
          _buildDrawerItem(
            context,
            icon: Icons.history_edu,
            title: 'Laporan Riwayat',
            onTap: () =>
                _navigateToAndPopDrawer(context, const AdminHistoryScreen()),
          ),

          const Spacer(),
          const Divider(),

          // --- KELUAR (LOGOUT BENERAN) ---
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout Akun',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              // 1. Sign Out dari Firebase
              await AuthService().signOut();

              // 2. Kembali ke Login Screen (Hapus semua rute sebelumnya)
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

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
