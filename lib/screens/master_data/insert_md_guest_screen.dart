import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../services/database_helper.dart';
import '../../models/guest_model.dart';

class InsertMDGuestScreen extends StatefulWidget {
  final Function() onInsert;
  final int eventId;
  final Map<String, dynamic>? guestData;

  InsertMDGuestScreen({required this.onInsert, required this.eventId, this.guestData});

  @override
  _InsertMDGuestScreenState createState() => _InsertMDGuestScreenState();
}

class _InsertMDGuestScreenState extends State<InsertMDGuestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _paxController = TextEditingController(text: '1');
  String _selectedCat = 'REGULAR'; // Added variable to store selected value
  String _guestQR = '';
  String _phoneCompleteNumber = '';
  int? clientId;

  @override
  void initState() {
    super.initState();
    getClientId();
  }

  Future<void> getClientId() async {
    clientId = await DatabaseHelper.instance.getClientIdByEventId(widget.eventId);
    setState(() {}); // Update state setelah mendapatkan client_id
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _paxController.dispose();
    super.dispose();
  }

  Future<void> _generateQR() async {
    // Generate a unique QR code for the guest
    _guestQR = UniqueKey().toString();
  }

  Future<void> _insertGuest() async {
    if (_formKey.currentState!.validate() && clientId != null) {
      await _generateQR();
      Guest newGuest = Guest(
        guest_qr: _guestQR,
        name: _nameController.text,
        email: _emailController.text,
        clientId: clientId!, // Use the clientId obtained from the database
        phone: _phoneCompleteNumber,
        pax: int.tryParse(_paxController.text) ?? 1,
        cat: _selectedCat, // Use the selected value from dropdown
      );

      int guestId = await DatabaseHelper.instance.insertGuest(newGuest);

      // Get all session_ids related to the event_id
      List<int> sessionIds = await DatabaseHelper.instance.getSessionIdsByEventId(widget.eventId);

      // Insert guest_id into check_in table for each session_id
      for (int sessionId in sessionIds) {
        await DatabaseHelper.instance.insertCheckIn(sessionId, guestId);
      }

      widget.onInsert(); // Callback to refresh guest list
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add New Guest'),
      content: Container(
        width: MediaQuery.of(context).orientation == Orientation.portrait
            ? MediaQuery.of(context).size.width * 0.8
            : MediaQuery.of(context).size.width * 0.5,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    return null;
                  },
                ),
                IntlPhoneField(
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(),
                    ),
                  ),
                  initialCountryCode: 'ID',
                  onChanged: (phone) {
                    _phoneCompleteNumber = phone.completeNumber;
                  },
                  validator: (phone) {
                    if (phone == null || phone.completeNumber.isEmpty) {
                      return 'Please enter a phone number';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _paxController,
                  decoration: InputDecoration(labelText: 'Pax'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the number of pax';
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _selectedCat,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedCat = value!;
                    });
                  },
                  items: <String>['VIP', 'VVIP', 'REGULAR'].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    labelText: 'Category',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: _insertGuest,
          child: Text('Add'),
        ),
      ],
    );
  }
}
