import 'package:flutter/material.dart';
import 'package:logging/logging.dart';  // Sesuaikan dengan nama file DashboardScreen di proyek Anda
import 'dashboard_admin_screen.dart'; // Sesuaikan dengan nama file DashboardScreen di proyek Anda
import 'register_screen.dart'; // Sesuaikan dengan nama file RegisterScreen di proyek Anda
import '../models/user_model.dart'; // Sesuaikan dengan path model User
import '../services/auth_service.dart'; // Sesuaikan dengan path service AuthService
import 'package:crypto/crypto.dart'; // Tambahkan untuk enkripsi
import 'dart:convert'; // Tambahkan untuk utf8
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final log = Logger('_LoginScreenState');

  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;

  // Simpan user ID ke SharedPreferences
  Future<void> saveUserId(int userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userId);
  }
  void validateInputs() async {
    setState(() {
      _emailError = _validateEmail(_emailController.text) ? null : 'Format email tidak valid';
      _passwordError = _passwordController.text.isEmpty ? 'Password tidak boleh kosong' : null;
    });

    log.info('Validasi input selesai: $_emailError, $_passwordError');

    if (_emailError == null && _passwordError == null) {
      String email = _emailController.text;
      String password = _passwordController.text;

      // Enkripsi password
      String encryptedPassword = _hashPassword(password);

      log.info('Melakukan proses login dengan email: $email');

      try {
        AuthService authService = AuthService();
        User? loggedInUser = await authService.loginUser(email, encryptedPassword);

        if (loggedInUser != null) {
          log.info('Login berhasil, mengarahkan ke DashboardScreen');

          // Navigasi ke DashboardScreen berdasarkan role pengguna
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardAdminScreen(role: loggedInUser.role)), // Pastikan ini sesuai dengan nama kelas yang didefinisikan
          );
        } else {
          log.warning('Login gagal, email atau password salah');
          // Tambahkan logika jika login gagal, misalnya tampilkan pesan kesalahan
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Login Gagal'),
              content: Text('Email atau password salah.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        log.severe('Terjadi kesalahan saat login: $e');
        // Handle error
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('Terjadi kesalahan saat melakukan login: $e'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } else {
      log.warning('Validasi gagal dengan error: $_emailError, $_passwordError');
    }
  }

  String _hashPassword(String password) {
    var bytes = utf8.encode(password); // Convert password to bytes
    var digest = sha256.convert(bytes); // Apply SHA-256 encryption

    return digest.toString(); // Return encrypted password as string
  }

  bool _validateEmail(String email) {
    // Validasi menggunakan regular expression untuk format email
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    log.info('LoginScreen widget dibangun');

    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Email',
                  errorText: _emailError,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  errorText: _passwordError,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: validateInputs,
                child: Text('Login'),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  log.info('Navigasi ke RegisterScreen');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterScreen()), // Ganti dengan halaman RegisterScreen
                  );
                },
                child: Text('Belum punya akun? Registrasi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
