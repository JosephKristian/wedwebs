import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:wedweb/screens/master_data/md_guest_screen.dart';
import '../../services/database_helper.dart';

class MDEventScreen extends StatefulWidget {
  final String role;
  final String clientName;
  final int clientId;

  MDEventScreen({required this.role, required this.clientName, required this.clientId});

  @override
  _MDEventScreenState createState() => _MDEventScreenState();
}

class _MDEventScreenState extends State<MDEventScreen> {
  late Future<List<Map<String, dynamic>>> _eventsFuture;
  final log = Logger('MDEventScreen');
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredEvents = [];

  @override
  void initState() {
    super.initState();
    _fetchEventData();
  }

  Future<void> _fetchEventData() async {
    _eventsFuture = DatabaseHelper.instance.getEventsByClientId(widget.clientId);
  }

  void _filterEvents(String query) {
    List<Map<String, dynamic>> filteredList = [];
    if (query.isNotEmpty) {
      filteredList = filteredEvents.where((event) {
        String eventName = event['event_name'].toString().toLowerCase();
        return eventName.contains(query.toLowerCase());
      }).toList();
    } else {
      filteredList = filteredEvents;
    }
    setState(() {
      // Update the state with filtered events
      filteredEvents = filteredList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Events List for ${widget.clientName}'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: EventSearch(filteredEvents));
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: _eventsFuture,
        builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error fetching data'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No data available'));
          } else {
            // Organize data into a map where each event has its sessions and tables
            Map<int, Map<String, dynamic>> eventMap = {};
            snapshot.data!.forEach((event) {
              int eventId = event['event_id'];
              if (!eventMap.containsKey(eventId)) {
                eventMap[eventId] = {
                  'event_id': eventId, // Ensure event_id is included
                  'event_name': event['event_name'],
                  'date': event['date'],
                  'sessions': <Map<String, dynamic>>[],
                };
              }
              bool sessionExists = eventMap[eventId]!['sessions'].any((session) =>
                  session['session_name'] == event['session_name'] &&
                  session['time'] == event['time'] &&
                  session['location'] == event['location']);

              if (!sessionExists) {
                eventMap[eventId]!['sessions'].add({
                  'session_name': event['session_name'],
                  'time': event['time'],
                  'location': event['location'],
                  'tables': <Map<String, dynamic>>[],
                });
              }

              if (event['table_name'] != null) {
                eventMap[eventId]!['sessions'].last['tables'].add({
                  'table_name': event['table_name'],
                  'seat': event['seat'],
                });
              }
            });

            // Assign filtered events for search
            filteredEvents = eventMap.values.toList();

            return ListView.builder(
              itemCount: filteredEvents.length,
              itemBuilder: (context, index) {
                var event = filteredEvents[index];
                return Card(
                  margin: EdgeInsets.all(8),
                  child: InkWell(
                    onTap: () {
                      // Navigate to MDGuestScreen and pass event_id and event_name
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MDGuestScreen(
                            eventId: event['event_id'],
                            eventName: event['event_name'], // Send event_name
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            event['event_name'],
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Date: ${event['date']}'),
                        ),
                        SizedBox(height: 8),
                        ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: event['sessions'].length,
                          itemBuilder: (context, sessionIndex) {
                            var session = event['sessions'][sessionIndex];
                            return ListTile(
                              title: Text('Session: ${session['session_name']}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Time: ${session['time']}'),
                                  Text('Location: ${session['location']}'),
                                  if (session['tables'].isEmpty)
                                    Text('Tables: None')
                                  else
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: session['tables'].map<Widget>((table) {
                                        return Text('Table: ${table['table_name']} (${table['seat']} seats)');
                                      }).toList(),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class EventSearch extends SearchDelegate<Map<String, dynamic>> {
  final List<Map<String, dynamic>> events;

  EventSearch(this.events);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, {});
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Implement buildResults to display search results
    List<Map<String, dynamic>> filteredList = events.where((event) {
      String eventName = event['event_name'].toString().toLowerCase();
      return eventName.contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        var event = filteredList[index];
        return ListTile(
          title: Text(event['event_name']),
          subtitle: Text('Date: ${event['date']}'),
          onTap: () {
            close(context, event);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Implement buildSuggestions to display suggestions
    List<Map<String, dynamic>> suggestionList = events.where((event) {
      String eventName = event['event_name'].toString().toLowerCase();
      return eventName.contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (context, index) {
        var event = suggestionList[index];
        return ListTile(
          title: Text(event['event_name']),
          subtitle: Text('Date: ${event['date']}'),
          onTap: () {
            query = event['event_name'].toString();
          },
        );
      },
    );
  }
}
