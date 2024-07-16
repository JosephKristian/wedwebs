import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import 'insert_event_screen.dart';

class EventScreen extends StatefulWidget {
  @override
  _EventScreenState createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  late Future<List<Map<String, dynamic>>> _eventSessions;
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredData = [];

  @override
  void initState() {
    super.initState();
    _fetchEventSessions();
  }

  void _fetchEventSessions() {
    _eventSessions = DatabaseHelper.instance.getEventSessions();
    _eventSessions.then((data) {
      setState(() {
        _filteredData = data;
      });
    });
  }


  void _filterData(String query) {
    final data = _filteredData.where((row) {
      final sessionName = row['session_name']?.toLowerCase() ?? '';
      final eventName = row['event_name']?.toLowerCase() ?? '';
      final clientName = row['client_name']?.toLowerCase() ?? '';
      final tableName = row['table_name']?.toLowerCase() ?? '';
      return sessionName.contains(query) ||
          eventName.contains(query) ||
          clientName.contains(query) ||
          tableName.contains(query);
    }).toList();

    setState(() {
      _filteredData = data;
    });
  }

  void _restoreOriginalData() {
    _fetchEventSessions(); // Refresh data from database
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event Sessions'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => InsertEventScreen()),
              );
              _fetchEventSessions(); // Refresh data after adding event
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (query) {
                _filterData(query.toLowerCase());
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _eventSessions,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No sessions found.'));
                } else {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('Session Name')),
                          DataColumn(label: Text('Time')),
                          DataColumn(label: Text('Location')),
                          DataColumn(label: Text('Event Name')),
                          DataColumn(label: Text('Client Name')),
                          DataColumn(label: Text('Table Name')),
                        ],
                        rows: _filteredData.map((row) {
                          return DataRow(cells: [
                            DataCell(Text(row['session_name'])),
                            DataCell(Text(row['time'])),
                            DataCell(Text(row['location'])),
                            DataCell(Text(row['event_name'])),
                            DataCell(Text(row['client_name'])),
                            DataCell(Text(row['table_name'] ?? 'none')),
                          ]);
                        }).toList(),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
