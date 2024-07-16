class Event {
  final int eventId;
  final int clientId;
  final String eventName;
  final String date;

  Event({
    required this.eventId,
    required this.clientId,
    required this.eventName,
    required this.date,
  });

  factory Event.fromMap(Map<String, dynamic> json) => Event(
    eventId: json['event_id'],
    clientId: json['client_id'],
    eventName: json['event_name'],
    date: json['date'],
  );

  Map<String, dynamic> toMap() => {
    'event_id': eventId,
    'client_id': clientId,
    'event_name': eventName,
    'date': date,
  };
}
