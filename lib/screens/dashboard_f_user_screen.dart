import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'scan_qr_screen.dart'; // Adjust according to the path of scan_qr_screen.dart

class DashboardFUserScreen extends StatelessWidget {
  final String role;
  final int clientId; // Add client ID
  final String clientName;

  final log = Logger('DashboardFUserScreen');

  DashboardFUserScreen({required this.role, required this.clientId, required this.clientName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Client $clientName'), // Access clientName directly
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code),
            onPressed: () {
              _navigateToScanQRScreen(context, clientId, role);
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              _logout(context);
            },
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'Widget Kosong',
            style: TextStyle(fontSize: 20.0),
          ),
        ),
      ),
    );
  }

  void _navigateToScanQRScreen(BuildContext context, int clientId, String role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanQRScreen(clientId: clientId, role: role,), // Ensure clientId matches the named parameter in ScanQRScreen
      ),
    );
  }

  void _logout(BuildContext context) async {
    // Implement logout as before
  }
}
