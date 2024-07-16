import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../services/database_helper.dart';
import 'update_guest_screen.dart';
import '../models/guest_model.dart';
import 'dashboard_user_screen.dart'; 


class ScanQRScreen extends StatefulWidget {
  final String role;
  final int clientId; // Tambahkan parameter clientId dari DashboardFUserScreen
  ScanQRScreen({required this.clientId, required this.role});

  @override
  _ScanQRScreenState createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? qrController;
  Barcode? result;
  bool isCameraPaused = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Kembali ke DashboardUserScreen ketika tombol kembali ditekan
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => DashboardUserScreen(role: widget.role ,)), // Ganti dengan layar dashboard yang sesuai
          (Route<dynamic> route) => false,
        );
        return false; // Menghentikan navigasi default
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Scan QR Code'),
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              flex: 5,
              child: QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: (result != null)
                    ? Text('Data: ${result!.code}')
                    : Text('Scan a code'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    qrController = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (!isCameraPaused) {
        setState(() {
          isCameraPaused = true;
          result = scanData;
        });

        // Panggil fungsi untuk mencari tamu di database berdasarkan QR code
        await _findGuest(scanData.code);
      }
    });
  }

  Future<void> _findGuest(String? qrCode) async {
    if (qrCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid QR code')),
      );
      _resumeCamera();
      return;
    }

    try {
      final db = await DatabaseHelper().database;
      final List<Map<String, dynamic>> maps = await db.query(
        'Guest',
        where: 'guest_qr = ?',
        whereArgs: [qrCode],
      );

      if (maps.isNotEmpty) {
        final guest = Guest.fromMap(maps[0]);

        // Periksa apakah tamu milik client yang sesuai dengan clientId
        final List<Map<String, dynamic>> clientMaps = await db.query(
          'Client',
          where: 'client_id = ?',
          whereArgs: [widget.clientId],
        );

        if (clientMaps.isNotEmpty) {
          // Cek apakah client_id pada tamu sama dengan widget.clientId
          if (guest.clientId == widget.clientId) {
            // Navigasi ke form update guest dengan guest_id
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UpdateGuestScreen(guestId: guest.guest_id!, role: widget.role,), // Menggunakan camelCase guestId
              ),
            );

            // Setelah kembali dari UpdateGuestScreen, reset camera
            _resumeCamera();
          } else {
            // Tampilkan pesan jika client_id tidak sesuai
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Guest does not belong to this client')),
            );
            _resumeCamera();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Client not found')),
          );
          _resumeCamera();
        }
      } else {
        // Tampilkan pesan jika QR code tidak ditemukan
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Guest not found')),
        );
        _resumeCamera();
      }
    } catch (e) {
      print('Error during database query: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error finding guest')),
      );
      _resumeCamera();
    }
  }

  void _resumeCamera() {
    setState(() {
      isCameraPaused = false;
      result = null;
    });
    qrController?.resumeCamera();
  }

  @override
  void dispose() {
    qrController?.dispose();
    super.dispose();
  }
}
