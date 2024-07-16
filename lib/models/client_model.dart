class Client {
  final int? client_id;
  final int? user_id;
  final String name;
  final String email;
  final String? phone;

  Client({
    this.client_id,
    required this.user_id,
    required this.name,
    required this.email,
    this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'client_id': client_id,
      'user_id': user_id,
      'name': name,
      'email': email,
      'phone': phone,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      client_id: map['client_id'],
      user_id: map['user_id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
    );
  }

  // Add factory method to convert from Map<String, dynamic> to Client
  factory Client.fromMaps(Map<String, dynamic> json) {
    return Client(
      client_id: json['client_id'],
      user_id: json['user_id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
    );
  }
}
