import 'package:flutter/foundation.dart';

class BrokerStatusNotifier extends ChangeNotifier {
  bool _isConnecting = true;
  String _status = "🔄 Connecting to MQTT...";

  bool get isConnecting => _isConnecting;
  String get status => _status;

  void updateStatus(String newStatus, {bool connecting = false}) {
    _status = newStatus;
    _isConnecting = connecting;
    notifyListeners();
  }
}
