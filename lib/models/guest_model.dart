class Guest {
  int? guest_id;
  String? guest_qr;
  String name;
  String? email;
  int clientId;
  String? phone;
  int pax;
  String rsvp;
  String cat;

  Guest({
    this.guest_id,
    this.guest_qr,
    required this.name,
    this.email,
    required this.clientId,
    this.phone,
    this.pax = 1,
    this.rsvp = 'pending',
    this.cat = 'REGULAR',
  });

  Map<String, dynamic> toMap() {
    return {
      'guest_id': guest_id,
      'guest_qr': guest_qr,
      'name': name,
      'email': email,
      'client_id': clientId,
      'phone': phone,
      'pax': pax,
      'rsvp': rsvp,
      'cat': cat,
    };
  }

  static Guest fromMap(Map<String, dynamic> map) {
    return Guest(
      guest_id: map['guest_id'],
      guest_qr: map['guest_qr'],
      name: map['name'],
      email: map['email'],
      clientId: map['client_id'],
      phone: map['phone'],
      pax: map['pax'],
      rsvp: map['rsvp'],
      cat: map['cat'],
    );
  }

  Guest copyWith({
    int? guest_id,
    String? guest_qr,
    String? name,
    String? email,
    int? clientId,
    String? phone,
    int? pax,
    String? rsvp,
    String? cat,
  }) {
    return Guest(
      guest_id: guest_id ?? this.guest_id,
      guest_qr: guest_qr ?? this.guest_qr,
      name: name ?? this.name,
      email: email ?? this.email,
      clientId: clientId ?? this.clientId,
      phone: phone ?? this.phone,
      pax: pax ?? this.pax,
      rsvp: rsvp ?? this.rsvp,
      cat: cat ?? this.cat,
    );
  }
}
