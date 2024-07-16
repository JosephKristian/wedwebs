    import 'package:flutter/material.dart';
    import 'package:logging/logging.dart';
    import 'package:intl_phone_field/intl_phone_field.dart';
    import '../../services/database_helper.dart'; // Sesuaikan dengan path DatabaseHelper
    import '../../models/client_model.dart'; // Sesuaikan dengan model Client
    import 'package:intl/intl.dart'; // Untuk format tanggal dan waktu

    class UpdateMDClientScreen extends StatefulWidget {
      final Client client;
      final Function() onUpdate;

      UpdateMDClientScreen({required this.client, required this.onUpdate});

      @override
      _UpdateMDClientScreenState createState() => _UpdateMDClientScreenState();
    }

    class _UpdateMDClientScreenState extends State<UpdateMDClientScreen> {
      final _formKey = GlobalKey<FormState>();
      final log = Logger('UpdateMDClientScreen');

      late TextEditingController _nameController;
      late TextEditingController _emailController;
      late TextEditingController _phoneController;

      String _phoneCompleteNumber = '';

      @override
      void initState() {
        super.initState();
        _nameController = TextEditingController(text: widget.client.name);
        _emailController = TextEditingController(text: widget.client.email);
        _phoneController = TextEditingController(text: widget.client.phone);
        _phoneCompleteNumber = widget.client.phone ?? '';
      }

      @override
      void dispose() {
        _nameController.dispose();
        _emailController.dispose();
        _phoneController.dispose();
        super.dispose();
      }



      void _updateClient() async {
        if (_formKey.currentState!.validate()) {
          try {
            Client updatedClient = Client(
              client_id: widget.client.client_id,
              user_id: widget.client.user_id,
              name: _nameController.text,
              email: _emailController.text,
              phone: _phoneCompleteNumber,
            );

            await DatabaseHelper.instance.updateClient(updatedClient);
            log.info('Client ${updatedClient.name} updated successfully.');

            widget.onUpdate(); // Panggil fungsi onUpdate setelah berhasil memperbarui data

            Navigator.of(context).pop(); // Tutup dialog
          } catch (e) {
            log.severe('Failed to update client: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update client.'),
              ),
            );
          }
        }
      }

      @override
      Widget build(BuildContext context) {
        return AlertDialog(
          title: Text('Update Client'),
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
                      initialValue: _phoneController.text,
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
                Navigator.of(context).pop(); // Tutup dialog
              },
            ),
            ElevatedButton(
              child: Text('Update'),
              onPressed: _updateClient,
            ),
          ],
        );
      }
    }
