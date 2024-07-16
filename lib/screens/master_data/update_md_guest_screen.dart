import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../models/guest_model.dart';
import '../../services/database_helper.dart';

class UpdateMDGuestScreen extends StatefulWidget {
  final Guest guest;
  final Function onUpdate;

  UpdateMDGuestScreen({required this.guest, required this.onUpdate});

  @override
  _UpdateMDGuestScreenState createState() => _UpdateMDGuestScreenState();
}

class _UpdateMDGuestScreenState extends State<UpdateMDGuestScreen> {
  final _formKey = GlobalKey<FormState>();
  final log = Logger('UpdateMDGuestScreen');

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _paxController;
  late TextEditingController _rsvpController;
  late TextEditingController _catController;

  String _phoneCompleteNumber = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.guest.name);
    _emailController = TextEditingController(text: widget.guest.email);
    _phoneCompleteNumber = widget.guest.phone ?? '';
    _paxController = TextEditingController(text: widget.guest.pax.toString());
    _rsvpController = TextEditingController(text: widget.guest.rsvp);
    _catController = TextEditingController(text: widget.guest.cat);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _paxController.dispose();
    _rsvpController.dispose();
    _catController.dispose();
    super.dispose();
  }

  Future<void> _updateGuest() async {
    if (_formKey.currentState!.validate()) {
      Guest updatedGuest = widget.guest.copyWith(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneCompleteNumber,
        pax: int.tryParse(_paxController.text) ?? 1,
        rsvp: _rsvpController.text,
        cat: _catController.text, // corrected field name
      );

      try {
        await DatabaseHelper.instance.updateGuest(updatedGuest);
        log.info('Guest ${updatedGuest.name} updated successfully.');
        widget.onUpdate();
        Navigator.of(context).pop();
      } catch (e) {
        log.severe('Failed to update guest: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update guest.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Update Guest'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
                initialValue: _phoneCompleteNumber,
                onChanged: (phone) {
                  setState(() {
                    _phoneCompleteNumber = phone.completeNumber;
                  });
                },
              ),
              TextFormField(
                controller: _paxController,
                decoration: InputDecoration(labelText: 'PAX'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _rsvpController,
                decoration: InputDecoration(labelText: 'RSVP'),
              ),
              TextFormField(
                controller: _catController,
                decoration: InputDecoration(labelText: 'CAT'), // corrected field name
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text('Update'),
          onPressed: _updateGuest,
        ),
      ],
    );
  }
}
