import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:crypto/crypto.dart'; // Tambahkan ini untuk enkripsi
import 'dart:convert'; // Tambahkan ini untuk utf8
import '../models/user_model.dart';
import '../services/auth_service.dart';


class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final log = Logger('_RegisterScreenState');

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String? _selectedRole; // Tambahkan ini untuk role

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _roleError; // Tambahkan ini untuk role

  void validateInputs() async {
    setState(() {
      _nameError = _nameController.text.isEmpty ? 'Name tidak boleh kosong' : null;
      _emailError = _validateEmail(_emailController.text) ? null : 'Format email tidak valid';
      _passwordError = _validatePassword(_passwordController.text) ? null : 'Password harus berupa kombinasi angka dan huruf minimal 8 karakter';
      _confirmPasswordError = _confirmPasswordController.text.isEmpty ? 'Konfirmasi password tidak boleh kosong' : null;
      _roleError = _selectedRole == null ? 'Role harus dipilih' : null; // Tambahkan validasi role

      if (_passwordController.text != _confirmPasswordController.text) {
        _confirmPasswordError = 'Password tidak cocok';
      }
    });

    log.info('Validasi input selesai: $_nameError, $_emailError, $_passwordError, $_confirmPasswordError, $_roleError');

    if (_nameError == null && _emailError == null && _passwordError == null && _confirmPasswordError == null && _roleError == null) {
      String name = _nameController.text;
      String email = _emailController.text;
      String password = _passwordController.text;
      String role = _selectedRole!; // Tambahkan ini untuk role

      String hashedPassword = hashPassword(password); // Encrypt password

      User newUser = User(
        name: name,
        email: email,
        password: hashedPassword, // Save encrypted password
        role: role, // Simpan role
      );

      try {
        log.info('Registrasi dengan nama: $name, email: $email, role: $role');
        AuthService authService = AuthService();
        await authService.registerUser(newUser);

        log.info('Registrasi berhasil');
        // Contoh alert dialog setelah berhasil registrasi
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Registrasi Berhasil'),
            content: Text('Registrasi berhasil dilakukan.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Tutup dialog
                  Navigator.pushReplacementNamed(context, '/login'); // Navigasi ke halaman login
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      } catch (e) {
        log.severe('Terjadi kesalahan saat registrasi: $e');
        String errorMessage = 'Terjadi kesalahan saat melakukan registrasi.';

        if (e.toString().contains('UNIQUE constraint failed')) {
          errorMessage = 'Email sudah digunakan. Silakan gunakan email lain.';
          setState(() {
            _emailError = errorMessage;
          });
        }

        // Handle error
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Tutup dialog
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } else {
      log.warning('Validasi gagal dengan error: $_nameError, $_emailError, $_passwordError, $_confirmPasswordError, $_roleError');
    }
  }

  String hashPassword(String password) {
    var bytes = utf8.encode(password); // Convert password to bytes
    var digest = sha256.convert(bytes); // Apply SHA-256 encryption

    return digest.toString(); // Return encrypted password as string
  }

  bool _validateEmail(String email) {
    // Validasi menggunakan regular expression untuk format email
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _validatePassword(String password) {
    // Validasi password harus mengandung minimal 1 angka, 1 huruf, dan panjang minimal 8 karakter
    return RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$').hasMatch(password);
  }

  @override
  Widget build(BuildContext context) {
    log.info('RegisterScreen widget dibangun');

    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Name',
                  errorText: _nameError,
                ),
              ),
              SizedBox(height: 20),
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
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Konfirmasi Password',
                  errorText: _confirmPasswordError,
                ),
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                items: ['admin', 'user', 'client'].map((String role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRole = newValue;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Pilih Role',
                  errorText: _roleError,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: validateInputs,
                child: Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() => runApp(MaterialApp(
  home: RegisterScreen(),
));
