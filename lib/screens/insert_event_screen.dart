import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/database_helper.dart';

class InsertEventScreen extends StatefulWidget {
  @override
  _InsertEventScreenState createState() => _InsertEventScreenState();
}

class _InsertEventScreenState extends State<InsertEventScreen> {
  final _formKey = GlobalKey<FormState>();
  String _eventName = '';
  int _clientId = 0;
  int _sessionCount = 1;
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> _clients = [];
  List<TextEditingController> _sessionNameControllers = [];
  List<List<TextEditingController>> _tableControllers = [];
  int _tableCount = 2; // Default number of tables
  List<int> _sessionIds = []; // List to store session IDs

  @override
  void initState() {
    super.initState();
    _loadClients();
    _sessions = List.generate(4, (index) => {
      'session_name': '',
      'time': TimeOfDay.now(),
      'location': '',
      'table_enabled': false,
      'tables': List.generate(_tableCount, (i) => {'table_name': String.fromCharCode('A'.codeUnitAt(0) + i), 'seat': 0}),
    });
    _sessionNameControllers = List.generate(4, (index) => TextEditingController());
    _tableControllers = List.generate(4, (index) => List.generate(_tableCount, (i) => TextEditingController()));
  }

  @override
  void dispose() {
    _sessionNameControllers.forEach((controller) => controller.dispose());
    _tableControllers.forEach((list) => list.forEach((controller) => controller.dispose()));
    super.dispose();
  }

  Future<void> _loadClients() async {
    List<Map<String, dynamic>> clients = await DatabaseHelper.instance.getClient();
    setState(() {
      _clients = clients;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Event'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper.instance.getClient(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No clients found.'));
          } else {
            final clients = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        initialValue: _eventName,
                        decoration: InputDecoration(labelText: 'Event Name'),
                        onSaved: (value) => _eventName = value!,
                        onChanged: (value) {
                          _eventName = value; // Update eventName on change
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter event name';
                          }
                          return null;
                        },
                      ),
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(labelText: 'Client'),
                        value: _clientId != 0 ? _clientId : null,
                        items: clients.map((client) {
                          return DropdownMenuItem<int>(
                            value: client['client_id'],
                            child: Text(client['name']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _clientId = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value == 0) {
                            return 'Please select a client';
                          }
                          return null;
                        },
                      ),
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(labelText: 'Number of Sessions'),
                        value: _sessionCount,
                        items: List.generate(4, (index) {
                          return DropdownMenuItem<int>(
                            value: index + 1,
                            child: Text((index + 1).toString()),
                          );
                        }),
                        onChanged: (value) {
                          setState(() {
                            _sessionCount = value!;
                            _sessions = List.generate(_sessionCount, (index) => {
                              'session_name': '',
                              'time': TimeOfDay.now(),
                              'location': '',
                              'table_enabled': false,
                              'tables': List.generate(_tableCount, (i) => {'table_name': String.fromCharCode('A'.codeUnitAt(0) + i), 'seat': 0}),
                            });
                            _sessionNameControllers = List.generate(_sessionCount, (index) => TextEditingController());
                            _tableControllers = List.generate(_sessionCount, (index) =>
                                List.generate(_tableCount, (i) => TextEditingController()));
                          });
                        },
                      ),
                      if (_sessionCount > 0) ...[
                        DropdownButtonFormField<int>(
                          decoration: InputDecoration(labelText: 'Number of Tables'),
                          value: _tableCount,
                          items: List.generate(5, (index) {
                            return DropdownMenuItem<int>(
                              value: index + 1,
                              child: Text((index + 1).toString()),
                            );
                          }),
                          onChanged: (value) {
                            setState(() {
                              _tableCount = value!;
                              // Reset sessions with new table count
                              _sessions.forEach((session) {
                                session['tables'] = List.generate(_tableCount, (i) =>
                                    {'table_name': String.fromCharCode('A'.codeUnitAt(0) + i), 'seat': 0});
                              });
                              // Reset table controllers
                              _tableControllers = List.generate(_sessionCount, (index) =>
                                  List.generate(_tableCount, (i) => TextEditingController()));
                            });
                          },
                        ),
                      ],
                      ...List.generate(_sessionCount, (sessionIndex) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _sessionNameControllers[sessionIndex],
                              decoration: InputDecoration(labelText: 'Session ${sessionIndex + 1} Name'),
                              onChanged: (value) {
                                _sessions[sessionIndex]['session_name'] = value;
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter session name';
                                }
                                return null;
                              },
                            ),
                            Row(
                              children: [
                                Text('Session ${sessionIndex + 1} Time:'),
                                SizedBox(width: 10),
                                IconButton(
                                  icon: Icon(Icons.access_time),
                                  onPressed: () async {
                                    TimeOfDay? selectedTime = await showTimePicker(
                                      context: context,
                                      initialTime: _sessions[sessionIndex]['time'],
                                    );
                                    if (selectedTime != null) {
                                      setState(() {
                                        _sessions[sessionIndex]['time'] = selectedTime;
                                      });
                                    }
                                  },
                                ),
                                Text(_sessions[sessionIndex]['time'].format(context)),
                              ],
                            ),
                            TextFormField(
                              initialValue: _sessions[sessionIndex]['location'],
                              decoration: InputDecoration(labelText: 'Session ${sessionIndex + 1} Location'),
                              onChanged: (value) {
                                _sessions[sessionIndex]['location'] = value;
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter session location';
                                }
                                return null;
                              },
                            ),
                            Row(
                              children: [
                                Text('Use Table for Session ${sessionIndex + 1}'),
                                Switch(
                                  value: _sessions[sessionIndex]['table_enabled'],
                                  onChanged: (value) {
                                    setState(() {
                                      _sessions[sessionIndex]['table_enabled'] = value;
                                      if (!value) {
                                        // Clear table data if disabled
                                        _sessions[sessionIndex]['tables'].forEach((table) {
                                          table['seat'] = 0;
                                        });
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                            if (_sessions[sessionIndex]['table_enabled']) ...[
                              ...List.generate(
                                _tableCount,
                                (tableIndex) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      TextFormField(
                                        controller: _tableControllers[sessionIndex][tableIndex],
                                        decoration: InputDecoration(labelText: 'Table ${String.fromCharCode('A'.codeUnitAt(0) + tableIndex)} Seat'),
                                        keyboardType: TextInputType.numberWithOptions(decimal: false, signed: false),
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        onChanged: (value) {
                                          try {
                                            _sessions[sessionIndex]['tables'][tableIndex]['seat'] = int.parse(value);
                                          } catch (e) {
                                            // Jika nilai tidak dapat di-parse sebagai integer, set nilai seat ke 0 atau tampilkan pesan error
                                            _sessions[sessionIndex]['tables'][tableIndex]['seat'] = 0;
                                            // Opsional: Tampilkan pesan error ke pengguna
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Please enter a valid number for seats')),
                                            );
                                          }
                                        },

                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter seat number';
                                          }
                                          if (int.tryParse(value) == null) {
                                            return 'Please enter a valid number';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                            SizedBox(height: 10),
                          ],
                        );
                      }).toList(),
                      Row(
                        children: [
                          Icon(Icons.calendar_today),
                          SizedBox(width: 10),
                          Text('Event Date: ${_selectedDate.toLocal()}'.split(' ')[0]),
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2101),
                              );
                              if (pickedDate != null && pickedDate != _selectedDate)
                                setState(() {
                                  _selectedDate = pickedDate;
                                });
                            },
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();

                            // Insert event into the database
                            int eventId = await DatabaseHelper.instance.insertEvent({
                              'event_name': _eventName,
                              'client_id': _clientId,
                              'date': _selectedDate.toIso8601String(),
                            });

                            // Insert sessions into the database and store session IDs
                            _sessionIds = [];
                            for (int i = 0; i < _sessionCount; i++) {
                              int sessionId = await DatabaseHelper.instance.insertSession({
                                'event_id': eventId,
                                'session_name': _sessions[i]['session_name'],
                                'time': _sessions[i]['time'].format(context),
                                'location': _sessions[i]['location'],
                              });
                              _sessionIds.add(sessionId);

                              if (_sessions[i]['table_enabled']) {
                                for (var table in _sessions[i]['tables']) {
                                  await DatabaseHelper.instance.insertTable({
                                    'session_id': sessionId,
                                    'table_name': table['table_name'],
                                    'seat': table['seat'],
                                  });
                                }
                              }
                            }

                            // Handle session IDs as needed
                            // For example, print the session IDs
                            print('Session IDs: $_sessionIds');

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Event and sessions saved')),
                            );
                            Navigator.pop(context);
                          }
                        },
                        child: Text('Save Event'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
