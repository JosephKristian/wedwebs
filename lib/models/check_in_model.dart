class CheckIn {
  int sessionId;
  int guestId;
  String? souvenir;
  int? angpau;
  int paxChecked;
  String? meals;
  String? note;
  String delivery;
  int guestNo;
  String status;

  CheckIn({
    required this.sessionId,
    required this.guestId,
    this.souvenir,
    this.angpau,
    this.paxChecked = 1,
    this.meals,
    this.note,
    this.delivery = 'no',
    this.guestNo = 1,
    this.status = 'not check-in yet',
  });

  Map<String, dynamic> toMap() {
    return {
      'session_id': sessionId,
      'guest_id': guestId,
      'souvenir': souvenir,
      'angpau': angpau,
      'pax_checked': paxChecked,
      'meals': meals,
      'note': note,
      'delivery': delivery,
      'guestNo': guestNo,
      'status': status,
    };
  }

  factory CheckIn.fromMap(Map<String, dynamic> map) {
    return CheckIn(
      sessionId: map['session_id'],
      guestId: map['guest_id'],
      souvenir: map['souvenir'],
      angpau: map['angpau'],
      paxChecked: map['pax_checked'],
      meals: map['meals'],
      note: map['note'],
      delivery: map['delivery'],
      guestNo: map['guestNo'],
      status: map['status'],
    );
  }
}
