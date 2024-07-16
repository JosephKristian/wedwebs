import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/check_in_model.dart';
import '../models/client_model.dart';
import '../models/event_model.dart';
import '../models/guest_model.dart';
import '../models/session_model.dart';
import '../models/table_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;
  final log = Logger('DatabaseHelper');

  DatabaseHelper._internal();

  static DatabaseHelper get instance => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final path = await getDatabasePath('digital_guestbook.db');
      log.info('Database path: $path');

      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
    } catch (e) {
      log.severe('Error initializing database: $e');
      rethrow;
    }
  }

  Future<String> getDatabasePath(String dbName) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, dbName);
    return path;
  }

  Future<void> _onCreate(Database db, int version) async {
    log.info('Creating tables...');
    try {
      await db.execute('''
        CREATE TABLE Users (
          user_id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          email TEXT NOT NULL UNIQUE,
          email_verified_at TEXT,        
          password TEXT NOT NULL,
          role TEXT NOT NULL,
          remember_token TEXT,
          created_at TEXT DEFAULT (datetime('now', 'localtime')),
          updated_at TEXT DEFAULT (datetime('now', 'localtime'))
        )
      ''');
      log.info('Table "Users" created successfully');

      await db.execute('''
        CREATE TABLE Client (
          client_id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          email TEXT NOT NULL,
          phone TEXT,
          FOREIGN KEY (user_id) REFERENCES Users(user_id)
        )
      ''');
      log.info('Table "Client" created successfully');

      await db.execute('''
        CREATE TABLE Guest (
          guest_id INTEGER PRIMARY KEY AUTOINCREMENT,
          client_id INTEGER NOT NULL,
          guest_qr TEXT NOT NULL UNIQUE,
          name TEXT NOT NULL,
          email TEXT,
          phone TEXT,
          pax INTEGER DEFAULT 1,
          rsvp TEXT DEFAULT 'pending',
          cat TEXT DEFAULT 'regular',
          FOREIGN KEY (client_id) REFERENCES Client(client_id)
        )
      ''');
      log.info('Table "Guest" created successfully');

      await db.execute('''
        CREATE TABLE Event (
          event_id INTEGER PRIMARY KEY AUTOINCREMENT,
          client_id INTEGER NOT NULL,
          event_name TEXT NOT NULL,
          date DATE NOT NULL,
          FOREIGN KEY (client_id) REFERENCES Client(client_id)
        )
      ''');
      log.info('Table "Event" created successfully');

      await db.execute('''
        CREATE TABLE Session (
          session_id INTEGER PRIMARY KEY AUTOINCREMENT,
          event_id INTEGER NOT NULL,
          session_name TEXT NOT NULL,
          time TEXT NOT NULL,
          location TEXT NOT NULL,
          FOREIGN KEY (event_id) REFERENCES Event(event_id)
        )
      ''');
      log.info('Table "Session" created successfully');

      await db.execute('''
        CREATE TABLE 'Table' (
          table_id INTEGER PRIMARY KEY AUTOINCREMENT,
          session_id INTEGER NOT NULL,
          table_name TEXT NOT NULL,
          seat INTEGER NOT NULL,
          FOREIGN KEY (session_id) REFERENCES Session(session_id)
        )
      ''');
      log.info('Table "Table" created successfully');

      await db.execute('''
        CREATE TABLE Check_in (
          session_id INTEGER NOT NULL,
          guest_id INTEGER NOT NULL,
          souvenir TEXT,
          angpau INTEGER,
          pax_checked INTEGER DEFAULT 1,
          meals TEXT,
          note TEXT,
          delivery TEXT DEFAULT 'no',
          guestNo INTEGER DEFAULT 1,
          status TEXT DEFAULT 'not check-in yet',
          PRIMARY KEY (session_id, guest_id),
          FOREIGN KEY (session_id) REFERENCES Session(session_id),
          FOREIGN KEY (guest_id) REFERENCES Guest(guest_id)
        )
      ''');
      log.info('Table "Check_in" created successfully');

      // Insert dummy data for each table
      await _insertDummyData(db);
    } catch (e) {
      log.severe('Error creating tables: $e');
      rethrow;
    }
  }

  Future<void> _insertDummyData(Database db) async {
    try {
      await db.transaction((txn) async {
        Batch batch = txn.batch();

        // Insert dummy Users
        batch.insert('Users', {
          'name': 'User A',
          'email': 'A@mail.com',
          'password': '05f93f4da5c81e0b86c07c191102b598e548e9dfc39e66a6d53f5c87912f5336',
          'role': 'admin',
        });
        batch.insert('Users', {
          'name': 'User B',
          'email': 'B@mail.com',
          'password': '05f93f4da5c81e0b86c07c191102b598e548e9dfc39e66a6d53f5c87912f5336',
          'role': 'user',
        });
        batch.insert('Users', {
          'name': 'User C',
          'email': 'C@mail.com',
          'password': '05f93f4da5c81e0b86c07c191102b598e548e9dfc39e66a6d53f5c87912f5336',
          'role': 'client',
        });

        // Insert dummy Client
        batch.insert('Client', {
          'user_id': 1,
          'name': 'Client A',
          'email': 'clientA@example.com',
          'phone': '123456789',
        });
        batch.insert('Client', {
          'user_id': 2,
          'name': 'Client B',
          'email': 'clientB@example.com',
          'phone': '987654321',
        });
        batch.insert('Client', {
          'user_id': 3,
          'name': 'Client C',
          'email': 'clientC@example.com',
          'phone': '456123789',
        });

        // Insert dummy Guests
        batch.insert('Guest', {
          'client_id': 1,
          'guest_qr': 'dummy_qr_1',
          'name': 'Guest A',
          'email': 'guestA@example.com',
          'phone': '111111111',
          'pax': 2,
          'cat': 'regular',
        });
        batch.insert('Guest', {
          'client_id': 2,
          'guest_qr': 'dummy_qr_2',
          'name': 'Guest B',
          'email': 'guestB@example.com',
          'phone': '222222222',
          'pax': 3,
          'cat': 'VIP',
        });
        batch.insert('Guest', {
          'client_id': 3,
          'guest_qr': 'dummy_qr_3',
          'name': 'Guest C',
          'email': 'guestC@example.com',
          'phone': '333333333',
          'pax': 4,
          'cat': 'VVIP',
        });

        // Insert dummy Events
        batch.insert('Event', {
          'client_id': 1,
          'event_name': 'Event A',
          'date': '2024-07-01',
        });
        batch.insert('Event', {
          'client_id': 2,
          'event_name': 'Event B',
          'date': '2024-07-02',
        });
        batch.insert('Event', {
          'client_id': 3,
          'event_name': 'Event C',
          'date': '2024-07-03',
        });

        // Insert dummy Sessions
        batch.insert('Session', {
          'event_id': 1,
          'session_name': 'Session A',
          'time': '09:00 AM',
          'location': 'Location A',
        });
        batch.insert('Session', {
          'event_id': 2,
          'session_name': 'Session B',
          'time': '11:00 AM',
          'location': 'Location B',
        });
        batch.insert('Session', {
          'event_id': 3,
          'session_name': 'Session C',
          'time': '02:00 PM',
          'location': 'Location C',
        });

        // Insert dummy Tables
        batch.insert('Table', {
          'session_id': 1,
          'table_name': 'Table A',
          'seat': 5,
        });
        batch.insert('Table', {
          'session_id': 2,
          'table_name': 'Table B',
          'seat': 8,
        });
        batch.insert('Table', {
          'session_id': 3,
          'table_name': 'Table C',
          'seat': 6,
        });

        // Insert dummy Check-ins
        batch.insert('Check_in', {
          'session_id': 1,
          'guest_id': 1,
          'souvenir': 'Souvenir A',
          'angpau': 100,
          'pax_checked': 2,
          'meals': 'Meal A',
          'note': 'Note A',
          'delivery': 'yes',
          'guestNo': 2,
          'status': 'not yet check-in',
        });
        batch.insert('Check_in', {
          'session_id': 2,
          'guest_id': 2,
          'souvenir': 'Souvenir B',
          'angpau': 200,
          'pax_checked': 3,
          'meals': 'Meal B',
          'note': 'Note B',
          'delivery': 'no',
          'guestNo': 3,
          'status': 'not yet check-in',
        });
        batch.insert('Check_in', {
          'session_id': 3,
          'guest_id': 3,
          'souvenir': 'Souvenir C',
          'angpau': 300,
          'pax_checked': 4,
          'meals': 'Meal C',
          'note': 'Note C',
          'delivery': 'yes',
          'guestNo': 4,
          'status': 'not yet check-in',
        });

        await batch.commit();
        log.info('Dummy data inserted successfully');
      });
    } catch (e) {
      log.severe('Error inserting dummy data: $e');
      rethrow;
    }
  }

//   Future<void> close() async {
//     final db = await database;
//     db.close();
//   }
// }



  // ___________________________method______________________________________
  // Client

  Future<int> insertClient(Client client) async {
    final db = await database;
    try {
      int clientId = await db.insert('Client', client.toMap());
      log.info('Client inserted successfully with ID: $clientId');
      return clientId;
    } catch (e) {
      log.severe('Failed to insert client: $e');
      throw Exception('Failed to insert client');
    }
  }

  Future<int> updateClient(Client client) async {
    final db = await database;
    try {
      int result = await db.update(
        'Client',
        client.toMap(),
        where: 'client_id = ?',
        whereArgs: [client.client_id],
      );
      log.info('Client updated successfully');
      return result;
    } catch (e) {
      log.severe('Error updating client: $e');
      throw Exception('Failed to update client');
    }
  }


  Future<List<Map<String, dynamic>>> getClient() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query('Client');
    return maps;
  }

  Future<List<Client>> getClients() async {
    final db = await instance.database;
    
    final List<Map<String, dynamic>> maps = await db.query('Client');

    return List.generate(maps.length, (i) {
      return Client(
        client_id: maps[i]['client_id'],
        user_id: maps[i]['user_id'],
        name: maps[i]['name'],
        email: maps[i]['email'],
        phone: maps[i]['phone'],
      );
    });
  }

  Future<void> deleteClient(int clientId) async {
    final db = await instance.database;
    try {
      await db.delete(
        'Client',
        where: 'client_id = ?',
        whereArgs: [clientId],
      );
      log.info('Client deleted successfully');
    } catch (e) {
      log.severe('Error deleting client: $e');
      throw Exception('Failed to delete client');
    }
  }

  // guest
    Future<List<Map<String, dynamic>>> getGuestsByEventId(int eventId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT DISTINCT Guest.*
      FROM Guest
      INNER JOIN Check_in ON Guest.guest_id = Check_in.guest_id
      INNER JOIN Session ON Check_in.session_id = Session.session_id
      WHERE Session.event_id = ?
    ''', [eventId]);
    return result;
  }

  Future<List<Guest>> getGuestsByClientId(int clientId) async {
    final db = await instance.database;

    final result = await db.query(
      'Guest',
      where: 'client_id = ?',
      whereArgs: [clientId],
    );

    return result.map((json) => Guest.fromMap(json)).toList();
  }

  Future<List<Guest>> getGuest() async {
    final db = await instance.database;
    final guestData = await db.query('Guest');

    return guestData.map((json) => Guest.fromMap(json)).toList();
  }

  Future<void> deleteGuest(int id) async {
    final db = await instance.database;
    await db.delete(
      'Guest',
      where: 'guest_id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertGuest(Guest guest) async {
    final db = await instance.database;

    return await db.insert('Guest', guest.toMap());
  }

  Future<int> updateGuest(Guest guest) async {
    final db = await instance.database;

    return await db.update(
      'Guest',
      guest.toMap(),
      where: 'guest_id = ?',
      whereArgs: [guest.guest_id],
    );
  }
// tambahan
  Future<Guest> getGuestById(int guestId) async {
  final db = await database;
  final result = await db.query('Guest', where: 'guest_id = ?', whereArgs: [guestId]);
  return Guest.fromMap(result.first);
}

  Future<Client> getClientById(int clientId) async {
    final db = await database;
    final result = await db.query('Client', where: 'client_id = ?', whereArgs: [clientId]);
    return Client.fromMap(result.first);
  }

  Future<Event> getEventBySessionId(int sessionId) async {
    final db = await database;
    final result = await db.query('Event', where: 'session_id = ?', whereArgs: [sessionId]);
    return Event.fromMap(result.first);
  }

  Future<List<Map<String, dynamic>>> getSessionsByEventId(int eventId) async {
    Database db = await instance.database;
    return await db.query('Session', where: 'event_id = ?', whereArgs: [eventId]);
    }
  Future<List<int>> getSessionIdsByEventId(int eventId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'Session',
      columns: ['session_id'],
      where: 'event_id = ?',
      whereArgs: [eventId],
    );

    List<int> sessionIds = result.map((row) => row['session_id'] as int).toList();
    return sessionIds;
  }

 Future<void> insertCheckIn(int sessionId, int guestId) async {
    final db = await database;
    await db.insert('Check_in', {
      'session_id': sessionId,
      'guest_id': guestId,
      'status': 'not check-in yet',
      // Tambahkan kolom lain sesuai dengan kebutuhan default value
    });
  }

  

  Future<Session> getSessionById(int sessionId) async {
    final db = await database;
    final result = await db.query('Session', where: 'session_id = ?', whereArgs: [sessionId]);
    return Session.fromMap(result.first);
  }

  Future<TableModel> getTableBySessionId(int sessionId) async {
    final db = await database;
    final result = await db.query('Table', where: 'session_id = ?', whereArgs: [sessionId]);
    if (result.isNotEmpty) {
      return TableModel.fromMap(result.first);
    } else {
      return TableModel.empty();
    }
  }

  Future<CheckIn> getCheckInByGuestId(int guestId) async {
    final db = await database;
    final result = await db.query('Check_in', where: 'guest_id = ?', whereArgs: [guestId]);
    return CheckIn.fromMap(result.first);
  }

// Method untuk mendapatkan CheckIn berdasarkan session_id dan guest_id
  Future<CheckIn?> getCheckInBySessionAndGuestId(int sessionId, int guestId) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'Check_in',
      where: 'session_id = ? AND guest_id = ?',
      whereArgs: [sessionId, guestId],
    );
    if (maps.isNotEmpty) {
      return CheckIn.fromMap(maps.first); // Mengembalikan objek CheckIn dari hasil query pertama
    }
    
    return null; // Mengembalikan null jika tidak ada hasil
  }

  Future<List<Session>> getAllSessions() async {
    final db = await database;
    final result = await db.query('Session');
    return result.map((json) => Session.fromMap(json)).toList();
  }

  Future<void> updateCheckIn(CheckIn checkIn) async {
    final db = await database;
    // Update data Check_in
    await db.update(
      'Check_in',
      {
        'session_id': checkIn.sessionId,
        'guest_id': checkIn.guestId,
        'souvenir': checkIn.souvenir,
        'angpau': checkIn.angpau,
        'pax_checked': checkIn.paxChecked,
        'meals': checkIn.meals,
        'note': checkIn.note,
        'delivery': checkIn.delivery,
        'guestNo': checkIn.guestNo,
        'status': 'checked-in', // Update status ke 'checked-in'
      },
      where: 'session_id = ? AND guest_id = ?',
      whereArgs: [checkIn.sessionId, checkIn.guestId],
    );
  }


  Future<List<CheckIn>> getAllCheckIns() async {
    final db = await instance.database;
    final result = await db.query('Check_in');

    return result.map((json) => CheckIn.fromMap(json)).toList();
  }

  Future<Event?> getEventByClientId(int clientId) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      'Event',
      where: 'client_id = ?',
      whereArgs: [clientId],
    );

    if (maps.isNotEmpty) {
      return Event.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Session>> getAvailableSessions(int guestId) async {
  Database db = await instance.database;

  String query = '''
    SELECT s.*
    FROM Session s
    LEFT JOIN Check_in c ON s.session_id = c.session_id AND c.guest_id = ?
    WHERE c.status = 'not check-in yet' AND c.guest_id = ?
  ''';

  List<Map<String, dynamic>> maps = await db.rawQuery(query, [guestId]);

  if (maps.isNotEmpty) {
    return List.generate(maps.length, (i) {
      return Session.fromMap(maps[i]);
    });
  }
  return [];
  }



// join


  Future<int> insertEvent(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('Event', row);
  }

  Future<List<Map<String, dynamic>>> getEventSessions() async {
    Database db = await instance.database;
    return await db.rawQuery('''
      SELECT session.session_name, session.time, session.location, event.event_name, client.name AS client_name, 'table'.table_name 
      FROM session
      JOIN event ON session.event_id = event.event_id
      JOIN client ON event.client_id = client.client_id
      LEFT JOIN 'table' ON session.session_id = 'table'.session_id
    ''');
  }

  Future<List<Map<String, dynamic>>> getEventsByClientId(int clientId) async {
    final db = await database;
    
    // Query untuk mengambil data event, sesi, dan tabel yang terkait
    final result = await db.rawQuery('''
      SELECT 
        e.event_id,
        e.event_name,
        e.date,
        s.session_id,
        s.session_name,
        s.time,
        s.location,
        t.table_id,
        t.table_name,
        t.seat
      FROM Event e
      LEFT JOIN Session s ON e.event_id = s.event_id
      LEFT JOIN 'Table' t ON s.session_id = t.session_id
      WHERE e.client_id = ?
      ORDER BY e.event_id, s.session_id, t.table_id
    ''', [clientId]);
    
    return result;
  }

  // Metode untuk mendapatkan event berdasarkan client_id
  Future<List<Event>> getEventsUseClientId(int clientId) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      'Event',
      where: 'client_id = ?',
      whereArgs: [clientId],
    );

    return List.generate(maps.length, (i) {
      return Event(
        eventId: maps[i]['event_id'],
        clientId: maps[i]['client_id'],
        eventName: maps[i]['event_name'],
        date: maps[i]['date'],
      );
    });
  }


  // Metode untuk mendapatkan sesi berdasarkan event_id
  Future<List<Session>> getSessionsForEventinqr(int eventId, int guestId) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT s.session_id, s.session_name, s.time, s.location
      FROM Session s
      JOIN Check_in ci ON s.session_id = ci.session_id
      WHERE ci.guest_id = ?
        AND ci.status = 'not check-in yet';
    ''', [guestId]);

    return List.generate(maps.length, (i) {
      return Session(
        sessionId: maps[i]['session_id'],
        eventId: eventId, // eventId diambil dari parameter metode
        sessionName: maps[i]['session_name'],
        time: maps[i]['time'],
        location: maps[i]['location'],
      );
    });
  }


// Metode untuk mendapatkan sesi berdasarkan event_id
  Future<List<Session>> getSessionsForEvent(int eventId) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      'Session',
      where: 'event_id = ?',
      whereArgs: [eventId],
    );

    return List.generate(maps.length, (i) {
      return Session(
        sessionId: maps[i]['session_id'],
        eventId: maps[i]['event_id'],
        sessionName: maps[i]['session_name'],
        time: maps[i]['time'],
        location: maps[i]['location'],
      );
    });
  }

   // Metode untuk mendapatkan client_id berdasarkan event_id
  Future<int?> getClientIdByEventId(int eventId) async {
    Database db = await instance.database; // Pastikan database sudah diinisialisasi
    var result = await db.rawQuery('''
      SELECT client_id 
      FROM event 
      WHERE event_id = ?
    ''', [eventId]);

    if (result.isNotEmpty) {
      return result.first['client_id'] as int?;
    } else {
      return null; // Return null jika tidak ada hasil
    }
  }


  String eventsTable = 'event';
  String colEventId = 'event_id';
  String colEventName = 'event_name';
  String colDate = 'date';

  Future<Event?> getEventById(int eventId) async {
      Database db = await instance.database;
      final List<Map<String, dynamic>> eventMaps = await db.query(
        eventsTable,
        where: '$colEventId = ?',
        whereArgs: [eventId],
      );

      if (eventMaps.isNotEmpty) {
        return Event.fromMap(eventMaps.first);
      }
      return null;
    }

  // Tambahkan fungsi baru untuk mendapatkan event berdasarkan nama dan client_id
  Future<Map<String, dynamic>?> getEventByNameAndClient(String eventName, int clientId) async {
    Database db = await instance.database;
    var result = await db.query(
      'event',
      where: 'event_name = ? AND client_id = ?',
      whereArgs: [eventName, clientId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> insertSession(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('Session', row);
  }

  Future<int> insertTable(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('Table', row);
  }

  Future<void> addCheckIn(int sessionId, int guestId) async {
    final Database db = await instance.database;
    await db.insert('check_in', {'session_id': sessionId, 'guest_id': guestId});
  }

    Future<void> deleteCheckInByGuestId(int guestId) async {
    final db = await database;
    await db.delete(
      'check_in',
      where: 'guest_id = ?',
      whereArgs: [guestId],
    );
  }
  
  Future<void> insertEventWithSessions(String eventName, int clientId, DateTime date, List<Map<String, dynamic>> sessions) async {
    final db = await database;
    await db.transaction((txn) async {
      // Insert event
      int eventId = await txn.insert('event', {
        'event_name': eventName,
        'client_id': clientId,
        'date': date.toIso8601String(),
      });

      // Insert sessions
      for (var session in sessions) {
        int sessionId = await txn.insert('session', {
          'session_name': session['session_name'],
          'time': session['time'],
          'location': session['location'],
          'event_id': eventId,
        });

        // Insert tables if enabled
        if (session['tables'] != null) {
          for (var table in session['table'] ?? {}) {
            await txn.insert('table', {
              'table_name': table['table_name'],
              'seat': table['seat'],
              'session_id': sessionId,
            });
          }
        }
      }
    });
  }



}
