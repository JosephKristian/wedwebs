import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as blue;
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:wedweb/models/event_model.dart';
import 'package:wedweb/models/session_model.dart';
import 'package:wedweb/models/guest_model.dart';
import 'package:wedweb/models/client_model.dart';
import 'package:wedweb/models/check_in_model.dart';

import 'scan_qr_screen.dart';

class PrintScreen extends StatefulWidget {
  final int guestId;
  final Guest? guestBeforeUpdate;
  final Event? eventUpdate;
  final Session? sessionUpdate;
  final Client? client;
  final CheckIn? updatedCheckIn;
  final String role;

  PrintScreen({
    required this.guestId,
    required this.guestBeforeUpdate,
    required this.eventUpdate,
    required this.sessionUpdate,
    required this.client,
    required this.updatedCheckIn,
    required this.role,
  });

  @override
  _PrintScreenState createState() => _PrintScreenState();
}

class _PrintScreenState extends State<PrintScreen> {
  String? _savedAddress;
  StreamSubscription<List<blue.ScanResult>>? _scanSubscription;
  StreamSubscription? _bluetoothStateSubscription;
  blue.BluetoothDevice? _connectedDevice;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _loadSavedAddress();
    _monitorBluetoothState();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _bluetoothStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    if (await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted &&
        await Permission.locationWhenInUse.request().isGranted) {
      _scanForDevices();
    } else {
      // Handle the case where permissions are not granted
      _showDialog('Permissions not granted');
    }
  }

  Future<void> _loadSavedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedAddress = prefs.getString('printer_address');
    });
  }

  Future<void> _saveAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('printer_address', address);
    setState(() {
      _savedAddress = address;
    });
  }

  Future<void> _clearSavedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('printer_address');
    setState(() {
      _savedAddress = null;
    });
  }

  String formatDate(String dateStr) {
    final DateTime dateTime = DateTime.parse(dateStr);
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(dateTime);
  }

  Future<void> printDummyReceipt(String address) async {
    try {
      // Membuat data dummy untuk struk
      List<int> receiptBytes = [];
      receiptBytes += [0x1B, 0x40]; // Init printer
      receiptBytes += [0x1B, 0x61, 0x01]; // Align center
      receiptBytes += [0x1D, 0x21, 0x11]; // Font size double-height and double-width
      receiptBytes += utf8.encode('${widget.client!.name}\n'); // Client name in uppercase
      receiptBytes += [0x1D, 0x21, 0x00]; // Reset font size
      receiptBytes += utf8.encode('-------------------------\n'); // Garis pemisah

      // Menambahkan QR code
      receiptBytes += generateQRCode(widget.guestBeforeUpdate!.guest_qr!);

      receiptBytes += utf8.encode('-------------------------\n'); // Garis pemisah
      receiptBytes += [0x1D, 0x21, 0x01]; // Bold text
      receiptBytes += utf8.encode('${widget.eventUpdate!.eventName}\n');
      receiptBytes += [0x1D, 0x21, 0x00]; // Reset bold text

      receiptBytes += [0x1B, 0x61, 0x00]; // Reset align center
      receiptBytes += utf8.encode('Guest Name: ${widget.guestBeforeUpdate!.name}\n');
      receiptBytes += utf8.encode('Table: ...\n');
      receiptBytes += utf8.encode('Headcount: ${widget.updatedCheckIn!.paxChecked}\n');
      receiptBytes += utf8.encode('Category: ${widget.guestBeforeUpdate!.cat}\n');
      receiptBytes += utf8.encode('Date: ${formatDate(widget.eventUpdate!.date)} (${widget.sessionUpdate!.time})\n');
      receiptBytes += utf8.encode('Location: ${widget.sessionUpdate!.location}\n');
      receiptBytes += utf8.encode('Session: ${widget.sessionUpdate!.sessionName}\n');
      receiptBytes += utf8.encode('\n'); // Garis pemisah
      receiptBytes += utf8.encode('\n'); // Garis pemisah
      receiptBytes += [0x1B, 0x61, 0x01]; // Align center
      receiptBytes += utf8.encode('WEDWEB.COM!\n');
      receiptBytes += utf8.encode('-------------------------\n'); // Garis pemisah
      receiptBytes += [0x0A]; // Newline

      // Logging
      print('Printing receipt...');
      print('Client Name: ${widget.client!.name}');
      print('Event Name: ${widget.eventUpdate!.eventName}');
      print('Guest Name: ${widget.guestBeforeUpdate!.name}');
      print('Address: $address');

      // Mengirim data ke printer
      await FlutterBluetoothPrinter.printBytes(
        address: address,
        data: Uint8List.fromList(receiptBytes),
        keepConnected: false,
      );
      print('Receipt printed successfully.');
    } catch (e) {
      print('Error printing receipt: $e');
      // Handle error: show dialog or log error message
      _showDialog('Error printing receipt: $e');
    }
  }

  List<int> generateQRCode(String data) {
    // Setting model of QR Code
    List<int> qrCodeCommand = [];
    qrCodeCommand += [0x1D, 0x28, 0x6B, 0x04, 0x00, 0x31, 0x41, 0x32, 0x00];

    // Setting size of QR Code
    qrCodeCommand += [0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, 0x06];

    // Error correction level
    qrCodeCommand += [0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, 0x30];

    // Store data in QR Code symbol storage area
    List<int> storeQRCodeData = [];
    storeQRCodeData += [0x1D, 0x28, 0x6B];
    int dataLength = data.length + 3;
    storeQRCodeData += [dataLength % 256, dataLength ~/ 256]; // pL pH
    storeQRCodeData += [0x31, 0x50, 0x30];
    storeQRCodeData += utf8.encode(data);

    // Print QR Code
    List<int> printQRCodeCommand = [];
    printQRCodeCommand += [0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30];

    return qrCodeCommand + storeQRCodeData + printQRCodeCommand;
  }

  Future<void> _selectAndSaveDevice() async {
    final device = await FlutterBluetoothPrinter.selectDevice(context);
    if (device != null) {
      await _saveAddress(device.address);
    }
  }

  void _scanForDevices() async {
    var bluetoothState = await blue.FlutterBluePlus.adapterState.first;
    if (bluetoothState != blue.BluetoothAdapterState.on) {
      _showDialog('Bluetooth is off. Please turn on Bluetooth.');
      return;
    }

    _scanSubscription = blue.FlutterBluePlus.scanResults.listen((List<blue.ScanResult> results) {
      // Filter and connect to the known printer device
      for (blue.ScanResult result in results) {
        if (result.device.advName == 'Bluetooth Printer') { // Replace with your printer's name
          _connectToDevice(result.device);
          break;
        }
      }
    });
    blue.FlutterBluePlus.startScan();
    print('Scanning for Bluetooth devices...');
  }

  void _connectToDevice(blue.BluetoothDevice device) async {
    try {
      await device.connect();
      setState(() {
        _connectedDevice = device;
      });
      // Handle successful connection, e.g., show connected status
      print('Connected to printer: ${device.name}');
    } catch (e) {
      // Handle connection failure
      _showDialog('Failed to connect to printer. Please ensure the printer is on.');
      print('Failed to connect to printer: $e');
    }
  }

  void _disconnectFromDevice() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      setState(() {
        _connectedDevice = null;
      });
      // Handle disconnection, e.g., show disconnected status
      print('Disconnected from printer.');
    }
  }

  void _monitorBluetoothState() {
    _bluetoothStateSubscription = blue.FlutterBluePlus.adapterState.listen((state) {
      if (state == blue.BluetoothState.off) {
        _showDialog('Bluetooth is off. Please turn on Bluetooth.');
      }
    });
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Notification'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('E-TICKET'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.client != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Center(
                  child: Text(
                    widget.client!.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            SizedBox(height: 16),
            Center(
              child: QrImageView(
                data: widget.guestBeforeUpdate!.guest_qr!,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: Text(
                  widget.eventUpdate!.eventName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            if (widget.guestBeforeUpdate != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    title: Text('Nama Tamu:'),
                    subtitle: Text(widget.guestBeforeUpdate!.name),
                    trailing: Text(
                      'Jumlah Pax: ${widget.updatedCheckIn!.paxChecked.toString()}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  ListTile(
                    title: Text('Kategori:'),
                    subtitle: Text(widget.guestBeforeUpdate!.cat),
                    trailing: Text(
                      '${formatDate(widget.eventUpdate!.date)} (${widget.sessionUpdate!.time})',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  ListTile(
                    title: Text('Lokasi:'),
                    subtitle: Text(widget.sessionUpdate!.location),
                     trailing: Text(
                      'session: ${widget.sessionUpdate!.sessionName.toString()}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                if (_savedAddress == null) {
                  await _selectAndSaveDevice();
                }
                if (_savedAddress != null) {
                  await printDummyReceipt(_savedAddress!);
                }
              },
              icon: Icon(Icons.print),
              label: Text('Print Receipt'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await _clearSavedAddress();
                if (_savedAddress == null) {
                  await _selectAndSaveDevice();
                }
                if (_savedAddress != null) {
                  await printDummyReceipt(_savedAddress!);
                }
              },
              icon: Icon(Icons.search),
              label: Text('Scan Device'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => ScanQRScreen(clientId: widget.client!.client_id!,role: widget.role,)),
                  (Route<dynamic> route) => false,
                );
              },
              icon: Icon(Icons.arrow_circle_right_rounded),
              label: Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}
