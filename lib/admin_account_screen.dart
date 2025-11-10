import 'package:flutter/material.dart';

// --- Model Data Sederhana untuk Admin User ---
class AdminUser {
  final String id;
  final String name;
  final String email;
  final String createdAt;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });
}

// --- Admin Account Management Screen ---
class AdminAccountScreen extends StatefulWidget {
  const AdminAccountScreen({super.key});

  @override
  State<AdminAccountScreen> createState() => _AdminAccountScreenState();
}

class _AdminAccountScreenState extends State<AdminAccountScreen> {
  // Contoh data user admin (di aplikasi nyata akan diambil dari API/Firebase)
  List<AdminUser> _adminUsers = [
    AdminUser(
      id: '104',
      name: 'achmadzidann219',
      email: 'achmadzidann219@gmail.com',
      createdAt: '9/11/2025, 15.11.07',
    ),
    AdminUser(
      id: '105',
      name: 'Amrullah',
      email: 'ahmadzidan010@gmail.com',
      createdAt: '15/10/2025, 20.52.18',
    ),
    AdminUser(
      id: '106',
      name: 'Budi Santoso',
      email: 'budi.santoso@gmail.com',
      createdAt: '1/12/2025, 10.00.00',
    ),
  ];

  // LOGIKA: Fungsi untuk menghapus user
  void _deleteUser(String id) {
    setState(() {
      _adminUsers.removeWhere((user) => user.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User dengan ID $id berhasil dihapus!')),
    );
  }

  // LOGIKA: Fungsi untuk mengedit user (akan membuka dialog atau halaman baru)
  void _editUser(AdminUser user) {
    // Di sini Anda bisa menavigasi ke halaman edit atau menampilkan dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: Text('Anda ingin mengedit user: ${user.name} (${user.email})'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
              'Manajemen Akun Admin',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Kelola daftar akun admin yang terdaftar di Firebase Authentication.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // --- Daftar Pengguna Admin ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daftar Pengguna Admin',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 20, thickness: 1),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _adminUsers.length,
                    itemBuilder: (context, index) {
                      final user = _adminUsers[index];
                      return AdminUserCard(
                        user: user,
                        onEdit: () => _editUser(user),
                        onDelete: () => _deleteUser(user.id),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Widget Kartu Pengguna Admin ---
class AdminUserCard extends StatelessWidget {
  final AdminUser user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AdminUserCard({
    super.key,
    required this.user,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.person_outline, size: 30, color: Colors.grey),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    user.email,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  Text(
                    'Dibuat: ${user.createdAt}',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}