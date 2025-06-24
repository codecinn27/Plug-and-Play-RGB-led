import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:p9_rgbridge/services/mqtt_service.dart';

class MQTTConnection {
  static final MQTTConnection _instance = MQTTConnection._internal();
  factory MQTTConnection() => _instance;
  MQTTConnection._internal();

  MqttClient? _client;
  String _currentBroker = '';
  bool _isLocal = false;
  bool _isConnected = false;

  MqttClient? get client => _client;
  String get currentBroker => _currentBroker;
  bool get isLocal => _isLocal;
  bool get isConnected => _isConnected;


  Future<void> initialize() async {
    if (_isConnected) return;
    
    // Try local first, then cloud
    try {
      final localBroker = await _discoverLocalBroker();
      if (localBroker != null) {
        await connect(localBroker, isLocal: true);
      } else {
        await connect('152.42.241.179', isLocal: false);
      }
      _isConnected = true;
    } catch (e) {
      print('MQTT Connection Error: $e');
      _isConnected = false;
    }
  }

  Future<String?> _discoverLocalBroker() async {
    try {
      final mDnsResult = await discoverMqttBrokerViaMdns();
      return mDnsResult;
    } catch (e) {
      print('mDNS Discovery Error: $e');
      return null;
    }
  }


  Future<void> connect(String broker, {required bool isLocal}) async {
    final parts = broker.split(':');
    final host = parts[0];
    final port = parts.length > 1 ? int.tryParse(parts[1]) ?? 1883 : 1883;
    _client = MqttServerClient(host, 'flutter_client_${DateTime.now().millisecondsSinceEpoch}');
    _client?.port = port;
    _client?.logging(on: false);
    _client?.keepAlivePeriod = 20;
    _client?.onDisconnected = () {
      _isConnected = false;
      print('MQTT disconnected');
    };

    final connMess = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .startClean();

    _client?.connectionMessage = connMess;

    try {
      await _client?.connect();
      _currentBroker = broker;
      _isLocal = isLocal;
      _isConnected = true;
    } catch (e) {
      print('MQTT Connection Exception: $e');
      _client?.disconnect();
      rethrow;
    }
  }

  Future<void> disconnect() async {
    try {
      if (_client != null && _isConnected) {
        _client!.disconnect();
      }
    } catch (e) {
      print('Disconnection error: $e');
    } finally {
      _client = null;
      _isConnected = false;
      _currentBroker = '';
      _isLocal = false;
    }
  }
}

