import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/database_helper.dart';
import '../../models/client_model.dart';
import 'package:intl/intl.dart';

class InsertMDClientScreen extends StatefulWidget {
  final Function() onInsert;

  InsertMDClientScreen({required this.onInsert});

  @override
  _InsertMDClientScreenState createState() => _InsertMDClientScreenState();
}

class _InsertMDClientScreenState extends State<InsertMDClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final log = Logger('InsertMDClientScreen');

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String _phoneCompleteNumber = '';
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }
    
  void _loadUserId() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('user_id');
      log.info('User ID loaded from SharedPreferences: $userId');

      setState(() {
        _userId = userId;
      });
    } catch (e) {
      log.severe('Failed to load user ID: $e');
      // Handle error appropriately
    }
  }


  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _insertClient() async {
    if (_formKey.currentState!.validate()) {
      if (_userId == null) {
        log.severe('User ID is null');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get user ID.'),
          ),
        );
        return;
      }

      try {
        Client newClient = Client(
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneCompleteNumber,
          user_id: _userId!,
        );

        await DatabaseHelper.instance.insertClient(newClient);
        log.info('Client ${newClient.name} inserted successfully.');

        widget.onInsert();

        Navigator.of(context).pop();
      } catch (e) {
        log.severe('Failed to insert client: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to insert client.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add New Client'),
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
                      return 'Please enter the name';
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
                      return 'Please enter the email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email address';
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
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: Text('Insert'),
          onPressed: _insertClient,
        ),
      ],
    );
  }
}
