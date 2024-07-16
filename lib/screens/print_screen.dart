import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wedweb/models/event_model.dart';
import 'package:wedweb/models/session_model.dart';
import 'package:wedweb/models/guest_model.dart';
import 'package:wedweb/models/client_model.dart';
import 'package:wedweb/models/check_in_model.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrintScreen extends StatefulWidget {
  final int guestId;
  final Guest? guestBeforeUpdate;
  final Event? eventUpdate;
  final Session? sessionUpdate;
  final Client? client;
  final CheckIn? updatedCheckIn;

  PrintScreen({
    required this.guestId,
    required this.guestBeforeUpdate,
    required this.eventUpdate,
    required this.sessionUpdate,
    required this.client,
    required this.updatedCheckIn,
  });

  @override
  _PrintScreenState createState() => _PrintScreenState();
}

class _PrintScreenState extends State<PrintScreen> {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  String? _deviceMsg;

  @override
  void initState() {
    super.initState();
    initBluetooth();
    _loadSelectedDevice();
  }

  void _loadSelectedDevice() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? address = prefs.getString('selected_device_address');
    if (address != null) {
      for (var device in _devices) {
        if (device.address == address) {
          setState(() {
            _selectedDevice = device;
          });
          break;
        }
      }
    }
  }

  void initBluetooth() async {
    bool isConnected = await bluetooth.isConnected ?? false;

    if (!isConnected) {
      try {
        _devices = await bluetooth.getBondedDevices();
        setState(() {});
      } catch (e) {
        print(e);
      }
    }
  }

  void _print() async {
    try {
      if (_selectedDevice == null) {
        await _choosePrinter();
      }

      if (_selectedDevice != null) {
        _printTest();
      }
    } catch (e) {
      print(e);
      setState(() {
        _deviceMsg = 'Error: $e';
      });
    }
  }

  Future<void> _choosePrinter() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pilih Printer Bluetooth'),
          content: DropdownButton<BluetoothDevice>(
            items: _devices
                .map((device) => DropdownMenuItem(
                      child: Text(device.name!),
                      value: device,
                    ))
                .toList(),
            onChanged: (value) async {
              setState(() {
                _selectedDevice = value;
              });
              Navigator.of(context).pop();
              SharedPreferences prefs = await SharedPreferences.getInstance();
              prefs.setString('selected_device_address', _selectedDevice!.address!);
              _connect();
            },
            value: _selectedDevice,
          ),
        );
      },
    );
  }

  
  void _connect() {
    if (_selectedDevice != null) {
      bluetooth.connect(_selectedDevice!).catchError((error) {
        setState(() => _deviceMsg = 'Tidak dapat terhubung, terjadi kesalahan');
      });
    } else {
      setState(() => _deviceMsg = 'Tidak ada perangkat dipilih');
    }
  }

void _printTest() {
  bluetooth.isConnected.then((isConnected) {
    if (isConnected!) {
      bluetooth.printNewLine();
      bluetooth.printCustom("E-TICKET", 3, 1);
      bluetooth.printNewLine();
      if (widget.client != null) {
        bluetooth.printCustom(widget.client!.name, 2, 1);
        bluetooth.printNewLine();
        bluetooth.printQRcode(widget.guestBeforeUpdate!.guest_qr!, 300, 300, 1);
        bluetooth.printNewLine();
        bluetooth.printCustom("${widget.eventUpdate!.eventName}", 2, 1);
        bluetooth.printNewLine();
        bluetooth.printCustom("Nama Tamu: ${widget.guestBeforeUpdate!.name}", 1, 0);
        bluetooth.printCustom("Jumlah Pax: ${widget.updatedCheckIn!.paxChecked.toString()}", 1, 0);
        bluetooth.printCustom("Kategori: ${widget.guestBeforeUpdate!.cat}", 1, 0);
        bluetooth.printCustom("Event: ${widget.eventUpdate!.eventName}", 1, 0);
        bluetooth.printCustom("Tanggal: ${formatDate(widget.eventUpdate!.date)}", 1, 0);
        bluetooth.printCustom("Waktu: ${widget.sessionUpdate!.time}", 1, 0);
        bluetooth.printCustom("Lokasi: ${widget.sessionUpdate!.location}", 1, 0);
        bluetooth.printNewLine();
        bluetooth.printNewLine();
        bluetooth.printNewLine();
        bluetooth.paperCut();
      }
    } else {
      _showDeviceSelectionDialog(); // Tampilkan dialog pilihan perangkat
    }
  });
}


  void _showDeviceSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pilih Perangkat Bluetooth'),
          content: Container(
            width: double.minPositive,
            height: 150,
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_devices[index].name ?? "Perangkat tidak dikenal"),
                  onTap: () {
                    _selectedDevice = _devices[index];
                    Navigator.of(context).pop();
                    _connect();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }


  String formatDate(String dateStr) {
    final DateTime dateTime = DateTime.parse(dateStr);
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(dateTime);
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
                  ),
                ],
              ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _print,
              icon: Icon(Icons.print),
              label: Text('Cetak'),
            ),
            // ElevatedButton.icon(
            //   onPressed: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => ScanQRScreen(clientId: widget.client!.client_id!),
            //       ),
            //     );
            //   },
            //   icon: Icon(Icons.arrow_forward),
            //   label: Text('Next'),
            // ),
            if (_deviceMsg != null) Text(_deviceMsg!),
          ],
        ),
      ),
    );
  }
}
