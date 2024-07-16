import 'package:logging/logging.dart';
import 'database_helper.dart';
import 'package:crypto/crypto.dart'; // Tambahkan ini untuk enkripsi
import 'dart:convert'; // Tambahkan ini untuk utf8
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final log = Logger('AuthService');

  Future<int> registerUser(User user) async {
    final db = await DatabaseHelper().database;
    try {
      // Encrypt the user's password before creating the User object
      final encryptedPassword = _hashPassword(user.password);
      final newUser = User(
        user_id: user.user_id,
        name: user.name,
        email: user.email,
        password: encryptedPassword,
        emailVerifiedAt: user.emailVerifiedAt,
        role: user.role,
        rememberToken: user.rememberToken,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
      );
      
      log.info('Melakukan registrasi untuk user dengan email: ${newUser.email}');
      int result = await db.insert('users', newUser.toMap());
      log.info('Registrasi berhasil untuk user dengan email: ${newUser.email}, ID: $result');
      return result;
    } catch (e) {
      log.severe('Gagal melakukan registrasi untuk user dengan email: ${user.email}', e);
      rethrow;
    }
  }

  Future<User?> loginUser(String email, String password) async {
    final db = await DatabaseHelper().database;
    try {
      log.info('Melakukan login untuk user dengan email: $email');
      
      // Encrypt the input password to compare with the stored hashed password
      String hashedPassword = _hashPassword(password);

      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [email, hashedPassword],
      );

      if (maps.isNotEmpty) {
        log.info('Login berhasil untuk user dengan email: $email');
        User user = User.fromMap(maps[0]);

        // Save user_id to SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', user.user_id!);
        log.info('User ID ${user.user_id} saved to SharedPreferences');

        return user;
      } else {
        log.warning('Login gagal untuk user dengan email: $email - Email atau password salah');
        return null;
      }
    } catch (e) {
      log.severe('Gagal melakukan login untuk user dengan email: $email', e);
      rethrow;
    }
  }

  String _hashPassword(String password) {
    var bytes = utf8.encode(password); // Convert password to bytes
    var digest = sha256.convert(bytes); // Apply SHA-256 encryption

    return digest.toString(); // Return encrypted password as string
  }

  Future<void> logout() async {
    // Implementasi logout, misalnya menghapus token dari penyimpanan
    log.info('Logout dari aplikasi');
    // Hapus token atau sesi pengguna di penyimpanan lokal
    // Contoh: await SharedPreferences.getInstance().then((prefs) => prefs.remove('token'));
  }
}
