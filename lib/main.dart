import 'package:flutter/material.dart';

import 'dart:async';

import 'package:flutter_libserialport/flutter_libserialport.dart';

import 'services/arduino_serial_service.dart';

void main() {
  runApp(const VehicularEnvironmentApp());
}

class VehicularEnvironmentApp extends StatelessWidget {
  const VehicularEnvironmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vehicular Environment Control System',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ArduinoSerialService _arduino = ArduinoSerialService();

  StreamSubscription<String>? _serialSubscription;

  List<String> _ports = [];

  String? _selectedPort;

  bool _connected = false;

  double _cabinTemperature = 0.0;
  double _humidity = 0.0;
  int _flame = 0;
  double _engineTemperature = 0.0;

  String _systemStatus = 'NOT CONNECTED';

  bool _relayOn = false;
  bool _buzzerOn = false;

  String _serialBuffer = '';

  @override
  void initState() {
    super.initState();

    _refreshPorts();

    _serialSubscription = _arduino.dataStream.listen(
      _processSerialData,
      onError: (error) {
        if (mounted) {
          setState(() {
            _connected = false;
            _systemStatus = 'SERIAL ERROR';
          });
        }
      },
    );
  }

  void _refreshPorts() {
    setState(() {
      _ports = SerialPort.availablePorts;

      if (_ports.isNotEmpty && _selectedPort == null) {
        _selectedPort = _ports.first;
      }
    });
  }

  void _connectArduino() {
    if (_selectedPort == null) {
      _showMessage('No Arduino serial port selected.');
      return;
    }

    final success = _arduino.connect(_selectedPort!);

    if (success) {
      setState(() {
        _connected = true;
        _systemStatus = 'WAITING FOR DATA...';
      });

      _showMessage('Arduino connected successfully.');
    } else {
      setState(() {
        _connected = false;
        _systemStatus = 'CONNECTION FAILED';
      });

      _showMessage('Could not connect to $_selectedPort');
    }
  }

  void _disconnectArduino() {
    _arduino.disconnect();

    setState(() {
      _connected = false;
      _systemStatus = 'NOT CONNECTED';
      _relayOn = false;
      _buzzerOn = false;
    });

    _showMessage('Arduino disconnected.');
  }

  void _processSerialData(String data) {
    _serialBuffer += data;

    final lines = _serialBuffer.split('\n');

    _serialBuffer = lines.removeLast();

    for (final line in lines) {
      _parseArduinoLine(line.trim());
    }
  }

  void _parseArduinoLine(String line) {
    if (line.isEmpty) return;

    /*
      Arduino format:

      28.5 C | 55.7 % | 0 | 91.9 C | OVERHEATING!
    */

    final parts = line.split('|');

    if (parts.length != 5) return;

    try {
      final cabinText = parts[0].trim();
      final humidityText = parts[1].trim();
      final flameText = parts[2].trim();
      final engineText = parts[3].trim();
      final statusText = parts[4].trim();

      final cabinTemp =
          double.tryParse(cabinText.replaceAll(' C', '').trim());

      final humidity =
          double.tryParse(humidityText.replaceAll('%', '').trim());

      final flame = int.tryParse(flameText);

      final engineTemp =
          double.tryParse(engineText.replaceAll(' C', '').trim());

      if (cabinTemp == null ||
          humidity == null ||
          flame == null ||
          engineTemp == null) {
        return;
      }

      final alert =
          statusText.contains('FIRE') ||
          statusText.contains('OVERHEATING');

      setState(() {
        _cabinTemperature = cabinTemp;
        _humidity = humidity;
        _flame = flame;
        _engineTemperature = engineTemp;
        _systemStatus = statusText;

        _buzzerOn = alert;
        _relayOn = alert;
      });
    } catch (_) {
      // Ignore lines that are not sensor data.
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _serialSubscription?.cancel();
    _arduino.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusIsSafe =
        _systemStatus == 'System Safe' ||
        _systemStatus == 'NOT CONNECTED' ||
        _systemStatus == 'WAITING FOR DATA...';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'VEHICULAR ENVIRONMENT',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'ENVIRONMENT CONTROL SYSTEM',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.usb,
                      color: _connected ? Colors.green : Colors.red,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _connected
                            ? 'Arduino: CONNECTED'
                            : 'Arduino: NOT CONNECTED',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.circle,
                      size: 14,
                      color: _connected ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: sensorCard(
                    Icons.thermostat,
                    'Cabin Temperature',
                    '${_cabinTemperature.toStringAsFixed(1)} °C',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: sensorCard(
                    Icons.water_drop,
                    'Humidity',
                    '${_humidity.toStringAsFixed(1)} %',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            sensorCard(
              Icons.device_thermostat,
              'Engine Temperature',
              '${_engineTemperature.toStringAsFixed(1)} °C',
            ),

            const SizedBox(height: 12),

            statusCard(
              Icons.local_fire_department,
              'Flame Detection',
              _flame == 0 ? 'SAFE' : 'FIRE DETECTED',
              _flame == 0 ? Colors.green : Colors.red,
            ),

            const SizedBox(height: 12),

            statusCard(
              Icons.ac_unit,
              'HVAC / Relay',
              _relayOn ? 'ON' : 'OFF',
              _relayOn ? Colors.red : Colors.green,
            ),

            const SizedBox(height: 12),

            statusCard(
              Icons.volume_up,
              'Buzzer',
              _buzzerOn ? 'ON' : 'OFF',
              _buzzerOn ? Colors.red : Colors.green,
            ),

            const SizedBox(height: 25),

            const Text(
              'ARDUINO CONNECTION',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _selectedPort,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Select Arduino Serial Port',
                prefixIcon: Icon(Icons.usb),
              ),
              items: _ports.map((port) {
                return DropdownMenuItem(
                  value: port,
                  child: Text(port),
                );
              }).toList(),
              onChanged: _connected
                  ? null
                  : (value) {
                      setState(() {
                        _selectedPort = value;
                      });
                    },
            ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: _refreshPorts,
              icon: const Icon(Icons.refresh),
              label: const Text('REFRESH PORTS'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed:
                  _connected ? _disconnectArduino : _connectArduino,
              icon: Icon(
                _connected ? Icons.link_off : Icons.usb,
              ),
              label: Text(
                _connected
                    ? 'DISCONNECT ARDUINO'
                    : 'CONNECT TO ARDUINO',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 25),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 16,
                      color: statusIsSafe
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'System Status: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _systemStatus,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusIsSafe
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sensorCard(
    IconData icon,
    String title,
    String value,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget statusCard(
    IconData icon,
    String title,
    String status,
    Color statusColor,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          size: 36,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Text(
          status,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
        ),
      ),
    );
  }
}
