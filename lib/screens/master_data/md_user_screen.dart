import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class MDUserScreen extends StatelessWidget {

  final String role;
  final log = Logger('MDUserScreen');

  MDUserScreen({required this.role});

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
