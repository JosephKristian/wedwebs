import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../../services/database_helper.dart';
import 'insert_md_guest_screen.dart';

class MDGuestScreen extends StatefulWidget {
  final int eventId;
  final String eventName;

  MDGuestScreen({required this.eventId, required this.eventName});

  @override
  _MDGuestScreenState createState() => _MDGuestScreenState();
}

class _MDGuestScreenState extends State<MDGuestScreen> {
  late Future<List<Map<String, dynamic>>> _guestsFuture;
  final log = Logger('MDGuestScreen');
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredGuests = [];

  @override
  void initState() {
    super.initState();
    _fetchGuestData();
  }

  Future<void> _fetchGuestData() async {
    setState(() {
      _guestsFuture = DatabaseHelper.instance.getGuestsByEventId(widget.eventId);
    });
  }

  void _filterGuests(String query) {
    List<Map<String, dynamic>> filteredList = [];
    if (query.isNotEmpty) {
      filteredList = filteredGuests.where((guest) {
        String guestName = guest['name'].toString().toLowerCase();
        return guestName.contains(query.toLowerCase());
      }).toList();
    } else {
      filteredList = filteredGuests;
    }
    setState(() {
      filteredGuests = filteredList;
    });
  }

  void _addGuest() async {
    // Navigate to InsertMDGuestScreen and wait for result
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InsertMDGuestScreen(
          onInsert: _fetchGuestData,
          eventId: widget.eventId,
        ),
      ),
    );
    if (result != null && result) {
      _fetchGuestData(); // Refresh guest list on successful add
    }
  }

  void _editGuest(Map<String, dynamic> guest) async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => InsertMDGuestScreen(
        onInsert: _fetchGuestData,
        eventId: widget.eventId,
        guestData: guest,
      ),
    ),
  );
  if (result != null && result) {
    _fetchGuestData(); // Refresh guest list on successful edit
  } else {
    _fetchGuestData(); // Refresh guest list if edit is canceled
  }
}

  void _deleteGuest(int guestId) async {
    // Konfirmasi sebelum menghapus
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi'),
        content: Text('Apakah Anda yakin ingin menghapus tamu ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Batal
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Hapus
            child: Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      await DatabaseHelper.instance.deleteGuest(guestId);
      await DatabaseHelper.instance.deleteCheckInByGuestId(guestId);
      _fetchGuestData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Guest deleted successfully')),
      );
    } else {
      // Jika pengguna membatalkan, refresh data tamu juga
      _fetchGuestData();
    }
  }


  void _viewGuestDetails(Map<String, dynamic> guest) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuestDetailScreen(guest: guest),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Guests for Event ${widget.eventName}'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: GuestSearch(filteredGuests));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addGuest,
        child: Icon(Icons.add),
      ),
      body: FutureBuilder(
        future: _guestsFuture,
        builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error fetching data'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No guests available'));
          } else {
            filteredGuests = snapshot.data!.toSet().toList(); // Ensure unique guests

            return ListView.builder(
              itemCount: filteredGuests.length,
              itemBuilder: (context, index) {
                var guest = filteredGuests[index];
                return Dismissible(
                  key: Key(guest['guest_id'].toString()),
                  background: Container(color: Colors.blue, child: Icon(Icons.edit, color: Colors.white)),
                  secondaryBackground: Container(color: Colors.red, child: Icon(Icons.delete, color: Colors.white)),
                  onDismissed: (direction) {
                    if (direction == DismissDirection.startToEnd) {
                      _editGuest(guest);
                    } else {
                      _deleteGuest(guest['guest_id']);
                    }
                  },
                  child: Card(
                    margin: EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(guest['name']),
                      subtitle: Text('Email: ${guest['email']}'),
                      onTap: () {
                        _viewGuestDetails(guest);
                      },
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

  void _handleGuestSelection(Map<String, dynamic> guest) async {
    // Add guest to check_in table for each session related to event_id
    List<Map<String, dynamic>> sessions = await DatabaseHelper.instance.getSessionsByEventId(widget.eventId);
    if (sessions.isNotEmpty) {
      sessions.forEach((session) async {
        int sessionId = session['session_id'];
        int guestId = guest['guest_id'];
        await DatabaseHelper.instance.addCheckIn(sessionId, guestId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Guest added to check-in for all sessions')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No sessions found for this event')),
      );
    }
  }
}

class GuestDetailScreen extends StatelessWidget {
  final Map<String, dynamic> guest;

  GuestDetailScreen({required this.guest});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Guest Details'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${guest['name']}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Email: ${guest['email']}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Phone: ${guest['phone']}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Pax: ${guest['pax']}', style: TextStyle(fontSize: 18)),
            // Add other guest details here
          ],
        ),
      ),
    );
  }
}

class GuestSearch extends SearchDelegate<Map<String, dynamic>> {
  final List<Map<String, dynamic>> guests;

  GuestSearch(this.guests);

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
        close(context, Map<String, dynamic>());
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    List<Map<String, dynamic>> filteredList = guests.where((guest) {
      String guestName = guest['name'].toString().toLowerCase();
      return guestName.contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        var guest = filteredList[index];
        return ListTile(
          title: Text(guest['name']),
          subtitle: Text('Email: ${guest['email']}'),
          onTap: () {
            close(context, guest);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<Map<String, dynamic>> suggestionList = guests.where((guest) {
      String guestName = guest['name'].toString().toLowerCase();
      return guestName.contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (context, index) {
        var guest = suggestionList[index];
        return ListTile(
          title: Text(guest['name']),
          subtitle: Text('Email: ${guest['email']}'),
          onTap: () {
            query = guest['name'].toString();
          },
        );
      },
    );
  }
}
