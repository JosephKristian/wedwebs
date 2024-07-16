import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../services/database_helper.dart';
import '../services/auth_service.dart';
import 'login_screen.dart'; 
import 'dashboard_f_user_screen.dart';
import '../models/client_model.dart';
// import 'printer_screen.dart'; // Import halaman SettingScreen

class DashboardUserScreen extends StatefulWidget {
  final String role;

  DashboardUserScreen({required this.role});

  @override
  _DashboardUserScreenState createState() => _DashboardUserScreenState();
}

class _DashboardUserScreenState extends State<DashboardUserScreen> {
  final log = Logger('DashboardUserScreen');
  List<Client> clients = [];
  bool isLoading = true;
  Client? selectedClient;

  @override
  void initState() {
    super.initState();
    _fetchClients();
  }

  Future<void> _fetchClients() async {
    try {
      final data = await DatabaseHelper.instance.getClients();
      if (mounted) {
        setState(() {
          clients = data;
          isLoading = false;
        });
      }
    } catch (e) {
      log.severe('Error fetching clients: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _navigateToDashboardFUserScreen(Client client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardFUserScreen(role: widget.role, clientId: client.client_id!, clientName: client.name),
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Dashboard User'),
      automaticallyImplyLeading: false, // Nonaktifkan tombol back otomatis
      actions: [
        IconButton(
          icon: Icon(Icons.logout),
          onPressed: () {
            _logout(context);
          },
        ),
      ],
    ),
    drawer: Drawer(
      child: ListView(
        children: <Widget>[
          // ListTile(
          //   leading: Icon(Icons.bluetooth),
          //   title: Text('Printer'),
          //   onTap: () {
          //     Navigator.pop(context); // Tutup Drawer sebelum navigasi
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => SettingScreen()),
          //     );
          //   },
          // ),
          // Tambahkan item drawer lain jika diperlukan
        ],
      ),
    ),
    body: isLoading
        ? Center(child: CircularProgressIndicator())
        : clients.isEmpty
            ? Center(child: Text('No clients available'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Autocomplete<Client>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      return clients.where((Client client) {
                        return client.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      }).toList();
                    },
                    onSelected: (Client client) {
                      setState(() {
                        selectedClient = client;
                      });
                      _navigateToDashboardFUserScreen(client);
                    },
                    displayStringForOption: (Client client) => client.name,
                    fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                      return TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        onChanged: (String value) {
                          // Implementasi logika pencarian/filter client di sini jika diperlukan
                        },
                        decoration: InputDecoration(
                          labelText: 'Search client name',
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: clients.length,
                      itemBuilder: (context, index) {
                        final client = clients[index];
                        return ListTile(
                          title: Text(client.name),
                          onTap: () => _navigateToDashboardFUserScreen(client),
                        );
                      },
                    ),
                  ),
                ],
              ),
  );
}

  void _logout(BuildContext context) async {
    try {
      log.info('Logging out');
      AuthService authService = AuthService();
      await authService.logout();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      log.severe('Error logging out: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Error logging out: $e'),
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
