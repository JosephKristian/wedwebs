class TableModel {
  int? tableId;
  int sessionId;
  String tableName;
  int seat;

  TableModel({
    this.tableId,
    required this.sessionId,
    required this.tableName,
    required this.seat,
  });

  Map<String, dynamic> toMap() {
    return {
      'table_id': tableId,
      'session_id': sessionId,
      'table_name': tableName,
      'seat': seat,
    };
  }

  factory TableModel.fromMap(Map<String, dynamic> map) {
    return TableModel(
      tableId: map['table_id'],
      sessionId: map['session_id'],
      tableName: map['table_name'],
      seat: map['seat'],
    );
  }

   factory TableModel.empty() {
    // Kembalikan nilai default jika tidak ada data yang ditemukan
    return TableModel(
      // Nilai default untuk setiap atribut
      tableId: 0,
      sessionId: 0,
      tableName: 'none',
      seat: 0,
    );
  }
}
