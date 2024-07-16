import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'login_screen.dart'; // Sesuaikan dengan path login_screen.dart
import 'dashboard_user_screen.dart'; // Sesuaikan dengan path dashboard_screen.dart
import '../services/auth_service.dart'; // Sesuaikan dengan path AuthService
import 'dashboard_md_screen.dart'; // Sesuaikan dengan path dashboard_md_screen.dart
import 'event_screen.dart'; // Sesuaikan dengan path event_screen.dart

class DashboardAdminScreen extends StatelessWidget {
  final String role;
  final log = Logger('DashboardAdminScreen');

  DashboardAdminScreen({required this.role});

  @override
  Widget build(BuildContext context) {
    // Cek apakah role adalah admin
    if (role != 'admin') {
      log.warning('Role tidak diizinkan mengakses dashboard admin: $role');
      // Jika bukan admin, kembali ke dashboard umum
      return DashboardUserScreen(role: role);
    }

    log.info('Akses ke dashboard admin dengan role: $role');
    // Jika admin, tampilkan dashboard admin
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Admin'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              _logout(context);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to Admin Dashboard, $role!'), // Menampilkan pesan selamat datang dengan role
            SizedBox(height: 20),
            // Tambahkan menu untuk navigasi ke dashboard master data
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('Master Data Dashboard'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DashboardMDScreen(role: role)), // Sesuaikan dengan path yang sesuai
                );
              },
            ),
            SizedBox(height: 20),
            // Tambahkan menu untuk navigasi ke event screen
            ListTile(
              leading: Icon(Icons.event),
              title: Text('Event'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EventScreen()), // Sesuaikan dengan path yang sesuai
                );
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _logout(context);
              },
              child: Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }

  void _logout(BuildContext context) async {
    try {
      log.info('Melakukan logout');
      AuthService authService = AuthService();
      await authService.logout(); // Pastikan method logout ada di AuthService

      // Navigasi ke halaman login setelah logout
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      log.severe('Terjadi kesalahan saat logout: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Terjadi kesalahan saat logout: $e'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
