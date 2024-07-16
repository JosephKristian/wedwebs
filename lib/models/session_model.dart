class Session {
  int? sessionId;
  int eventId; // tambahkan event_id sebagai foreign key
  String sessionName;
  String time;
  String location;

  Session({
    this.sessionId,
    required this.eventId,
    required this.sessionName,
    required this.time,
    required this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'session_id': sessionId,
      'event_id': eventId,
      'session_name': sessionName,
      'time': time,
      'location': location,
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      sessionId: map['session_id'],
      eventId: map['event_id'],
      sessionName: map['session_name'],
      time: map['time'],
      location: map['location'],
    );
  }

  // // Tambahkan method untuk memasukkan Session ke dalam database
  // Future<int> insert() async {
  //   final db = await DatabaseHelper().database;
  //   return await db.insert('Session', toMap());
  // }

  // // Tambahkan method untuk memperbarui Session di database
  // Future<int> update() async {
  //   final db = await DatabaseHelper().database;
  //   return await db.update(
  //     'Session',
  //     toMap(),
  //     where: 'session_id = ?',
  //     whereArgs: [sessionId],
  //   );
  // }

  // // Tambahkan method untuk menghapus Session dari database
  // Future<void> delete() async {
  //   final db = await DatabaseHelper().database;
  //   await db.delete(
  //     'Session',
  //     where: 'session_id = ?',
  //     whereArgs: [sessionId],
  //   );
  // }
}
