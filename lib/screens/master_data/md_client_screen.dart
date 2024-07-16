import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../../services/database_helper.dart';
import '../../models/client_model.dart';
import 'md_event_screen.dart';
import 'insert_md_client_screen.dart';
import 'update_md_client_screen.dart';

class MDClientScreen extends StatefulWidget {
  final String role;

  MDClientScreen({required this.role});

  @override
  _MDClientScreenState createState() => _MDClientScreenState();
}

class _MDClientScreenState extends State<MDClientScreen> {
  final log = Logger('MDClientScreen');
  late Future<List<Client>> _clientsFuture;
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _refreshClients();
  }

  Future<void> _refreshClients() async {
    setState(() {
      _clientsFuture = DatabaseHelper.instance.getClients().then((clients) {
        return clients.where((client) {
          if (_selectedFilter != 'All' && client.client_id != _selectedFilter) {
            return false;
          }
          if (_searchQuery.isNotEmpty &&
              !client.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
              !client.email.toLowerCase().contains(_searchQuery.toLowerCase())) {
            return false;
          }
          return true;
        }).toList();
      });
    });
  }

  void _editClient(BuildContext context, Client client) {
    log.info('Edit client: ${client.name}');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return UpdateMDClientScreen(
          client: client,
          onUpdate: _refreshClients,
        );
      },
    );
  }

  void _deleteClient(BuildContext context, Client client) {
    log.info('Delete client: ${client.name}');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi'),
          content: Text('Apakah Anda yakin ingin menghapus client ini?'),
          actions: <Widget>[
            TextButton(
              child: Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Hapus'),
              onPressed: () async {
                Navigator.of(context).pop();

                try {
                  await DatabaseHelper.instance.deleteClient(client.client_id!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Client ${client.name} berhasil dihapus.'),
                    ),
                  );
                  _refreshClients();
                } catch (e) {
                  log.severe('Terjadi kesalahan saat menghapus client: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus client ${client.name}.'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _viewGuests(BuildContext context, Client client) {
    log.info('View guests of client: ${client.name}');
    if (client.client_id != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MDEventScreen(role: widget.role, clientName: client.name, clientId: client.client_id!)),
      );
    } else {
      log.warning('Client ID is null for client: ${client.name}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Client ID is null for client ${client.name}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Client List'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return InsertMDClientScreen(
                    onInsert: _refreshClients,
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _refreshClients();
                      });
                    },
                  ),
                ),
                SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedFilter,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedFilter = newValue!;
                      _refreshClients();
                    });
                  },
                  items: <String>['All', 'Format A', 'Format B', 'Format C', 'Format D', 'Format E']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Client>>(
              future: _clientsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No data available'));
                } else {
                  List<Client> clients = snapshot.data!;
                  return _buildClientTable(context, clients);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientTable(BuildContext context, List<Client> clients) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columns: [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Phone')),
            DataColumn(label: Text('Actions')),
          ],
          rows: clients
              .map(
                (client) => DataRow(
                  cells: [
                    DataCell(Text(client.name)),
                    DataCell(Text(client.email ?? '-')),
                    DataCell(Text(client.phone ?? '-')),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              _editClient(context, client);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              _deleteClient(context, client);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.person),
                            onPressed: () {
                              _viewGuests(context, client);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
