import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../services/auth_service.dart'; // Sesuaikan dengan path AuthService
import 'master_data/md_client_screen.dart'; // Sesuaikan dengan path md_client_screen.dart
import 'master_data/md_user_screen.dart'; // Sesuaikan dengan path md_user_screen.dart
import 'master_data/md_admin_screen.dart'; // Sesuaikan dengan path md_admin_screen.dart
import 'login_screen.dart';

class DashboardMDScreen extends StatelessWidget {
  final String role;
  final log = Logger('DashboardMDScreen');

  DashboardMDScreen({required this.role});

  @override
  Widget build(BuildContext context) {
    log.info('Akses ke dashboard master data dengan role: $role');
    // Widget Scaffold sebagai kerangka utama
    return Scaffold(
      appBar: AppBar(
        title: Text('Master Data Dashboard'),
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
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MDClientScreen(role: role)), // Navigasi ke MDClientScreen
                );
              },
              child: Text('Client'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MDUserScreen(role: role)), // Navigasi ke MDUserScreen
                );
              },
              child: Text('User'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MDAdminScreen(role: role)), // Navigasi ke MDAdminScreen
                );
              },
              child: Text('Admin'),
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
