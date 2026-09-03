import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_libserialport/flutter_libserialport.dart';

class ArduinoSerialService {
  SerialPort? _port;
  SerialPortReader? _reader;
  StreamSubscription<Uint8List>? _subscription;

  final StreamController<String> _dataController =
      StreamController<String>.broadcast();

  Stream<String> get dataStream => _dataController.stream;

  bool get isConnected => _port?.isOpen ?? false;

  List<String> get availablePorts => SerialPort.availablePorts;

  bool connect(String portName) {
    disconnect();

    final port = SerialPort(portName);

    if (!port.openReadWrite()) {
      return false;
    }

    _port = port;
    _reader = SerialPortReader(port);

    _subscription = _reader!.stream.listen(
      (data) {
        final text = utf8.decode(data, allowMalformed: true);
        _dataController.add(text);
      },
      onError: (error) {
        _dataController.addError(error);
      },
    );

    return true;
  }

  void disconnect() {
    _subscription?.cancel();
    _subscription = null;

    _reader = null;

    if (_port != null) {
      if (_port!.isOpen) {
        _port!.close();
      }
      _port!.dispose();
      _port = null;
    }
  }

  void dispose() {
    disconnect();
    _dataController.close();
  }
}
