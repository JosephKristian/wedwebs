import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart'; // Pastikan mengimpor halaman registrasi yang sesuai
import 'services/database_helper.dart'; // Sesuaikan dengan path file DatabaseHelper
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // Inisialisasi binding Flutter terlebih dahulu
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  // Setup logger
  _setupLogging();

  // Initialize DatabaseHelper
  await _initializeDatabase();

  runApp(MyApp());
}

void _setupLogging() {
  Logger.root.level = Level.ALL; // Log semua level
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
}

Future<void> _initializeDatabase() async {
  final log = Logger('_initializeDatabase');

  try {
    // Panggil method untuk inisialisasi database
    await DatabaseHelper.instance.database; // Memanggil getter instance untuk mendapatkan DatabaseHelper singleton

    log.info('Database berhasil diinisialisasi');
  } catch (e) {
    log.severe('Terjadi kesalahan saat inisialisasi database: $e');
    // Handle error
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final log = Logger('MyApp');
    log.info('MyApp widget dibangun');

    return MaterialApp(
      title: 'Digital Guestbook',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login', // Rute awal diatur ke halaman login
      routes: {
        '/login': (context) => LoginScreen(), // Rute untuk halaman login
        '/register': (context) => RegisterScreen(), // Rute untuk halaman registrasi
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: Text('Error')),
            body: Center(
              child: Text('Halaman tidak ditemukan'),
            ),
          ),
        );
      },
    );
  }
}
