import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../../services/auth_service.dart';

class MDAdminScreen extends StatelessWidget {
  final String role;
  final log = Logger('MDAdminScreen');

  MDAdminScreen({required this.role});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      // Atur padding sesuai kebutuhan
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: Text(
          'Widget Kosong',
          style: TextStyle(fontSize: 20.0),
        ),
      ),
    );
  }
}
