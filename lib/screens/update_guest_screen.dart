import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/guest_model.dart';
import '../models/client_model.dart';
import '../models/event_model.dart';
import '../models/session_model.dart';
import '../models/check_in_model.dart';
import '../services/database_helper.dart';
import 'print_screen.dart'; // import PrintScreen untuk navigasi

class UpdateGuestScreen extends StatefulWidget {
  final int guestId;

  UpdateGuestScreen({required this.guestId});

  @override
  _UpdateGuestScreenState createState() => _UpdateGuestScreenState();
}

class _UpdateGuestScreenState extends State<UpdateGuestScreen> {
  Guest? _guest;
  Client? _client;
  List<Event> _events = [];
  Event? _selectedEvent;
  List<Session> _sessions = [];
  Session? _selectedSession;
  CheckIn? _checkIn;
  final _formKey = GlobalKey<FormState>();
  late Future<void> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchGuestDetails();
  }

  Future<void> _fetchGuestDetails() async {
    final dbHelper = DatabaseHelper.instance;
    _guest = await dbHelper.getGuestById(widget.guestId);
    if (_guest != null) {
      _client = await dbHelper.getClientById(_guest!.clientId);
      Set<Event> eventSet = (await dbHelper.getEventsUseClientId(_guest!.clientId)).toSet();
      _events = eventSet.toList();
      _checkIn = await dbHelper.getCheckInByGuestId(widget.guestId);
      if (_checkIn != null) {
        _selectedEvent = await dbHelper.getEventById(_checkIn!.sessionId);
        if (_selectedEvent != null && _events.contains(_selectedEvent)) {
          _selectedEvent = _events.firstWhere((event) => event.eventId == _selectedEvent!.eventId);
          _sessions = await dbHelper.getSessionsForEvent(_selectedEvent!.eventId);
          _selectedSession = await dbHelper.getSessionById(_checkIn!.sessionId);
        } else {
          _selectedEvent = null;
          _sessions = [];
          _selectedSession = null;
        }
      }
    }
    setState(() {}); // Untuk merender ulang UI setelah data di-fetch
  }

  Future<void> _updateCheckIn() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final dbHelper = DatabaseHelper.instance;
      if (_checkIn != null && _selectedSession != null) {
        // Update data CheckIn
        _checkIn!.sessionId = _selectedSession!.sessionId!; // Menggunakan id session terpilih
        try {
          await dbHelper.updateCheckIn(_checkIn!);
          // Navigasi ke PrintScreen setelah berhasil update
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PrintScreen(
                guestId: widget.guestId,
                guestBeforeUpdate: _guest,
                eventUpdate: _selectedEvent,
                sessionUpdate: _selectedSession,
                client: _client,
                updatedCheckIn: _checkIn,
              ),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An error occurred: $e'),
            ),
          );
        }
      }
    }
  }

  Future<void> _fetchSessionsForEvent(int eventId) async {
    final dbHelper = DatabaseHelper.instance;
    _sessions = await dbHelper.getSessionsForEventinqr(eventId,widget.guestId);
    setState(() {
      _selectedSession = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else {
          return Scaffold(
            appBar: AppBar(
              title: Text('Update Guest'),
            ),
            body: Padding(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    if (_client != null) Text('Client Name: ${_client!.name}'),
                    SizedBox(height: 16),
                    if (_guest != null)
                      QrImageView(
                        data: _guest!.guest_qr!,
                        size: 100,
                      ),
                    SizedBox(height: 16),
                    if (_guest != null) Text('Guest Name: ${_guest!.name}'),
                    SizedBox(height: 16),
                    if (_guest != null) Text('Category: ${_guest!.cat}'),
                    SizedBox(height: 16),
                    DropdownButtonFormField<Event>(
                      decoration: InputDecoration(labelText: 'Event'),
                      value: _selectedEvent,
                      items: _events.map((event) {
                        return DropdownMenuItem<Event>(
                          value: event,
                          child: Text(event.eventName),
                        );
                      }).toList(),
                      onChanged: (Event? newValue) {
                        setState(() {
                          _selectedEvent = newValue;
                          if (newValue != null) {
                            _fetchSessionsForEvent(newValue.eventId);
                          }
                        });
                      },
                      validator: (value) => value == null ? 'Please select an event' : null,
                    ),
                    if (_selectedEvent != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 16),
                          Text('Date: ${_selectedEvent!.date}'),
                          SizedBox(height: 16),
                        ],
                      ),
                    DropdownButtonFormField<Session>(
                      decoration: InputDecoration(labelText: 'Session'),
                      value: _selectedSession,
                      items: _sessions.map((session) {
                        return DropdownMenuItem<Session>(
                          value: session,
                          child: Text(session.sessionName),
                        );
                      }).toList(),
                      onChanged: (Session? newValue) {
                        setState(() {
                          _selectedSession = newValue;
                        });
                      },
                      validator: (value) => value == null ? 'Please select a session' : null,
                    ),
                    if (_selectedSession != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 16),
                          Text('Time: ${_selectedSession!.time}'),
                          SizedBox(height: 16),
                        ],
                      ),
                    TextFormField(
                      initialValue: _checkIn?.souvenir,
                      decoration: InputDecoration(labelText: 'Souvenir'),
                      onSaved: (value) {
                        _checkIn?.souvenir = value!;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      initialValue: _checkIn?.angpau?.toString(),
                      decoration: InputDecoration(labelText: 'Angpau'),
                      keyboardType: TextInputType.number,
                      onSaved: (value) {
                        _checkIn?.angpau = int.parse(value!);
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      initialValue: _guest!.pax.toString(),
                      decoration: InputDecoration(labelText: 'Pax'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter pax';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _checkIn?.paxChecked = int.parse(value!);
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      initialValue: _checkIn?.meals,
                      decoration: InputDecoration(labelText: 'Meals'),
                      onSaved: (value) {
                        _checkIn?.meals = value!;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      initialValue: _checkIn?.note,
                      decoration: InputDecoration(labelText: 'Note'),
                      onSaved: (value) {
                        _checkIn?.note = value!;
                      },
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _updateCheckIn,
                      child: Text('Update'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
