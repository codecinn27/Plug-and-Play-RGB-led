import 'dart:async';
import 'dart:io';
import 'dart:convert';

class DeviceDiscovery {
  static const int port = 4210;
  static const String discoveryMessage = "DISCOVER_BROKER";

  /// Returns the discovered broker IP if found, else null
  static Future<String?> discoverViaUDP({Duration timeout = const Duration(seconds: 3)}) async {
    final rawSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    rawSocket.broadcastEnabled = true;

    // Send broadcast message
    rawSocket.send(utf8.encode(discoveryMessage), InternetAddress("255.255.255.255"), port);

    String? brokerIp;
    final completer = Completer<String?>();

    rawSocket.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        final datagram = rawSocket.receive();
        if (datagram != null) {
          final response = utf8.decode(datagram.data);
          if (response.contains("BROKER")) {
            brokerIp = datagram.address.address;
            completer.complete(brokerIp);
            rawSocket.close();
          }
        }
      }
    });

    // Fallback after timeout
    Future.delayed(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(null);
        rawSocket.close();
      }
    });

    return completer.future;
  }
}
